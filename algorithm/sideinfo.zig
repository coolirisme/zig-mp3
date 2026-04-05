// Side info parser
// Band index tables

const std = @import("std");
const bits = @import("./bits.zig");

// --- Band index / width tables (from Frame.fs) ---

pub const BandEntry = struct {
    long: []const u32,
    short: []const u32,
};

const BAND_WIDTH_32000_LONG = [_]u32{ 4, 4, 4, 4, 4, 4, 6, 6, 8, 10, 12, 16, 20, 24, 30, 38, 46, 56, 68, 84, 102 };
const BAND_WIDTH_32000_SHORT = [_]u32{ 4, 4, 4, 4, 6, 8, 12, 16, 20, 26, 34, 42 };
const BAND_WIDTH_44100_LONG = [_]u32{ 4, 4, 4, 4, 4, 4, 6, 6, 8, 8, 10, 12, 16, 20, 24, 28, 34, 42, 50, 54, 76 };
const BAND_WIDTH_44100_SHORT = [_]u32{ 4, 4, 4, 4, 6, 8, 10, 12, 14, 18, 22, 30 };
const BAND_WIDTH_48000_LONG = [_]u32{ 4, 4, 4, 4, 4, 4, 6, 6, 6, 8, 10, 12, 16, 18, 22, 28, 34, 40, 46, 54, 54 };
const BAND_WIDTH_48000_SHORT = [_]u32{ 4, 4, 4, 4, 6, 6, 10, 12, 14, 16, 20, 26 };

const BAND_INDEX_32000_LONG = [_]u32{ 0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 54, 66, 82, 102, 126, 156, 194, 240, 296, 364, 448, 550, 576 };
const BAND_INDEX_32000_SHORT = [_]u32{ 0, 4, 8, 12, 16, 22, 30, 42, 58, 78, 104, 138, 180, 192 };
const BAND_INDEX_44100_LONG = [_]u32{ 0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576 };
const BAND_INDEX_44100_SHORT = [_]u32{ 0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192 };
const BAND_INDEX_48000_LONG = [_]u32{ 0, 4, 8, 12, 16, 20, 24, 30, 36, 42, 50, 60, 72, 88, 106, 128, 156, 190, 230, 276, 330, 384, 576 };
const BAND_INDEX_48000_SHORT = [_]u32{ 0, 4, 8, 12, 16, 22, 28, 38, 50, 64, 80, 100, 126, 192 };

pub fn getBandWidth(sampleRate: u32) !BandEntry {
    return switch (sampleRate) {
        32000 => .{ .long = BAND_WIDTH_32000_LONG[0..], .short = BAND_WIDTH_32000_SHORT[0..] },
        44100 => .{ .long = BAND_WIDTH_44100_LONG[0..], .short = BAND_WIDTH_44100_SHORT[0..] },
        48000 => .{ .long = BAND_WIDTH_48000_LONG[0..], .short = BAND_WIDTH_48000_SHORT[0..] },
        else => error.UnknownSampleRate,
    };
}

pub fn getBandIndex(sampleRate: u32) !BandEntry {
    return switch (sampleRate) {
        32000 => .{ .long = BAND_INDEX_32000_LONG[0..], .short = BAND_INDEX_32000_SHORT[0..] },
        44100 => .{ .long = BAND_INDEX_44100_LONG[0..], .short = BAND_INDEX_44100_SHORT[0..] },
        48000 => .{ .long = BAND_INDEX_48000_LONG[0..], .short = BAND_INDEX_48000_SHORT[0..] },
        else => error.UnknownSampleRate,
    };
}

pub const FrameInfo = struct {
    frameSize: u32,
    bandWidth: BandEntry,
    bandIndex: BandEntry,
};

pub fn getFrameInfo(sampleRate: u32, bitrateKbps: u32, padding: bool) !FrameInfo {
    return .{
        .frameSize = @divFloor(144 * bitrateKbps * 1000, sampleRate) + (if (padding) @as(u32, 1) else @as(u32, 0)),
        .bandWidth = try getBandWidth(sampleRate),
        .bandIndex = try getBandIndex(sampleRate),
    };
}

pub const Granule = struct {
    granule: u8,
    channel: u8,
    par23Length: u32,
    bigValues: u32,
    globalGain: u32,
    scaleFactorCompress: u32,
    windowSwitchFlag: bool,
    blockType: u32,
    mixedBlockFlag: bool,
    tableSelect: [3]u32,
    subBlockGain: ?[3]u32,
    region0Count: u32,
    region1Count: u32,
    preflag: u8,
    scaleFactorScale: u8,
    count1TableSelect: u8,
};

