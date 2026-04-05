const std = @import("std");
const mp3decoder = @import("./mp3decoder.zig");
const wav = @import("./wav.zig");

const CliArgs = struct {
    play: bool,
    interactive: bool,
    seekSec: f64,
    ytUrl: ?[]const u8,
    inputFromStdin: bool,
    inputPath: ?[]const u8,
    outputPath: ?[]const u8,
};

const PlayerArgv = []const []const u8;
const PlayerConfigs = struct {
    aplay: [8][]const u8,
    paplay: [5][]const u8,
    ffplay: [13][]const u8,

    fn all(self: *const PlayerConfigs) [3]PlayerArgv {
        return .{
            self.aplay[0..],
            self.paplay[0..],
            self.ffplay[0..],
        };
    }
};
const InteractiveResult = struct {
    playedDurationSec: f64,
    peak: f32,
    stoppedEarly: bool,
};

// Realtime decode callback globals (single-threaded CLI).
var rt_stdin_file: ?std.fs.File = null;
var rt_seek_remaining: usize = 0;
var rt_emitted: usize = 0;
var rt_peak: f32 = 0;

fn printUsage() void {
    std.debug.print("Usage: zig run cli.zig -- [--play|-p] [--interactive] [--seek <sec|mm:ss|hh:mm:ss>] <input.mp3|-> [output.wav]\n", .{});
    std.debug.print("   or: zig run cli.zig -- [--play|-p] [--interactive] [--seek <sec|mm:ss|hh:mm:ss>] --yt <youtube-url> [output.wav]\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("  --play, -p      Decode and play in terminal via ffplay/aplay/paplay\n", .{});
    std.debug.print("  --interactive   Enable keyboard seek controls (TTY only)\n", .{});
    std.debug.print("  --seek <t>   Start playback from offset (sec, mm:ss, or hh:mm:ss)\n", .{});
    std.debug.print("  --yt <url>   Fetch YouTube audio via yt-dlp and transcode to MP3 via ffmpeg\n", .{});
    std.debug.print("  -            Read MP3 bytes from stdin (pipe input)\n", .{});
}

fn die(msg: []const u8) noreturn {
    std.debug.print("{s}\n", .{msg});
    std.process.exit(1);
}

fn fmtDuration(allocator: std.mem.Allocator, sec: f64) ![]u8 {
    const m: u64 = @intFromFloat(@floor(sec / 60.0));
    const s = sec - (@as(f64, @floatFromInt(m)) * 60.0);
    return std.fmt.allocPrint(allocator, "{d}:{d:0>6.3}", .{ m, s });
}

fn fmtBytes(allocator: std.mem.Allocator, n: usize) ![]u8 {
    if (n < 1024) return std.fmt.allocPrint(allocator, "{d} B", .{n});
    if (n < 1024 * 1024) return std.fmt.allocPrint(allocator, "{d:.1} KB", .{@as(f64, @floatFromInt(n)) / 1024.0});
    return std.fmt.allocPrint(allocator, "{d:.2} MB", .{@as(f64, @floatFromInt(n)) / (1024.0 * 1024.0)});
}

fn parseSeekSpecSeconds(raw: []const u8) ?f64 {
    if (raw.len == 0) return null;
    const colon = std.mem.count(u8, raw, ":");
    if (colon == 0) return std.fmt.parseFloat(f64, raw) catch null;

    var it = std.mem.splitScalar(u8, raw, ':');
    var parts: [3][]const u8 = .{ "", "", "" };
    var count: usize = 0;
    while (it.next()) |p| {
        if (count >= 3) return null;
        parts[count] = p;
        count += 1;
    }
    if (count < 2 or count > 3) return null;

    if (count == 2) {
        const mm = std.fmt.parseUnsigned(u64, parts[0], 10) catch return null;
        const ss = std.fmt.parseFloat(f64, parts[1]) catch return null;
        return @as(f64, @floatFromInt(mm)) * 60.0 + ss;
    }
    const hh = std.fmt.parseUnsigned(u64, parts[0], 10) catch return null;
    const mm = std.fmt.parseUnsigned(u64, parts[1], 10) catch return null;
    const ss = std.fmt.parseFloat(f64, parts[2]) catch return null;
    return @as(f64, @floatFromInt(hh)) * 3600.0 + @as(f64, @floatFromInt(mm)) * 60.0 + ss;
}

fn parseCliArgs(allocator: std.mem.Allocator, argv: []const []const u8) !CliArgs {
    var play = false;
    var interactive = false;
    var ytUrl: ?[]const u8 = null;
    var seekSec: f64 = 0;
    var positional = std.ArrayList([]const u8).empty;
    defer positional.deinit(allocator);

    var i: usize = 0;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (std.mem.eql(u8, arg, "--play") or std.mem.eql(u8, arg, "-p")) {
            play = true;
        } else if (std.mem.eql(u8, arg, "--interactive")) {
            interactive = true;
        } else if (std.mem.eql(u8, arg, "--seek")) {
            if (i + 1 >= argv.len) die("Error: --seek requires a time value.");
            const parsed = parseSeekSpecSeconds(argv[i + 1]) orelse die("Error: invalid seek value.");
            if (parsed < 0) die("Error: seek must be >= 0.");
            seekSec = parsed;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--yt")) {
            if (i + 1 >= argv.len) die("Error: --yt requires a YouTube URL.");
            ytUrl = argv[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            std.process.exit(0);
        } else {
            try positional.append(allocator, arg);
        }
    }

    if (ytUrl == null and positional.items.len == 0 and !std.fs.File.stdin().isTty()) {
        try positional.append(allocator, "-");
    }

    if (ytUrl != null) {
        if (positional.items.len > 1) {
            printUsage();
            die("");
        }
        return .{
            .play = play,
            .interactive = interactive,
            .seekSec = seekSec,
            .ytUrl = ytUrl,
            .inputFromStdin = false,
            .inputPath = null,
            .outputPath = if (positional.items.len == 1) positional.items[0] else null,
        };
    }

    if (positional.items.len == 0 or positional.items.len > 2) {
        printUsage();
        die("");
    }

    const inputFromStdin = std.mem.eql(u8, positional.items[0], "-");
    return .{
        .play = play,
        .interactive = interactive,
        .seekSec = seekSec,
        .ytUrl = null,
        .inputFromStdin = inputFromStdin,
        .inputPath = if (inputFromStdin) null else positional.items[0],
        .outputPath = if (positional.items.len > 1) positional.items[1] else null,
    };
}

fn readStdinBytes(allocator: std.mem.Allocator) ![]u8 {
    return try std.fs.File.stdin().readToEndAlloc(allocator, std.math.maxInt(usize));
}

fn shellEscapeSingleQuoted(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);
    try out.append(allocator, '\'');
    for (s) |c| {
        if (c == '\'') try out.appendSlice(allocator, "'\\''") else try out.append(allocator, c);
    }
    try out.append(allocator, '\'');
    return try out.toOwnedSlice(allocator);
}

