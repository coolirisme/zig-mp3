// Anti-alias butterfly reduction for MPEG1 Layer III
//
// Reduces inter-subband aliasing introduced by the polyphase filterbank.
// Applied to the long-block frequency lines AFTER requantization and stereo
// processing, BEFORE reordering and the IMDCT.
//
// For each subband boundary sb (1 .. numBoundaries):
//   For i = 0..7:
//     u = xr[sb*18 - 1 - i]    (upper lines of left subband)
//     v = xr[sb*18 + i]        (lower lines of right subband)
//     xr[sb*18 - 1 - i] =  CS[i]*u - CA[i]*v
//     xr[sb*18 + i]     =  CS[i]*v + CA[i]*u
//
// Block-type rules:
//   long  blocks -> 31 boundaries (all subband pairs)
//   mixed blocks ->  1 boundary   (between long subbands 0 and 1 only)
//   short blocks ->  0 boundaries (butterflies not applied)

const std = @import("std");

// ci coefficients from ISO 11172-3 Table B.9
const CI = [_]f64{ -0.6, -0.535, -0.33, -0.185, -0.095, -0.041, -0.0142, -0.0037 };

// CS[i] = 1 / sqrt(1 + ci^2),  CA[i] = ci / sqrt(1 + ci^2)
pub const CS = blk: {
    var out: [8]f64 = undefined;
    for (CI, 0..) |c, i| {
        out[i] = 1.0 / std.math.sqrt(1.0 + c * c);
    }
    break :blk out;
};

pub const CA = blk: {
    var out: [8]f64 = undefined;
    for (CI, 0..) |c, i| {
        out[i] = c * CS[i];
    }
    break :blk out;
};

pub const SfType = enum {
    long,
    short,
    mixed,
};

/// Apply anti-alias butterflies in place to the long-block portion of xr[].
pub fn applyAntiAlias(xr: []f64, sfType: SfType) void {
    if (sfType == .short) return;

    // Match reference decoder behavior:
    // long  -> aliasreduce over 576 lines (31 boundaries)
    // mixed -> aliasreduce over  36 lines (1 boundary at sb=1)
    const numBoundaries: usize = if (sfType == .mixed) 1 else 31;

    var sb: usize = 1;
    while (sb <= numBoundaries) : (sb += 1) {
        const base = sb * 18;
        var i: usize = 0;
        while (i < 8) : (i += 1) {
            const lo = base - 1 - i;
            const hi = base + i;
            const u = xr[lo];
            const v = xr[hi];
            xr[lo] = CS[i] * u - CA[i] * v;
            xr[hi] = CS[i] * v + CA[i] * u;
        }
    }
}
