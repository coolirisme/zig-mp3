// WAV file encoder — RIFF/WAVE, PCM 16-bit signed little-endian
// Spec: http://soundfile.sapp.org/doc/WaveFormat/

const std = @import("std");

fn putU16LE(buf: []u8, off: usize, v: u16) void {
    buf[off] = @truncate(v & 0xff);
    buf[off + 1] = @truncate((v >> 8) & 0xff);
}

fn putI16LE(buf: []u8, off: usize, v: i16) void {
    const u: u16 = @bitCast(v);
    putU16LE(buf, off, u);
}

fn putU32LE(buf: []u8, off: usize, v: u32) void {
    buf[off] = @truncate(v & 0xff);
    buf[off + 1] = @truncate((v >> 8) & 0xff);
    buf[off + 2] = @truncate((v >> 16) & 0xff);
    buf[off + 3] = @truncate((v >> 24) & 0xff);
}

/// Encode floating-point PCM samples as raw 16-bit little-endian PCM.
pub fn encodePcm16(allocator: std.mem.Allocator, pcm: []const f32) ![]u8 {
    const buf = try allocator.alloc(u8, pcm.len * 2);
    for (pcm, 0..) |s, i| {
        const v: i16 = if (s > 1) 32767 else if (s < -1) -32768 else @intFromFloat(@round(s * 32767));
        putI16LE(buf, i * 2, v);
    }
    return buf;
}

/// Encode floating-point PCM samples as a WAV file.
pub fn encodeWav(allocator: std.mem.Allocator, pcm: []const f32, sampleRate: u32, channels: u16) ![]u8 {
    const pcm16 = try encodePcm16(allocator, pcm);
    defer allocator.free(pcm16);

    const dataBytes = pcm16.len;
    const fileBytes = 44 + dataBytes;

    const buf = try allocator.alloc(u8, fileBytes);
    @memset(buf, 0);

    // - RIFF chunk ---------------------------------------------------------------
    buf[0] = 0x52;
    buf[1] = 0x49;
    buf[2] = 0x46;
    buf[3] = 0x46; // "RIFF"
    putU32LE(buf, 4, @intCast(fileBytes - 8)); // chunk size
    buf[8] = 0x57;
    buf[9] = 0x41;
    buf[10] = 0x56;
    buf[11] = 0x45; // "WAVE"

    // - fmt  chunk ---------------------------------------------------------------
    buf[12] = 0x66;
    buf[13] = 0x6D;
    buf[14] = 0x74;
    buf[15] = 0x20; // "fmt "
    putU32LE(buf, 16, 16); // chunk size = 16
    putU16LE(buf, 20, 1); // PCM = 1
    putU16LE(buf, 22, channels); // num channels
    putU32LE(buf, 24, sampleRate); // sample rate
    putU32LE(buf, 28, sampleRate * channels * 2); // byte rate
    putU16LE(buf, 32, channels * 2); // block align
    putU16LE(buf, 34, 16); // bits per sample

    // - data chunk ---------------------------------------------------------------
    buf[36] = 0x64;
    buf[37] = 0x61;
    buf[38] = 0x74;
    buf[39] = 0x61; // "data"
    putU32LE(buf, 40, @intCast(dataBytes)); // data size
    @memcpy(buf[44..], pcm16);

    return buf;
}
