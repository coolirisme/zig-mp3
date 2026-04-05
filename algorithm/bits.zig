// Bit manipulation utilities

const std = @import("std");

pub fn getBitsArrayFromByteArray(allocator: std.mem.Allocator, bytes: []const u8) ![]u8 {
    const out = try allocator.alloc(u8, bytes.len * 8);
    for (bytes, 0..) |b, i| {
        const base = i * 8;
        out[base] = @as(u8, (b >> 7) & 1);
        out[base + 1] = @as(u8, (b >> 6) & 1);
        out[base + 2] = @as(u8, (b >> 5) & 1);
        out[base + 3] = @as(u8, (b >> 4) & 1);
        out[base + 4] = @as(u8, (b >> 3) & 1);
        out[base + 5] = @as(u8, (b >> 2) & 1);
        out[base + 6] = @as(u8, (b >> 1) & 1);
        out[base + 7] = @as(u8, b & 1);
    }
    return out;
}

pub fn bitsArrayToNumber(bits: []const u8, start: usize, count: usize) u32 {
    var out: u32 = 0;
    var i: usize = 0;
    while (i < count) : (i += 1) {
        // Guard against truncated bitstreams by zero-filling missing bits.
        // Use arithmetic instead of bitwise ops: << and | coerce to signed int32,
        // which produces wrong (negative) results for count > 30.
        const bit: u8 = if (start + i < bits.len) bits[start + i] else 0;
        out = out * 2 + bit;
    }
    return out;
}

pub const BitsResult = struct {
    value: u32,
    next: usize,
};

pub fn getBits2(start: usize, count: usize, arr: []const u8) BitsResult {
    const value = bitsArrayToNumber(arr, start, count);
    const safe_advance = if (start >= arr.len) 0 else @min(count, arr.len - start);
    return .{ .value = value, .next = start + safe_advance };
}

pub fn getBits32(start: usize, count: usize, arr: []const u8) BitsResult {
    const value = bitsArrayToNumber(arr, start, count);
    const safe_advance = if (start >= arr.len) 0 else @min(count, arr.len - start);
    return .{ .value = value, .next = start + safe_advance };
}
