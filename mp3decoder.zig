const std = @import("std");
const sideinfo = @import("./algorithm/sideinfo.zig");
const bits = @import("./algorithm/bits.zig");
const huffman = @import("./algorithm/huffman.zig");
const requantize = @import("./algorithm/requantize.zig");
const stereo = @import("./algorithm/stereo.zig");
const reorder = @import("./algorithm/reorder.zig");
const antialias = @import("./algorithm/antialias.zig");
const imdct = @import("./algorithm/imdct.zig");
const pqmf = @import("./algorithm/pqmf.zig");

// --- Constants ---
const BITRATES_KBPS = struct {
    const V1L1 = [_]u32{ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0 };
    const V1L2 = [_]u32{ 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0 };
    const V1L3 = [_]u32{ 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0 };
    const V2L1 = [_]u32{ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 };
    const V2L2L3 = [_]u32{ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 };
};

const SAMPLE_RATES = struct {
    const MPEG1 = [_]u32{ 44100, 48000, 32000, 0 };
    const MPEG2 = [_]u32{ 22050, 24000, 16000, 0 };
    const MPEG25 = [_]u32{ 11025, 12000, 8000, 0 };
};

pub const Version = enum { MPEG25, MPEG2, MPEG1 };
pub const Layer = enum { LayerIII, LayerII, LayerI };
const CHANNEL_MODE = [_][]const u8{ "Stereo", "JointStereo", "DualChannel", "Mono" };
const EMPHASIS_MODE = [_][]const u8{ "none", "50/15us", "reserved", "CCITT J.17" };

pub const FrameHeader = struct {
    offset: usize,
    version: Version,
    layer: Layer,
    hasCrc: bool,
    bitrateKbps: u32,
    sampleRate: u32,
    padding: bool,
    channelMode: []const u8,
    channelModeBits: u8,
    modeExtension: u8,
    emphasisBits: u8,
    emphasis: []const u8,
    isFreeFormat: bool,
    samples: u32,
    frameLength: u32,
};

fn computeFrameLength(layer: Layer, version: Version, bitrateKbps: u32, sampleRate: u32, paddingBit: u8) u32 {
    if (layer == .LayerI) {
        return @as(u32, @intCast(@divFloor(12 * bitrateKbps * 1000, sampleRate) + paddingBit)) * 4;
    }
    const coef: u32 = if (layer == .LayerIII and version != .MPEG1) 72 else 144;
    return @as(u32, @intCast(@divFloor(coef * bitrateKbps * 1000, sampleRate) + paddingBit));
}

fn samplesPerFrame(version: Version, layer: Layer) u32 {
    if (layer == .LayerI) return 384;
    if (layer == .LayerII) return 1152;
    if (layer == .LayerIII) return if (version == .MPEG1) 1152 else 576;
    return 0;
}

fn bitrateKey(version: Version, layer: Layer) []const u8 {
    if (version == .MPEG1 and layer == .LayerI) return "V1L1";
    if (version == .MPEG1 and layer == .LayerII) return "V1L2";
    if (version == .MPEG1 and layer == .LayerIII) return "V1L3";
    if (layer == .LayerI) return "V2L1";
    return "V2L2L3";
}

fn pickBitrate(brKey: []const u8, idx: u8) u32 {
    if (std.mem.eql(u8, brKey, "V1L1")) return BITRATES_KBPS.V1L1[idx];
    if (std.mem.eql(u8, brKey, "V1L2")) return BITRATES_KBPS.V1L2[idx];
    if (std.mem.eql(u8, brKey, "V1L3")) return BITRATES_KBPS.V1L3[idx];
    if (std.mem.eql(u8, brKey, "V2L1")) return BITRATES_KBPS.V2L1[idx];
    return BITRATES_KBPS.V2L2L3[idx];
}

fn pickSampleRate(version: Version, idx: u8) u32 {
    return switch (version) {
        .MPEG1 => SAMPLE_RATES.MPEG1[idx],
        .MPEG2 => SAMPLE_RATES.MPEG2[idx],
        .MPEG25 => SAMPLE_RATES.MPEG25[idx],
    };
}

