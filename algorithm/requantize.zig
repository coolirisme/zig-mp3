// Requantization for MPEG1 Layer III
// spectral amplitudes.

const std = @import("std");

// Pretab boost applied to long-block scale factors when granule.preflag is set.
// Values are zero for sfb 0-7, so mixed-block long portions are unaffected.
const PRETAB = [_]i32{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 3, 2, 0 };

fn absPow43(n: i32) f64 {
    const a: u32 = @intCast(@abs(n));
    return std.math.pow(f64, @as(f64, @floatFromInt(a)), 4.0 / 3.0);
}

pub const ScaleFactors = union(enum) {
    long: [22]i32,
    short: [3][13]i32,
    mixed: struct { long: [8]i32, short: [3][13]i32 },
};

pub const Granule = struct {
    scaleFactorScale: u8,
    globalGain: i32,
    preflag: u8,
    subBlockGain: ?[3]i32,
};

pub const BandIndex = struct {
    long: []const u32,
    short: []const u32,
};

/// Requantize the spectral integers for one granule/channel.
pub fn requantizeGranule(samples: []const i32, scaleFactors: ScaleFactors, granule: Granule, bandIndex: BandIndex) [576]f64 {
    var output: [576]f64 = [_]f64{0} ** 576;
    const sfcMult: f64 = if (granule.scaleFactorScale != 0) 1.0 else 0.5;
    const globalGainPow = std.math.pow(f64, 2.0, 0.25 * (@as(f64, @floatFromInt(granule.globalGain)) - 210.0));

    switch (scaleFactors) {
        .long => |longSf| {
            requantizeLong(samples, &output, longSf[0..], granule, bandIndex, globalGainPow, sfcMult, 0, 21);
        },
        .short => |shortSf| {
            requantizeShort(samples, &output, shortSf, granule, bandIndex, globalGainPow, sfcMult, 0, 12, 0);
        },
        .mixed => |mixedSf| {
            // Mixed block: long bands 0-7 (lines 0-35), short bands 3-11 (lines 36-407)
            requantizeLong(samples, &output, mixedSf.long[0..], granule, bandIndex, globalGainPow, sfcMult, 0, 8);
            requantizeShort(samples, &output, mixedSf.short, granule, bandIndex, globalGainPow, sfcMult, 3, 12, 36);
        },
    }

    return output;
}

/// Apply long-block requantization for scale factor bands [sfbStart, sfbEnd).
fn requantizeLong(samples: []const i32, output: *[576]f64, longSf: []const i32, granule: Granule, bandIndex: BandIndex, globalGainPow: f64, sfcMult: f64, sfbStart: usize, sfbEnd: usize) void {
    var sfb: usize = sfbStart;
    while (sfb < sfbEnd) : (sfb += 1) {
        const sfbGain = longSf[sfb] + (if (granule.preflag != 0) PRETAB[sfb] else 0);
        const gain = globalGainPow * std.math.pow(f64, 2.0, -sfcMult * @as(f64, @floatFromInt(sfbGain)));
        const start = bandIndex.long[sfb];
        const end = bandIndex.long[sfb + 1];
        var i: usize = start;
        while (i < end) : (i += 1) {
            const v = samples[i];
            if (v != 0) {
                const sign: f64 = if (v < 0) -1.0 else 1.0;
                output[i] = sign * absPow43(v) * gain;
            }
        }
    }
}

/// Apply short-block requantization for scale factor bands [sfbStart, sfbEnd).
fn requantizeShort(samples: []const i32, output: *[576]f64, shortSf: [3][13]i32, granule: Granule, bandIndex: BandIndex, globalGainPow: f64, sfcMult: f64, sfbStart: usize, sfbEnd: usize, outputOffset: usize) void {
    const shortBase = bandIndex.short[sfbStart];

    var sfb: usize = sfbStart;
    while (sfb < sfbEnd) : (sfb += 1) {
        const width = bandIndex.short[sfb + 1] - bandIndex.short[sfb];
        const sfbRelBase = (bandIndex.short[sfb] - shortBase) * 3;

        var win: usize = 0;
        while (win < 3) : (win += 1) {
            const subGain = if (granule.subBlockGain) |sbg| sbg[win] else 0;
            // subBlockGain is 3-bit: contributes 2^(-2 * subBlockGain[win]) to the gain
            const gain = globalGainPow *
                std.math.pow(f64, 2.0, -2.0 * @as(f64, @floatFromInt(subGain)) -
                    sfcMult * @as(f64, @floatFromInt(shortSf[win][sfb])));

            var k: usize = 0;
            while (k < width) : (k += 1) {
                const idx = outputOffset + sfbRelBase + win * width + k;
                const v = samples[idx];
                if (v != 0) {
                    const sign: f64 = if (v < 0) -1.0 else 1.0;
                    output[idx] = sign * absPow43(v) * gain;
                }
            }
        }
    }
}