fn readYoutubeMp3Bytes(allocator: std.mem.Allocator, ytUrl: []const u8) ![]u8 {
    const escUrl = try shellEscapeSingleQuoted(allocator, ytUrl);
    defer allocator.free(escUrl);

    const cmd = try std.fmt.allocPrint(
        allocator,
        "yt-dlp -f ba --no-playlist -o - {s} | ffmpeg -loglevel error -i pipe:0 -f mp3 pipe:1",
        .{escUrl},
    );
    defer allocator.free(cmd);

    const r = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "sh", "-c", cmd },
        .max_output_bytes = std.math.maxInt(usize),
    }) catch die("Error: failed to run yt-dlp/ffmpeg pipeline.");
    defer allocator.free(r.stderr);

    switch (r.term) {
        .Exited => |code| if (code != 0) {
            std.debug.print("Error: yt-dlp/ffmpeg failed.\n{s}\n", .{r.stderr});
            std.process.exit(1);
        },
        else => die("Error: yt-dlp/ffmpeg terminated unexpectedly."),
    }
    if (r.stdout.len == 0) die("Error: no bytes produced by yt-dlp/ffmpeg pipeline.");
    return r.stdout;
}

fn readInputBytes(allocator: std.mem.Allocator, args: CliArgs) !struct { bytes: []u8, label: []const u8 } {
    if (args.ytUrl) |url| return .{ .bytes = try readYoutubeMp3Bytes(allocator, url), .label = "youtube" };
    if (args.inputFromStdin) {
        const b = try readStdinBytes(allocator);
        if (b.len == 0) die("Error: no input bytes received on stdin.");
        return .{ .bytes = b, .label = "stdin (-)" };
    }
    const p = args.inputPath orelse die("Error: missing input path.");
    return .{ .bytes = try std.fs.cwd().readFileAlloc(allocator, p, std.math.maxInt(usize)), .label = p };
}

