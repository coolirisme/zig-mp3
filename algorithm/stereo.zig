// Mid/Side and Intensity Stereo processing for MPEG1 Layer III
// ISO/IEC 11172-3 §2.4.3.4.9

const std = @import("std");

const SQRT2 = std.math.sqrt(2.0);

// Precomputed (kl, kr) for IS positions 0..6.
const IS_COEFF = blk: {
    var out: [7][2]f64 = [_][2]f64{.{ 0, 0 }} ** 7;
    var p: usize = 0;
    while (p < 7) : (p += 1) {
        if (p == 6) {
            out[p] = .{ 1, 0 };
        } else {
            const ratio = std.math.tan(@as(f64, @floatFromInt(p)) * std.math.pi / 12.0);
            out[p] = .{ ratio / (1.0 + ratio), 1.0 / (1.0 + ratio) };
        }
    }
    break :blk out;
};

pub const ScaleFactors = union(enum) {
    long: [22]i32,
    short: [3][13]i32,
    mixed: struct { long: [8]i32, short: [3][13]i32 },
};

pub const BandIndex = struct {
    long: []const u32,
    short: []const u32,
};

/// Apply MS + IS stereo processing for one granule.
pub fn processStereo(xrL: *[576]f64, xrR: *[576]f64, modeExt: u8, sfL: ScaleFactors, sfR: ScaleFactors, bandIndex: BandIndex) !void {
    const msOn = (modeExt & 0b10) != 0;
    const isOn = (modeExt & 0b01) != 0;
    if (!msOn and !isOn) return;

    const typeL = std.meta.activeTag(sfL);
    const typeR = std.meta.activeTag(sfR);
    if (typeL != typeR) return error.IncompatibleStereoBlockType;

    switch (sfL) {
        .long => {
            const sR = sfR.long;
            processLongRange(xrL, xrR, msOn, isOn, sR[0..], bandIndex.long, 0, 21);
        },
        .short => {
            const sR = sfR.short;
            processShortRange(xrL, xrR, msOn, isOn, sR, bandIndex.short, 0, 12, 0, 0);
        },
        .mixed => {
            const sR = sfR.mixed;
            processLongRange(xrL, xrR, msOn, isOn, sR.long[0..], bandIndex.long, 0, 8);
            processShortRange(xrL, xrR, msOn, isOn, sR.short, bandIndex.short, 3, 12, bandIndex.short[3], 36);
        },
    }
}

fn processLongRange(xrL: *[576]f64, xrR: *[576]f64, msOn: bool, isOn: bool, sfRLong: []const i32, longIdx: []const u32, sfbStart: usize, sfbEnd: usize) void {
    const isBoundary = if (isOn) findISBoundaryLong(xrR, longIdx, sfbStart, sfbEnd) else sfbEnd;

    if (msOn) {
        var sfb: usize = sfbStart;
        while (sfb < isBoundary) : (sfb += 1) {
            applyMSRange(xrL, xrR, longIdx[sfb], longIdx[sfb + 1]);
        }
    }

    if (isOn) {
        var sfb: usize = isBoundary;
        while (sfb < sfbEnd) : (sfb += 1) {
            const isPos = sfRLong[sfb];
            if (isPos >= 7) continue;
            const kl = IS_COEFF[@intCast(isPos)][0];
            const kr = IS_COEFF[@intCast(isPos)][1];
            var i: usize = longIdx[sfb];
            while (i < longIdx[sfb + 1]) : (i += 1) {
                xrR[i] = xrL[i] * kr;
                xrL[i] = xrL[i] * kl;
            }
        }
    }
}

fn findISBoundaryLong(xrR: *[576]f64, longIdx: []const u32, sfbStart: usize, sfbEnd: usize) usize {
    var boundary = sfbEnd;
    var sfb: isize = @intCast(sfbEnd - 1);
    while (sfb >= @as(isize, @intCast(sfbStart))) : (sfb -= 1) {
        const sfb_u: usize = @intCast(sfb);
        var hasNonZero = false;
        var i: usize = longIdx[sfb_u];
        while (i < longIdx[sfb_u + 1]) : (i += 1) {
            if (xrR[i] != 0) {
                hasNonZero = true;
                break;
            }
        }
        if (hasNonZero) return boundary;
        boundary = @intCast(sfb);
    }
    return boundary;
}

fn processShortRange(xrL: *[576]f64, xrR: *[576]f64, msOn: bool, isOn: bool, sfRShort: [3][13]i32, shortIdx: []const u32, sfbStart: usize, sfbEnd: usize, shortSfbBase: u32, outputOffset: usize) void {
    var win: usize = 0;
    while (win < 3) : (win += 1) {
        const isBoundary = if (isOn) findISBoundaryShort(xrR, shortIdx, sfbStart, sfbEnd, win, shortSfbBase, outputOffset) else sfbEnd;

        if (msOn) {
            var sfb: usize = sfbStart;
            while (sfb < isBoundary) : (sfb += 1) {
                const width = shortIdx[sfb + 1] - shortIdx[sfb];
                const sfbRelBase = (shortIdx[sfb] - shortSfbBase) * 3;
                var k: usize = 0;
                while (k < width) : (k += 1) {
                    const idx = outputOffset + sfbRelBase + win * width + k;
                    const m = xrL[idx];
                    const s = xrR[idx];
                    xrL[idx] = (m + s) / SQRT2;
                    xrR[idx] = (m - s) / SQRT2;
                }
            }
        }

        if (isOn) {
            var sfb: usize = isBoundary;
            while (sfb < sfbEnd) : (sfb += 1) {
                const isPos = sfRShort[win][sfb];
                if (isPos >= 7) continue;
                const kl = IS_COEFF[@intCast(isPos)][0];
                const kr = IS_COEFF[@intCast(isPos)][1];
                const width = shortIdx[sfb + 1] - shortIdx[sfb];
                const sfbRelBase = (shortIdx[sfb] - shortSfbBase) * 3;
                var k: usize = 0;
                while (k < width) : (k += 1) {
                    const idx = outputOffset + sfbRelBase + win * width + k;
                    xrR[idx] = xrL[idx] * kr;
                    xrL[idx] = xrL[idx] * kl;
                }
            }
        }
    }
}

fn findISBoundaryShort(xrR: *[576]f64, shortIdx: []const u32, sfbStart: usize, sfbEnd: usize, win: usize, shortSfbBase: u32, outputOffset: usize) usize {
    var boundary = sfbEnd;
    var sfb: isize = @intCast(sfbEnd - 1);
    while (sfb >= @as(isize, @intCast(sfbStart))) : (sfb -= 1) {
        const sfb_u: usize = @intCast(sfb);
        const width = shortIdx[sfb_u + 1] - shortIdx[sfb_u];
        const sfbRelBase = (shortIdx[sfb_u] - shortSfbBase) * 3;
        var hasNonZero = false;
        var k: usize = 0;
        while (k < width) : (k += 1) {
            if (xrR[outputOffset + sfbRelBase + win * width + k] != 0) {
                hasNonZero = true;
                break;
            }
        }
        if (hasNonZero) return boundary;
        boundary = @intCast(sfb);
    }
    return boundary;
}

fn applyMSRange(xrL: *[576]f64, xrR: *[576]f64, start: u32, end: u32) void {
    var i: usize = start;
    while (i < end) : (i += 1) {
        const m = xrL[i];
        const s = xrR[i];
        xrL[i] = (m + s) / SQRT2;
        xrR[i] = (m - s) / SQRT2;
    }
}
