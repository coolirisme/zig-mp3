// Polyphase Synthesis Filter Bank (PQMF) for MPEG1 Layer III
// ISO/IEC 11172-3 Annex B §B.8

const std = @import("std");
const tables = @import("./tables.zig");

pub const PQMFState = struct {
    v: [1024]f64,
};

/// Create the per-channel PQMF history state.
pub fn createPQMFState() PQMFState {
    return .{ .v = [_]f64{0} ** 1024 };
}

/// Run one time step of the synthesis filterbank.
pub fn synthFilterStep(s: []const f64, state: *PQMFState, out: *[32]f64) void {
    const v = &state.v;

    // Step 2: Shift history right by 64, discarding the oldest 64 values.
    std.mem.copyBackwards(f64, v[64..1024], v[0..960]);

    // Step 1: Matrixing - fill V[0..63] with N · s.
    var i: usize = 0;
    while (i < 64) : (i += 1) {
        var sum: f64 = 0;
        var k: usize = 0;
        while (k < 32) : (k += 1) {
            const c = std.math.cos((std.math.pi / 64.0) * (16.0 + @as(f64, @floatFromInt(i))) * (2.0 * @as(f64, @floatFromInt(k)) + 1.0));
            sum += s[k] * c;
        }
        v[i] = sum;
    }

    // Step 3: Apply synthesis window D[] and accumulate 32 output samples.
    var j: usize = 0;
    while (j < 32) : (j += 1) {
        var sum: f64 = 0;
        var m: usize = 0;
        while (m < 8) : (m += 1) {
            sum += v[m * 128 + j] * tables.synthWindow[m * 64 + j];
            sum += v[m * 128 + 96 + j] * tables.synthWindow[m * 64 + 32 + j];
        }
        out[j] = sum;
    }
}
