// IMDCT and overlap-add for MPEG1 Layer III
// ISO/IEC 11172-3 §2.4.3.4.10

const std = @import("std");
const tables = @import("./tables.zig");

pub const SfType = enum {
    long,
    short,
    mixed,
};

pub const Granule = struct {
    blockType: u32,
};

fn processLong(s: []const f64, win: []const f64, prevOverlap: *[18]f64, pcmOut: *[18]f64) void {
    var y: [36]f64 = [_]f64{0} ** 36;
    var n: usize = 0;
    while (n < 36) : (n += 1) {
        var sum: f64 = 0;
        var k: usize = 0;
        while (k < 18) : (k += 1) {
            const c = std.math.cos((std.math.pi / 72.0) * (2.0 * @as(f64, @floatFromInt(n)) + 19.0) * (2.0 * @as(f64, @floatFromInt(k)) + 1.0));
            sum += s[k] * c;
        }
        y[n] = sum * win[n];
    }
    n = 0;
    while (n < 18) : (n += 1) {
        pcmOut[n] = prevOverlap[n] + y[n];
        prevOverlap[n] = y[n + 18];
    }
}

fn processShort(s0: []const f64, s1: []const f64, s2: []const f64, prevOverlap: *[18]f64, pcmOut: *[18]f64) void {
    const w = tables.sineBlock[2][0..];
    const subs = [_][]const f64{ s0, s1, s2 };
    var yw: [3][12]f64 = [_][12]f64{[_]f64{0} ** 12} ** 3;

    var win: usize = 0;
    while (win < 3) : (win += 1) {
        var n: usize = 0;
        while (n < 12) : (n += 1) {
            var sum: f64 = 0;
            var k: usize = 0;
            while (k < 6) : (k += 1) {
                const c = std.math.cos((std.math.pi / 24.0) * (2.0 * @as(f64, @floatFromInt(n)) + 7.0) * (2.0 * @as(f64, @floatFromInt(k)) + 1.0));
                sum += subs[win][k] * c;
            }
            yw[win][n] = sum * w[n];
        }
    }

    var z: [36]f64 = [_]f64{0} ** 36;
    var n: usize = 0;
    while (n < 6) : (n += 1) z[n + 6] = yw[0][n];
    n = 0;
    while (n < 6) : (n += 1) z[n + 12] = yw[0][n + 6] + yw[1][n];
    n = 0;
    while (n < 6) : (n += 1) z[n + 18] = yw[1][n + 6] + yw[2][n];
    n = 0;
    while (n < 6) : (n += 1) z[n + 24] = yw[2][n + 6];

    n = 0;
    while (n < 18) : (n += 1) {
        pcmOut[n] = prevOverlap[n] + z[n];
        prevOverlap[n] = z[n + 18];
    }
}

/// Apply IMDCT and overlap-add for one granule/channel.
pub fn applyIMDCT(xr: []const f64, sfType: SfType, granule: Granule, overlap: *[576]f64) [576]f64 {
    var pcm: [576]f64 = [_]f64{0} ** 576;
    const bt = if (sfType == .mixed) 0 else granule.blockType;
    const longWin = tables.sineBlock[if (bt == 1) 1 else if (bt == 3) 3 else 0][0..];

    var sb: usize = 0;
    while (sb < 32) : (sb += 1) {
        var prevOverlap: [18]f64 = undefined;
        @memcpy(prevOverlap[0..], overlap[sb * 18 .. sb * 18 + 18]);
        var pcmSb: [18]f64 = [_]f64{0} ** 18;

        if (sfType == .short or (sfType == .mixed and sb >= 2)) {
            var s0: []const f64 = undefined;
            var s1: []const f64 = undefined;
            var s2: []const f64 = undefined;
            if (sfType == .short) {
                s0 = xr[sb * 6 .. sb * 6 + 6];
                s1 = xr[192 + sb * 6 .. 192 + sb * 6 + 6];
                s2 = xr[384 + sb * 6 .. 384 + sb * 6 + 6];
            } else {
                const off = (sb - 2) * 6;
                s0 = xr[36 + off .. 36 + off + 6];
                s1 = xr[36 + 180 + off .. 36 + 180 + off + 6];
                s2 = xr[36 + 360 + off .. 36 + 360 + off + 6];
            }
            processShort(s0, s1, s2, &prevOverlap, &pcmSb);
        } else {
            processLong(xr[sb * 18 .. sb * 18 + 18], longWin, &prevOverlap, &pcmSb);
        }

        @memcpy(overlap[sb * 18 .. sb * 18 + 18], prevOverlap[0..]);

        var t: usize = 0;
        while (t < 18) : (t += 1) {
            pcm[t * 32 + sb] = pcmSb[t];
        }
    }

    // Frequency inversion for Layer III hybrid synthesis.
    var t: usize = 1;
    while (t < 18) : (t += 2) {
        var sb2: usize = 1;
        while (sb2 < 32) : (sb2 += 2) {
            pcm[t * 32 + sb2] = -pcm[t * 32 + sb2];
        }
    }
    return pcm;
}