// --- Frame header parsing ---
pub fn parseFrameHeader(bytes: []const u8, offset: usize) ?FrameHeader {
    if (offset + 4 > bytes.len) return null;

    const b1 = bytes[offset];
    const b2 = bytes[offset + 1];
    const b3 = bytes[offset + 2];
    const b4 = bytes[offset + 3];
    if (b1 != 0xff or (b2 & 0xe0) != 0xe0) return null;

    const versionBits: u8 = @intCast((b2 >> 3) & 0b11);
    const layerBits: u8 = @intCast((b2 >> 1) & 0b11);
    const protectionBit: u8 = @intCast(b2 & 0b1);
    const bitrateIndex: u8 = @intCast((b3 >> 4) & 0b1111);
    const sampleRateIndex: u8 = @intCast((b3 >> 2) & 0b11);
    const paddingBit: u8 = @intCast((b3 >> 1) & 0b1);
    const channelModeBits: u8 = @intCast((b4 >> 6) & 0b11);
    const modeExtension: u8 = @intCast((b4 >> 4) & 0b11);
    const emphasisBits: u8 = @intCast(b4 & 0b11);

    if (versionBits == 0b01 or layerBits == 0b00) return null;

    const version: Version = switch (versionBits) {
        0b00 => .MPEG25,
        0b10 => .MPEG2,
        0b11 => .MPEG1,
        else => return null,
    };
    const layer: Layer = switch (layerBits) {
        0b01 => .LayerIII,
        0b10 => .LayerII,
        0b11 => .LayerI,
        else => return null,
    };

    const brKey = bitrateKey(version, layer);
    const bitrateKbps = pickBitrate(brKey, bitrateIndex);
    const sampleRate = pickSampleRate(version, sampleRateIndex);
    if (sampleRate == 0) return null;

    const samples = samplesPerFrame(version, layer);
    if (samples == 0 or bitrateKbps == 0) return null;

    const frameLength = computeFrameLength(layer, version, bitrateKbps, sampleRate, paddingBit);
    return .{
        .offset = offset,
        .version = version,
        .layer = layer,
        .hasCrc = protectionBit == 0,
        .bitrateKbps = bitrateKbps,
        .sampleRate = sampleRate,
        .padding = paddingBit != 0,
        .channelMode = CHANNEL_MODE[channelModeBits],
        .channelModeBits = channelModeBits,
        .modeExtension = modeExtension,
        .emphasisBits = emphasisBits,
        .emphasis = EMPHASIS_MODE[emphasisBits],
        .isFreeFormat = false,
        .samples = samples,
        .frameLength = frameLength,
    };
}

// --- Per-frame decode: side info -> scale factors -> Huffman -> requantize -> stereo -> reorder -> IMDCT+overlap ---
pub const DecoderState = struct {
    reservoir: std.ArrayList(u8),
    overlap: [2][576]f64,
    pqmfState: [2]pqmf.PQMFState,
};

pub fn createDecoderState(allocator: std.mem.Allocator) DecoderState {
    _ = allocator;
    return .{
        .reservoir = std.ArrayList(u8).empty,
        .overlap = .{ [_]f64{0} ** 576, [_]f64{0} ** 576 },
        .pqmfState = .{ pqmf.createPQMFState(), pqmf.createPQMFState() },
    };
}

pub const DecodedFrame = struct {
    sideInfo: sideinfo.SideInfo,
    pcm: [4][576]f64,
    channels: usize,
};