fn encodePcm16ChunkInPlace(pcm: []const f32, out: []u8) []const u8 {
    std.debug.assert(out.len >= pcm.len * 2);
    var i: usize = 0;
    while (i < pcm.len) : (i += 1) {
        const s = pcm[i];
        const v: i16 = if (s > 1) 32767 else if (s < -1) -32768 else @intFromFloat(@round(s * 32767));
        const u: u16 = @bitCast(v);
        out[i * 2] = @truncate(u & 0xff);
        out[i * 2 + 1] = @truncate((u >> 8) & 0xff);
    }
    return out[0 .. pcm.len * 2];
}

fn buildPlayerConfigs(allocator: std.mem.Allocator, sampleRate: u32, channels: u8) !PlayerConfigs {
    const sr = try std.fmt.allocPrint(allocator, "{d}", .{sampleRate});
    const ch = try std.fmt.allocPrint(allocator, "{d}", .{channels});
    const paplay_rate = try std.fmt.allocPrint(allocator, "--rate={d}", .{sampleRate});
    const paplay_channels = try std.fmt.allocPrint(allocator, "--channels={d}", .{channels});
    return .{
        .aplay = .{ "aplay", "-q", "-f", "S16_LE", "-r", sr, "-c", ch },
        .paplay = .{ "paplay", "--raw", "--format=s16le", paplay_rate, paplay_channels },
        .ffplay = .{ "ffplay", "-autoexit", "-nodisp", "-loglevel", "error", "-f", "s16le", "-ar", sr, "-channels", ch, "-i", "pipe:0" },
    };
}

fn freePlayerConfigs(allocator: std.mem.Allocator, players: PlayerConfigs) void {
    allocator.free(players.aplay[5]);
    allocator.free(players.aplay[7]);
    allocator.free(players.paplay[3]);
    allocator.free(players.paplay[4]);
}

fn choosePlayer(players: [3]PlayerArgv) ?PlayerArgv {
    for (players) |argv| {
        var child = std.process.Child.init(argv, std.heap.page_allocator);
        child.stdin_behavior = .Pipe;
        child.stdout_behavior = .Ignore;
        child.stderr_behavior = .Ignore;
        child.spawn() catch |e| {
            if (e == error.FileNotFound) continue;
            continue;
        };
        child.stdin.?.close();
        child.stdin = null;
        _ = child.kill() catch {};
        _ = child.wait() catch {};
        return argv;
    }
    return null;
}

fn playPcmInTerminal(allocator: std.mem.Allocator, pcm: []const f32, sampleRate: u32, channels: u8) !void {
    const pcm16 = try wav.encodePcm16(allocator, pcm);
    defer allocator.free(pcm16);

    const player_configs = try buildPlayerConfigs(allocator, sampleRate, channels);
    defer freePlayerConfigs(allocator, player_configs);
    const players = player_configs.all();

    var failures = std.ArrayList(u8).empty;
    defer failures.deinit(allocator);

    for (players) |argv| {
        var child = std.process.Child.init(argv, allocator);
        child.stdin_behavior = .Pipe;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        child.spawn() catch |e| {
            if (e == error.FileNotFound) continue;
            try failures.writer(allocator).print("{s}: {s}\n", .{ argv[0], @errorName(e) });
            continue;
        };

        try child.stdin.?.writeAll(pcm16);
        child.stdin.?.close();
        child.stdin = null;
        const term = try child.wait();
        switch (term) {
            .Exited => |code| {
                if (code == 0) {
                    std.debug.print("Playback:       {s} (raw PCM stream)\n", .{argv[0]});
                    return;
                }
                try failures.writer(allocator).print("{s}: exited with code {d}\n", .{ argv[0], code });
            },
            else => try failures.writer(allocator).print("{s}: terminated unexpectedly\n", .{argv[0]}),
        }
    }

    std.debug.print("Error: unable to play audio in terminal.\n{s}", .{failures.items});
    std.process.exit(1);
}