pub const SideInfo = struct {
    mainDataBegin: u32,
    privateBits: u32,
    scfsi: [2][4]u8,
    sideInfoGr: [4]Granule,
    granuleCount: usize,
};

fn extractGranule(bitsArr: []const u8, gr: u8, ch: u8) !Granule {
    const wsf = bitsArr[33] == 1;
    const blockType = if (wsf) bits.bitsArrayToNumber(bitsArr, 34, 2) else 0;
    if (wsf and blockType == 0) return error.ReservedBlockType;
    const mixedBlockFlag = if (wsf) bitsArr[36] == 1 else false;
    const region0Count: u32 = if (wsf)
        (if (blockType == 2 and !mixedBlockFlag) @as(u32, 8) else @as(u32, 7))
    else
        bits.bitsArrayToNumber(bitsArr, 49, 4);
    const region1Count: u32 = if (wsf)
        20 - region0Count
    else
        bits.bitsArrayToNumber(bitsArr, 53, 3);

    var tableSelect: [3]u32 = .{ 0, 0, 0 };
    if (wsf) {
        tableSelect[0] = bits.bitsArrayToNumber(bitsArr, 37, 5);
        tableSelect[1] = bits.bitsArrayToNumber(bitsArr, 42, 5);
    } else {
        tableSelect[0] = bits.bitsArrayToNumber(bitsArr, 34, 5);
        tableSelect[1] = bits.bitsArrayToNumber(bitsArr, 39, 5);
        tableSelect[2] = bits.bitsArrayToNumber(bitsArr, 44, 5);
    }

    var sbg: ?[3]u32 = null;
    if (wsf) {
        sbg = .{
            bits.bitsArrayToNumber(bitsArr, 47, 3),
            bits.bitsArrayToNumber(bitsArr, 50, 3),
            bits.bitsArrayToNumber(bitsArr, 53, 3),
        };
    }

    return .{
        .granule = gr,
        .channel = ch,
        .par23Length = bits.bitsArrayToNumber(bitsArr, 0, 12),
        .bigValues = bits.bitsArrayToNumber(bitsArr, 12, 9),
        .globalGain = bits.bitsArrayToNumber(bitsArr, 21, 8),
        .scaleFactorCompress = bits.bitsArrayToNumber(bitsArr, 29, 4),
        .windowSwitchFlag = wsf,
        .blockType = blockType,
        .mixedBlockFlag = mixedBlockFlag,
        .tableSelect = tableSelect,
        .subBlockGain = sbg,
        .region0Count = region0Count,
        .region1Count = region1Count,
        .preflag = bitsArr[56],
        .scaleFactorScale = bitsArr[57],
        .count1TableSelect = bitsArr[58],
    };
}

/// Parse the side information from a Layer III frame.
pub fn parseSideInfo(allocator: std.mem.Allocator, sideInfoBytes: []const u8, isMono: bool) !SideInfo {
    const bitsArr = try bits.getBitsArrayFromByteArray(allocator, sideInfoBytes);
    defer allocator.free(bitsArr);

    var out: SideInfo = .{
        .mainDataBegin = bits.bitsArrayToNumber(bitsArr, 0, 9),
        .privateBits = if (isMono) bits.bitsArrayToNumber(bitsArr, 9, 5) else bits.bitsArrayToNumber(bitsArr, 9, 3),
        .scfsi = .{ .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        .sideInfoGr = undefined,
        .granuleCount = if (isMono) 2 else 4,
    };

    if (isMono) {
        out.scfsi[0] = .{ bitsArr[14], bitsArr[15], bitsArr[16], bitsArr[17] };
        out.sideInfoGr[0] = try extractGranule(bitsArr[18..], 0, 0);
        out.sideInfoGr[1] = try extractGranule(bitsArr[77..], 1, 0);
    } else {
        out.scfsi[0] = .{ bitsArr[12], bitsArr[13], bitsArr[14], bitsArr[15] };
        out.scfsi[1] = .{ bitsArr[16], bitsArr[17], bitsArr[18], bitsArr[19] };
        out.sideInfoGr[0] = try extractGranule(bitsArr[20..], 0, 0);
        out.sideInfoGr[1] = try extractGranule(bitsArr[20 + 59 ..], 0, 1);
        out.sideInfoGr[2] = try extractGranule(bitsArr[138..], 1, 0);
        out.sideInfoGr[3] = try extractGranule(bitsArr[138 + 59 ..], 1, 1);
    }

    return out;
}