/// Decode one MPEG-1 Layer III frame through the full spectral pipeline.
pub fn decodeFrame(allocator: std.mem.Allocator, bytes: []const u8, header: FrameHeader, state: *DecoderState) !?DecodedFrame {
    if (header.layer != .LayerIII or header.version != .MPEG1) {
        return error.OnlyMpeg1Layer3Supported;
    }

    const isMono = header.channelModeBits == 3;
    const sideInfoSize: usize = if (isMono) 17 else 32;

    var pos: usize = header.offset + 4;
    if (header.hasCrc) pos += 2;

    // Parse side info
    const sideInfoBytes = bytes[pos .. pos + sideInfoSize];
    const sInfo = try sideinfo.parseSideInfo(allocator, sideInfoBytes, isMono);
    pos += sideInfoSize;

    // Get frame info (band indices for Huffman region boundaries)
    const frameInfo = try sideinfo.getFrameInfo(header.sampleRate, header.bitrateKbps, header.padding);

    // -- Bit reservoir ---------------------------------------------------------
    const mainDataSize = frameInfo.frameSize - 4 - sideInfoSize - (if (header.hasCrc) @as(u32, 2) else @as(u32, 0));
    const frameMainData = bytes[pos .. pos + mainDataSize];

    const reservoirLen = state.reservoir.items.len;
    const combined = try allocator.alloc(u8, reservoirLen + frameMainData.len);
    defer allocator.free(combined);
    @memcpy(combined[0..reservoirLen], state.reservoir.items);
    @memcpy(combined[reservoirLen..], frameMainData);

    // Persist tail for future frames before any early return.
    const keepFrom: usize = if (combined.len > 511) combined.len - 511 else 0;
    state.reservoir.clearRetainingCapacity();
    try state.reservoir.appendSlice(allocator, combined[keepFrom..]);

    const decodeStartSigned = @as(i64, @intCast(reservoirLen)) - @as(i64, @intCast(sInfo.mainDataBegin));
    if (decodeStartSigned < 0) {
        // Reservoir not yet large enough (normal during the first few frames).
        return null;
    }
    const decodeStart: usize = @intCast(decodeStartSigned);

    const arrayBits = try bits.getBitsArrayFromByteArray(allocator, combined[decodeStart..]);
    defer allocator.free(arrayBits);

    // -- Parse granule/channel data -------------------------------------------
    const granuleCount: usize = if (isMono) 2 else 4;
    var scaleFactors: [4]huffman.ScaleFactorObject = undefined;
    var samples: [4][576]i32 = [_][576]i32{[_]i32{0} ** 576} ** 4;
    var requantized: [4][576]f64 = [_][576]f64{[_]f64{0} ** 576} ** 4;

    var prevGranuleScaleLong: ?[2][22]i32 = null;
    var bitcount: usize = 0;

    var i: usize = 0;
    while (i < granuleCount) : (i += 1) {
        const gr = sInfo.sideInfoGr[i];
        const maxbit = bitcount + gr.par23Length;

        // Scale factors (consume bits, advance bitcount)
        const sfData = arrayBits[bitcount..];
        const sfParsed = huffman.parseScaleFactors(sfData, sInfo, gr, prevGranuleScaleLong);
        scaleFactors[i] = sfParsed.scaleFactors;
        bitcount += sfParsed.bitsConsumed;

        // Store long scale factors from granule 0 for scfsi reuse in granule 1
        if (gr.granule == 0) {
            switch (sfParsed.scaleFactors) {
                .long => |l| {
                    if (prevGranuleScaleLong == null) prevGranuleScaleLong = [_][22]i32{ [_]i32{0} ** 22, [_]i32{0} ** 22 };
                    prevGranuleScaleLong.?[gr.channel] = l;
                },
                else => {},
            }
        }

        // Huffman decode (uses remaining bits up to par23Length)
        const huffmanMaxbit = gr.par23Length + bitcount - sfParsed.bitsConsumed;
        samples[i] = huffman.parseHuffmanData(arrayBits, bitcount, huffmanMaxbit, frameInfo.bandIndex.long, gr);
        bitcount = maxbit;

        // Requantize: integer spectral values -> floating-point amplitudes
        requantized[i] = requantize.requantizeGranule(
            samples[i][0..],
            toRequantizeScaleFactors(scaleFactors[i]),
            toRequantizeGranule(gr),
            .{ .long = frameInfo.bandIndex.long, .short = frameInfo.bandIndex.short },
        );
    }

    // -- Stereo processing (on pre-reorder requantized data) ------------------
    if (!isMono and std.mem.eql(u8, header.channelMode, "JointStereo")) {
        const numGranules = granuleCount / 2;
        var g: usize = 0;
        while (g < numGranules) : (g += 1) {
            const c0 = g * 2;
            const c1 = g * 2 + 1;
            try stereo.processStereo(
                &requantized[c0],
                &requantized[c1],
                header.modeExtension,
                toStereoScaleFactors(scaleFactors[c0]),
                toStereoScaleFactors(scaleFactors[c1]),
                .{ .long = frameInfo.bandIndex.long, .short = frameInfo.bandIndex.short },
            );
        }
    }

    // -- Reorder -> Anti-alias -> IMDCT ---------------------------------------
    var pcm: [4][576]f64 = [_][576]f64{[_]f64{0} ** 576} ** 4;
    i = 0;
    while (i < granuleCount) : (i += 1) {
        const gr = sInfo.sideInfoGr[i];
        const sfTypeReorder = toReorderSfType(scaleFactors[i]);
        const sfTypeAnti = toAntiAliasSfType(scaleFactors[i]);
        const sfTypeImdct = toImdctSfType(scaleFactors[i]);

        const xr = try reorder.reorderSpectrum(
            allocator,
            requantized[i][0..],
            sfTypeReorder,
            .{ .long = frameInfo.bandIndex.long, .short = frameInfo.bandIndex.short },
        );
        defer allocator.free(xr);

        antialias.applyAntiAlias(xr, sfTypeAnti);

        const overlapPtr = &state.overlap[gr.channel];
        pcm[i] = imdct.applyIMDCT(xr, sfTypeImdct, .{ .blockType = gr.blockType }, overlapPtr);
    }

    return .{ .sideInfo = sInfo, .pcm = pcm, .channels = if (isMono) 1 else 2 };
}