fn parseSeekKeys(allocator: std.mem.Allocator, bytes_in: []const u8, pending: *std.ArrayList(u8), seek_delta: *i32, quit: *bool) !void {
    try pending.appendSlice(allocator, bytes_in);
    var i: usize = 0;
    while (i < pending.items.len) : (i += 1) {
        if (i + 2 < pending.items.len and pending.items[i] == 0x1b and pending.items[i + 1] == '[' and pending.items[i + 2] == 'C') {
            seek_delta.* += 10;
            i += 2;
            continue;
        }
        if (i + 2 < pending.items.len and pending.items[i] == 0x1b and pending.items[i + 1] == '[' and pending.items[i + 2] == 'D') {
            seek_delta.* -= 10;
            i += 2;
            continue;
        }
        if (pending.items[i] == 'q' or pending.items[i] == 'Q' or pending.items[i] == 0x03) {
            quit.* = true;
            return;
        }
    }
    if (pending.items.len > 8) {
        const keep = pending.items[pending.items.len - 8 ..];
        pending.clearRetainingCapacity();
        try pending.appendSlice(allocator, keep);
    }
}

fn playPcmInteractiveWithSeek(allocator: std.mem.Allocator, pcm: []const f32, sampleRate: u32, channels: u8, initialSeekSec: f64) !InteractiveResult {
    const player_configs = try buildPlayerConfigs(allocator, sampleRate, channels);
    defer freePlayerConfigs(allocator, player_configs);
    const chosen = choosePlayer(player_configs.all()) orelse die("Error: unable to find a terminal player (aplay/paplay/ffplay).");

    var term = try std.posix.tcgetattr(std.posix.STDIN_FILENO);
    const old_term = term;
    term.lflag.ICANON = false;
    term.lflag.ECHO = false;
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, term);
    defer std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, old_term) catch {};

    const interleaved_per_second: usize = sampleRate * channels;
    const interleaved_per_chunk: usize = @max(@as(usize, 1), interleaved_per_second / 10);
    const pcm16_chunk_buf = try allocator.alloc(u8, interleaved_per_chunk * 2);
    defer allocator.free(pcm16_chunk_buf);
    var cursor: usize = @intFromFloat(@floor(initialSeekSec * @as(f64, @floatFromInt(interleaved_per_second))));
    if (cursor > pcm.len) cursor = pcm.len;

    var stop_requested = false;
    var seek_delta_sec: i32 = 0;
    var pending = std.ArrayList(u8).empty;
    defer pending.deinit(allocator);
    var peak: f32 = 0;

    std.debug.print("Controls:       <- -10s | -> +10s | q quit\n", .{});

    while (!stop_requested and cursor < pcm.len) {
        var child = std.process.Child.init(chosen, allocator);
        child.stdin_behavior = .Pipe;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        try child.spawn();

        while (!stop_requested and cursor < pcm.len) {
            var fds = [_]std.posix.pollfd{.{ .fd = std.posix.STDIN_FILENO, .events = std.posix.POLL.IN, .revents = 0 }};
            _ = try std.posix.poll(&fds, 0);
            if ((fds[0].revents & std.posix.POLL.IN) != 0) {
                var kb: [16]u8 = undefined;
                const n = std.posix.read(std.posix.STDIN_FILENO, kb[0..]) catch 0;
                if (n > 0) try parseSeekKeys(allocator, kb[0..n], &pending, &seek_delta_sec, &stop_requested);
            }

            if (seek_delta_sec != 0) {
                const step = @as(i64, seek_delta_sec) * @as(i64, @intCast(interleaved_per_second));
                const next = @as(i64, @intCast(cursor)) + step;
                cursor = @intCast(@max(@as(i64, 0), @min(next, @as(i64, @intCast(pcm.len)))));
                seek_delta_sec = 0;
                break;
            }

            const chunk_interleaved = @min(interleaved_per_chunk, pcm.len - cursor);
            const chunk = pcm[cursor .. cursor + chunk_interleaved];
            for (chunk) |v| {
                const a = @abs(v);
                if (a > peak) peak = a;
            }
            const pcm16 = encodePcm16ChunkInPlace(chunk, pcm16_chunk_buf);
            child.stdin.?.writeAll(pcm16) catch break;
            cursor += chunk_interleaved;
            std.Thread.sleep(100 * std.time.ns_per_ms);
        }

        child.stdin.?.close();
        child.stdin = null;
        _ = child.kill() catch {};
        _ = child.wait() catch {};
    }

    const played_sec = if (channels > 0 and sampleRate > 0)
        @as(f64, @floatFromInt(cursor / channels)) / @as(f64, @floatFromInt(sampleRate))
    else
        0;
    std.debug.print("Playback:       {s} (interactive raw PCM stream)\n", .{chosen[0]});
    return .{ .playedDurationSec = played_sec, .peak = peak, .stoppedEarly = cursor < pcm.len };
}