fn toRequantizeScaleFactors(sf: huffman.ScaleFactorObject) requantize.ScaleFactors {
    return switch (sf) {
        .long => |v| .{ .long = v },
        .short => |v| .{ .short = v },
        .mixed => |v| .{ .mixed = .{ .long = v.long, .short = v.short } },
    };
}

fn toStereoScaleFactors(sf: huffman.ScaleFactorObject) stereo.ScaleFactors {
    return switch (sf) {
        .long => |v| .{ .long = v },
        .short => |v| .{ .short = v },
        .mixed => |v| .{ .mixed = .{ .long = v.long, .short = v.short } },
    };
}

fn toRequantizeGranule(gr: sideinfo.Granule) requantize.Granule {
    var sbg: ?[3]i32 = null;
    if (gr.subBlockGain) |v| {
        sbg = .{ @intCast(v[0]), @intCast(v[1]), @intCast(v[2]) };
    }
    return .{
        .scaleFactorScale = gr.scaleFactorScale,
        .globalGain = @intCast(gr.globalGain),
        .preflag = gr.preflag,
        .subBlockGain = sbg,
    };
}

fn toReorderSfType(sf: huffman.ScaleFactorObject) reorder.SfType {
    return switch (sf) {
        .long => .long,
        .short => .short,
        .mixed => .mixed,
    };
}

fn toAntiAliasSfType(sf: huffman.ScaleFactorObject) antialias.SfType {
    return switch (sf) {
        .long => .long,
        .short => .short,
        .mixed => .mixed,
    };
}

fn toImdctSfType(sf: huffman.ScaleFactorObject) imdct.SfType {
    return switch (sf) {
        .long => .long,
        .short => .short,
        .mixed => .mixed,
    };
}

pub const DecodeMp3FramesResult = struct {
    frames: std.ArrayList(FrameHeader),
    frameCount: usize,
    sampleRate: u32,
    channels: u8,
    durationSec: f64,
};

/// Walk every frame in an MP3 buffer and return an array of parsed frame headers
/// together with basic stream metadata. No audio is decoded.
pub fn decodeMp3Frames(allocator: std.mem.Allocator, buffer: []const u8) !DecodeMp3FramesResult {
    var frames = std.ArrayList(FrameHeader).empty;
    var i: usize = 0;
    while (i + 4 <= buffer.len) {
        const header = parseFrameHeader(buffer, i);
        if (header == null) {
            i += 1;
            continue;
        }
        if (i + header.?.frameLength > buffer.len) break;
        try frames.append(allocator, header.?);
        i += header.?.frameLength;
    }

    var totalSamples: u64 = 0;
    for (frames.items) |f| totalSamples += f.samples;
    const sampleRate: u32 = if (frames.items.len > 0) frames.items[0].sampleRate else 0;
    const durationSec = if (sampleRate > 0) @as(f64, @floatFromInt(totalSamples)) / @as(f64, @floatFromInt(sampleRate)) else 0.0;

    return .{
        .frames = frames,
        .frameCount = frames.items.len,
        .sampleRate = sampleRate,
        .channels = if (frames.items.len > 0 and std.mem.eql(u8, frames.items[0].channelMode, "Mono")) 1 else 2,
        .durationSec = durationSec,
    };
}

fn hasConsistentNextFrameHeader(bytes: []const u8, header: FrameHeader) bool {
    const nextOffset = header.offset + header.frameLength;
    if (nextOffset + 4 > bytes.len) return true;
    const nextHeader = parseFrameHeader(bytes, nextOffset);
    if (nextHeader == null) return false;
    return nextHeader.?.version == header.version and nextHeader.?.layer == header.layer and nextHeader.?.sampleRate == header.sampleRate;
}

fn skipId3v2(bytes: []const u8) usize {
    if (bytes.len < 10 or bytes[0] != 0x49 or bytes[1] != 0x44 or bytes[2] != 0x33) return 0;
    if (bytes[3] == 0xFF or bytes[4] == 0xFF) return 0;
    const size: usize =
        (@as(usize, bytes[6] & 0x7F) << 21) |
        (@as(usize, bytes[7] & 0x7F) << 14) |
        (@as(usize, bytes[8] & 0x7F) << 7) |
        (@as(usize, bytes[9] & 0x7F));
    const hasFooter = (bytes[5] & 0x10) != 0;
    return 10 + size + (if (hasFooter) @as(usize, 10) else @as(usize, 0));
}

fn isXingOrInfoFrame(bytes: []const u8, header: FrameHeader) bool {
    const isMono = header.channelModeBits == 3;
    const sideInfoSize: usize = if (isMono) 17 else 32;
    const dataStart = header.offset + 4 + (if (header.hasCrc) @as(usize, 2) else @as(usize, 0)) + sideInfoSize;
    if (dataStart + 8 > bytes.len) return false;

    const isXing =
        bytes[dataStart] == 0x58 and // X
        bytes[dataStart + 1] == 0x69 and // i
        bytes[dataStart + 2] == 0x6E and // n
        bytes[dataStart + 3] == 0x67; // g
    const isInfo =
        bytes[dataStart] == 0x49 and // I
        bytes[dataStart + 1] == 0x6E and // n
        bytes[dataStart + 2] == 0x66 and // f
        bytes[dataStart + 3] == 0x6F; // o
    return isXing or isInfo;
}

fn clamp(x: f64) f32 {
    if (x >= 1.0) return 1.0;
    if (x <= -1.0) return -1.0;
    if (std.math.isNan(x)) return 0;
    return @floatCast(x);
}

pub const DecodeAllFramesResult = struct {
    pcm: []f32,
    sampleRate: u32,
    channels: u8,
    durationSec: f64,
    frameCount: usize,
    encoderDelay: usize,
    endPadding: usize,
};

/// Decode an entire MPEG1 Layer III file and return floating-point PCM samples.
pub fn decodeAllFrames(allocator: std.mem.Allocator, buffer: []const u8) !DecodeAllFramesResult {
    var state = createDecoderState(allocator);
    defer state.reservoir.deinit(allocator);

    var chunks = std.ArrayList(f32).empty;
    errdefer chunks.deinit(allocator);

    var sampleRate: u32 = 0;
    var channels: u8 = 0;
    var frameCount: usize = 0;
    var firstFrame = true;
    const encoderDelay: usize = 0;
    const endPadding: usize = 0;

    var stepOut: [2][32]f64 = [_][32]f64{[_]f64{0} ** 32} ** 2;

    var offset: usize = skipId3v2(buffer);
    while (offset + 4 <= buffer.len) {
        const header = parseFrameHeader(buffer, offset);
        if (header == null) {
            offset += 1;
            continue;
        }
        if (!hasConsistentNextFrameHeader(buffer, header.?)) {
            offset += 1;
            continue;
        }
        if (offset + header.?.frameLength > buffer.len) break;
        if (header.?.layer != .LayerIII or header.?.version != .MPEG1) {
            offset += header.?.frameLength;
            continue;
        }

        if (sampleRate == 0) {
            sampleRate = header.?.sampleRate;
            channels = if (header.?.channelModeBits == 3) 1 else 2;
        }
        if (firstFrame) {
            firstFrame = false;
            if (isXingOrInfoFrame(buffer, header.?)) {
                offset += header.?.frameLength;
                continue;
            }
        }

        const decoded = try decodeFrame(allocator, buffer, header.?, &state);
        if (decoded) |d| {
            const numGranules: usize = 2;
            var framePcm: [2304]f32 = [_]f32{0} ** 2304;
            var outPos: usize = 0;

            var g: usize = 0;
            while (g < numGranules) : (g += 1) {
                var t: usize = 0;
                while (t < 18) : (t += 1) {
                    var ch: usize = 0;
                    while (ch < channels) : (ch += 1) {
                        const imdctOut = d.pcm[g * channels + ch];
                        pqmf.synthFilterStep(
                            imdctOut[t * 32 .. t * 32 + 32],
                            &state.pqmfState[ch],
                            &stepOut[ch],
                        );
                    }
                    var sb: usize = 0;
                    while (sb < 32) : (sb += 1) {
                        if (channels == 1) {
                            framePcm[outPos] = clamp(stepOut[0][sb]);
                            outPos += 1;
                        } else {
                            framePcm[outPos] = clamp(stepOut[0][sb]);
                            framePcm[outPos + 1] = clamp(stepOut[1][sb]);
                            outPos += 2;
                        }
                    }
                }
            }

            try chunks.appendSlice(allocator, framePcm[0..outPos]);
            frameCount += 1;
        }
        offset += header.?.frameLength;
    }

    const pcm = try chunks.toOwnedSlice(allocator);
    const samplesPerChannel: f64 = if (channels > 0) @as(f64, @floatFromInt(pcm.len)) / @as(f64, @floatFromInt(channels)) else 0;
    const durationSec: f64 = if (sampleRate > 0) samplesPerChannel / @as(f64, @floatFromInt(sampleRate)) else 0;

    return .{
        .pcm = pcm,
        .sampleRate = sampleRate,
        .channels = channels,
        .durationSec = durationSec,
        .frameCount = frameCount,
        .encoderDelay = encoderDelay,
        .endPadding = endPadding,
    };
}