fn realtimeOnChunk(chunk: []const f32) anyerror!void {
    var out = chunk;
    if (rt_seek_remaining > 0) {
        const skip = @min(rt_seek_remaining, out.len);
        out = out[skip..];
        rt_seek_remaining -= skip;
    }
    if (out.len == 0) return;

    for (out) |v| {
        const a = @abs(v);
        if (a > rt_peak) rt_peak = a;
    }
    var pcm16buf: [4608]u8 = undefined;
    const pcm16 = encodePcm16ChunkInPlace(out, pcm16buf[0..]);
    try rt_stdin_file.?.writeAll(pcm16);
    rt_emitted += out.len;
}

fn playRealtimeInTerminal(allocator: std.mem.Allocator, inputBytes: []const u8, sampleRate: u32, channels: u8, seekSec: f64) !mp3decoder.DecodeAllFramesRealtimeResult {
    const player_configs = try buildPlayerConfigs(allocator, sampleRate, channels);
    defer freePlayerConfigs(allocator, player_configs);
    const chosen = choosePlayer(player_configs.all()) orelse die("Error: unable to find a terminal player (aplay/paplay/ffplay).");

    var child = std.process.Child.init(chosen, allocator);
    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    try child.spawn();

    rt_stdin_file = child.stdin.?;
    rt_seek_remaining = @as(usize, @intFromFloat(@floor(seekSec * @as(f64, @floatFromInt(sampleRate))))) * channels;
    rt_emitted = 0;
    rt_peak = 0;

    const result = mp3decoder.decodeAllFramesRealtime(allocator, inputBytes, realtimeOnChunk) catch |e| {
        _ = child.kill() catch {};
        _ = child.wait() catch {};
        return e;
    };

    child.stdin.?.close();
    child.stdin = null;
    switch (try child.wait()) {
        .Exited => |code| if (code != 0) die("Error: player exited with non-zero status."),
        else => die("Error: player terminated unexpectedly."),
    }
    std.debug.print("Playback:       {s} (realtime raw PCM stream)\n", .{chosen[0]});
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();
    _ = args_it.skip();

    var argv = std.ArrayList([]const u8).empty;
    defer argv.deinit(allocator);
    while (args_it.next()) |a| try argv.append(allocator, a);

    const args = try parseCliArgs(allocator, argv.items);
    const input = try readInputBytes(allocator, args);
    defer allocator.free(input.bytes);

    const in_size = try fmtBytes(allocator, input.bytes.len);
    defer allocator.free(in_size);
    std.debug.print("Input:  {s}  ({s})\n", .{ input.label, in_size });

    const interactive_tty = std.fs.File.stdin().isTty() and std.fs.File.stdout().isTty();
    if (args.play and args.interactive and !interactive_tty) {
        std.debug.print("Note: --interactive requires a TTY; falling back to realtime playback.\n", .{});
    }

    // Realtime playback path (default): stream chunks directly while decoding.
    if (args.play and args.outputPath == null and (!args.interactive or !interactive_tty)) {
        var frameScan = try mp3decoder.decodeMp3Frames(allocator, input.bytes);
        defer frameScan.frames.deinit(allocator);
        if (frameScan.frameCount == 0 or frameScan.sampleRate == 0 or frameScan.channels == 0) {
            die("Error: no MPEG-1 Layer III frames decoded from input.");
        }
        if (args.seekSec > 0 and frameScan.durationSec > 0 and args.seekSec >= frameScan.durationSec) {
            die("Error: seek is beyond stream duration.");
        }

        std.debug.print("\nStarting realtime terminal playback...\n", .{});
        const s = try playRealtimeInTerminal(allocator, input.bytes, frameScan.sampleRate, frameScan.channels, args.seekSec);
        if (s.frameCount == 0) die("Error: no MPEG-1 Layer III frames decoded from input stream.");

        const played = if (s.channels > 0 and s.sampleRate > 0)
            @as(f64, @floatFromInt(rt_emitted / s.channels)) / @as(f64, @floatFromInt(s.sampleRate))
        else
            0;
        const d_played = try fmtDuration(allocator, played);
        defer allocator.free(d_played);
        std.debug.print("Frames decoded:  {d}\n", .{s.frameCount});
        std.debug.print("Sample rate:     {d} Hz\n", .{s.sampleRate});
        std.debug.print("Channels:        {d}\n", .{s.channels});
        std.debug.print("Duration:        {s} played\n", .{d_played});
        std.debug.print("Peak amplitude:  {d:.6}\n", .{rt_peak});
        return;
    }

    var decoded = try mp3decoder.decodeAllFrames(allocator, input.bytes);
    defer allocator.free(decoded.pcm);
    if (decoded.frameCount == 0 or decoded.sampleRate == 0 or decoded.channels == 0) {
        die("Error: no MPEG-1 Layer III frames decoded from input.");
    }

    const d = try fmtDuration(allocator, decoded.durationSec);
    defer allocator.free(d);
    std.debug.print("Frames decoded:  {d}\n", .{decoded.frameCount});
    std.debug.print("Sample rate:     {d} Hz\n", .{decoded.sampleRate});
    std.debug.print("Channels:        {d}\n", .{decoded.channels});
    std.debug.print("Duration:        {s}\n", .{d});

    var peak: f32 = 0;
    for (decoded.pcm) |v| {
        const a = @abs(v);
        if (a > peak) peak = a;
    }
    std.debug.print("Peak amplitude:  {d:.6}\n", .{peak});

    if (args.play) {
        if (interactive_tty) {
            std.debug.print("\nStarting interactive terminal playback...\n", .{});
            const r = try playPcmInteractiveWithSeek(allocator, decoded.pcm, decoded.sampleRate, decoded.channels, args.seekSec);
            const pd = try fmtDuration(allocator, r.playedDurationSec);
            defer allocator.free(pd);
            std.debug.print("Duration:        {s} played{s}\n", .{ pd, if (r.stoppedEarly) " (stopped early)" else "" });
            std.debug.print("Peak amplitude:  {d:.6}\n", .{r.peak});
        } else {
            std.debug.print("\nStarting terminal playback...\n", .{});
            var playSlice: []const f32 = decoded.pcm;
            if (args.seekSec > 0) {
                const seekSamplesPerChannel: usize = @intFromFloat(@floor(args.seekSec * @as(f64, @floatFromInt(decoded.sampleRate))));
                const seekInterleaved = seekSamplesPerChannel * decoded.channels;
                if (seekInterleaved >= decoded.pcm.len) die("Error: seek is beyond stream duration.");
                playSlice = decoded.pcm[seekInterleaved..];
                const sd = try fmtDuration(allocator, args.seekSec);
                defer allocator.free(sd);
                std.debug.print("Seek:            {s}\n", .{sd});
            }
            try playPcmInTerminal(allocator, playSlice, decoded.sampleRate, decoded.channels);
        }
    }

    if (args.outputPath) |out| {
        var outSlice: []const f32 = decoded.pcm;
        if (args.seekSec > 0) {
            const seekSamplesPerChannel: usize = @intFromFloat(@floor(args.seekSec * @as(f64, @floatFromInt(decoded.sampleRate))));
            const seekInterleaved = seekSamplesPerChannel * decoded.channels;
            if (seekInterleaved >= decoded.pcm.len) die("Error: seek is beyond stream duration.");
            outSlice = decoded.pcm[seekInterleaved..];
        }
        const wavBytes = try wav.encodeWav(allocator, outSlice, decoded.sampleRate, decoded.channels);
        defer allocator.free(wavBytes);
        try std.fs.cwd().writeFile(.{ .sub_path = out, .data = wavBytes });
        const outSize = try fmtBytes(allocator, wavBytes.len);
        defer allocator.free(outSize);
        std.debug.print("Output: {s}  ({s})\n", .{ out, outSize });
    } else if (!args.play) {
        std.debug.print("\nTip: pass a second argument to write a WAV file, e.g.:\n", .{});
        std.debug.print("  zig run cli.zig -- input.mp3 output.wav\n", .{});
    }
}