pub const DecodeAllFramesRealtimeResult = struct {
    sampleRate: u32,
    channels: u8,
    durationSec: f64,
    frameCount: usize,
    encoderDelay: usize,
    endPadding: usize,
    samplesPerChannel: usize,
};

/// Realtime/incremental full-file decode.
pub fn decodeAllFramesRealtime(
    allocator: std.mem.Allocator,
    buffer: []const u8,
    onChunk: *const fn ([]const f32) anyerror!void,
) !DecodeAllFramesRealtimeResult {
    var state = createDecoderState(allocator);
    defer state.reservoir.deinit(allocator);

    var sampleRate: u32 = 0;
    var channels: u8 = 0;
    var frameCount: usize = 0;
    var firstFrame = true;
    const encoderDelay: usize = 0;
    const endPadding: usize = 0;
    var emittedInterleaved: usize = 0;
    var stepOut: [2][32]f64 = [_][32]f64{[_]f64{0} ** 32} ** 2;

    var offset: usize = skipId3v2(buffer);
    while (offset + 4 <= buffer.len) {
        const header = parseFrameHeader(buffer, offset);
        if (header == null) {
            offset += 1;
            continue;
        }
        if (!hasConsistentNextFrameHeader(buffer, header.?)) {
            offset += 1;
            continue;
        }
        if (offset + header.?.frameLength > buffer.len) break;
        if (header.?.layer != .LayerIII or header.?.version != .MPEG1) {
            offset += header.?.frameLength;
            continue;
        }
        if (sampleRate == 0) {
            sampleRate = header.?.sampleRate;
            channels = if (header.?.channelModeBits == 3) 1 else 2;
        }
        if (firstFrame) {
            firstFrame = false;
            if (isXingOrInfoFrame(buffer, header.?)) {
                offset += header.?.frameLength;
                continue;
            }
        }

        const decoded = try decodeFrame(allocator, buffer, header.?, &state);
        if (decoded) |d| {
            const numGranules: usize = 2;
            var framePcm: [2304]f32 = [_]f32{0} ** 2304;
            var outPos: usize = 0;

            var g: usize = 0;
            while (g < numGranules) : (g += 1) {
                var t: usize = 0;
                while (t < 18) : (t += 1) {
                    var ch: usize = 0;
                    while (ch < channels) : (ch += 1) {
                        const imdctOut = d.pcm[g * channels + ch];
                        pqmf.synthFilterStep(
                            imdctOut[t * 32 .. t * 32 + 32],
                            &state.pqmfState[ch],
                            &stepOut[ch],
                        );
                    }
                    var sb: usize = 0;
                    while (sb < 32) : (sb += 1) {
                        if (channels == 1) {
                            framePcm[outPos] = clamp(stepOut[0][sb]);
                            outPos += 1;
                        } else {
                            framePcm[outPos] = clamp(stepOut[0][sb]);
                            framePcm[outPos + 1] = clamp(stepOut[1][sb]);
                            outPos += 2;
                        }
                    }
                }
            }

            try onChunk(framePcm[0..outPos]);
            emittedInterleaved += outPos;
            frameCount += 1;
        }
        offset += header.?.frameLength;
    }

    const samplesPerChannel: usize = if (channels > 0) emittedInterleaved / channels else 0;
    const durationSec: f64 = if (sampleRate > 0)
        @as(f64, @floatFromInt(samplesPerChannel)) / @as(f64, @floatFromInt(sampleRate))
    else
        0;

    return .{
        .sampleRate = sampleRate,
        .channels = channels,
        .durationSec = durationSec,
        .frameCount = frameCount,
        .encoderDelay = encoderDelay,
        .endPadding = endPadding,
        .samplesPerChannel = samplesPerChannel,
    };
}
