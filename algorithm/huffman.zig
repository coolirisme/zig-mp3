// Scale factor parser
// Huffman decoder

const std = @import("std");
const bits = @import("./bits.zig");
const tables = @import("./tables.zig");

pub const SideInfo = @import("./sideinfo.zig").SideInfo;
pub const Granule = @import("./sideinfo.zig").Granule;

// --- Scale factor parsing (from Maindata.fs ScaleFactors module) ---

const SLEN = [_][2]u8{
    .{ 0, 0 }, .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 }, .{ 3, 0 }, .{ 1, 1 }, .{ 1, 2 }, .{ 1, 3 },
    .{ 2, 1 }, .{ 2, 2 }, .{ 2, 3 }, .{ 3, 1 }, .{ 3, 2 }, .{ 3, 3 }, .{ 4, 2 }, .{ 4, 3 },
};

pub const ScaleFactorObject = union(enum) {
    long: [22]i32,
    short: [3][13]i32,
    mixed: struct { long: [8]i32, short: [3][13]i32 },
};

pub const ParseScaleFactorsResult = struct {
    scaleFactors: ScaleFactorObject,
    bitsConsumed: usize,
};

/// Parse scale factors for one granule/channel.
pub fn parseScaleFactors(data: []const u8, sideInfo: SideInfo, granule: Granule, prevGranuleScaleLong: ?[2][22]i32) ParseScaleFactorsResult {
    var bitoffset: usize = 0;
    const sfl = SLEN[granule.scaleFactorCompress];
    const len0: usize = sfl[0];
    const len1: usize = sfl[1];

    if (granule.blockType == 2 and granule.windowSwitchFlag) {
        if (granule.mixedBlockFlag) {
            var longData: [8]i32 = [_]i32{0} ** 8;
            var i: usize = 0;
            while (i < 8) : (i += 1) {
                const r = bits.getBits2(bitoffset, len0, data);
                bitoffset = r.next;
                longData[i] = @intCast(r.value);
            }

            var shortData: [3][13]i32 = [_][13]i32{[_]i32{0} ** 13} ** 3;
            var sfb: usize = 3;
            while (sfb <= 5) : (sfb += 1) {
                var win: usize = 0;
                while (win < 3) : (win += 1) {
                    const r = bits.getBits2(bitoffset, len0, data);
                    bitoffset = r.next;
                    shortData[win][sfb] = @intCast(r.value);
                }
            }
            sfb = 6;
            while (sfb <= 11) : (sfb += 1) {
                var win: usize = 0;
                while (win < 3) : (win += 1) {
                    const r = bits.getBits2(bitoffset, len1, data);
                    bitoffset = r.next;
                    shortData[win][sfb] = @intCast(r.value);
                }
            }

            return .{ .scaleFactors = .{ .mixed = .{ .long = longData, .short = shortData } }, .bitsConsumed = bitoffset };
        }

        var shortData: [3][13]i32 = [_][13]i32{[_]i32{0} ** 13} ** 3;
        var sfb: usize = 0;
        while (sfb <= 5) : (sfb += 1) {
            var win: usize = 0;
            while (win < 3) : (win += 1) {
                const r = bits.getBits2(bitoffset, len0, data);
                bitoffset = r.next;
                shortData[win][sfb] = @intCast(r.value);
            }
        }
        sfb = 6;
        while (sfb <= 11) : (sfb += 1) {
            var win: usize = 0;
            while (win < 3) : (win += 1) {
                const r = bits.getBits2(bitoffset, len1, data);
                bitoffset = r.next;
                shortData[win][sfb] = @intCast(r.value);
            }
        }
        return .{ .scaleFactors = .{ .short = shortData }, .bitsConsumed = bitoffset };
    }

    // Long block
    var longData: [22]i32 = [_]i32{0} ** 22;
    if (granule.granule == 0) {
        var sfb: usize = 0;
        while (sfb <= 10) : (sfb += 1) {
            const r = bits.getBits2(bitoffset, len0, data);
            bitoffset = r.next;
            longData[sfb] = @intCast(r.value);
        }
        sfb = 11;
        while (sfb <= 20) : (sfb += 1) {
            const r = bits.getBits2(bitoffset, len1, data);
            bitoffset = r.next;
            longData[sfb] = @intCast(r.value);
        }
    } else {
        const sb = [_]usize{ 5, 10, 15, 20 };
        var index: usize = 0;
        var i: usize = 0;
        while (i <= 1) : (i += 1) {
            var sfb: usize = index;
            while (sfb <= sb[i]) : (sfb += 1) {
                if (sideInfo.scfsi[granule.channel][i] == 1 and prevGranuleScaleLong != null) {
                    longData[sfb] = prevGranuleScaleLong.?[granule.channel][sfb];
                } else {
                    const r = bits.getBits2(bitoffset, len0, data);
                    bitoffset = r.next;
                    longData[sfb] = @intCast(r.value);
                }
                index = sfb;
            }
            index += 1;
        }
        i = 2;
        while (i <= 3) : (i += 1) {
            var sfb: usize = index;
            while (sfb <= sb[i]) : (sfb += 1) {
                if (sideInfo.scfsi[granule.channel][i] == 1 and prevGranuleScaleLong != null) {
                    longData[sfb] = prevGranuleScaleLong.?[granule.channel][sfb];
                } else {
                    const r = bits.getBits2(bitoffset, len1, data);
                    bitoffset = r.next;
                    longData[sfb] = @intCast(r.value);
                }
                index = sfb;
            }
            index += 1;
        }
    }

    return .{ .scaleFactors = .{ .long = longData }, .bitsConsumed = bitoffset };
}

/// Decode Huffman-coded spectral data for one granule/channel.
pub fn parseHuffmanData(data: []const u8, offset: usize, maxbit: usize, bandIndexLong: []const u32, granule: Granule) [576]i32 {
    var samples: [576]i32 = [_]i32{0} ** 576;
    const bitsArray = data;

    var bitoffset = offset;
    var samplecount: usize = 0;

    var region0: u32 = 0;
    var region1: u32 = 0;
    if (granule.blockType == 2 and granule.windowSwitchFlag) {
        region0 = 36;
        region1 = 576;
    } else {
        region0 = bandIndexLong[granule.region0Count + 1];
        region1 = bandIndexLong[granule.region0Count + granule.region1Count + 2];
    }

    const Ctx = struct {
        table: []const []const tables.HuffCell,
        tableId: u8,
    };

    const getTable = struct {
        fn f(x: usize, gr: Granule, r0: u32, r1: u32) Ctx {
            if (x < r0) {
                return .{ .table = tables.getHuffmanTable(@intCast(gr.tableSelect[0])), .tableId = @intCast(gr.tableSelect[0]) };
            } else if (x < r1) {
                return .{ .table = tables.getHuffmanTable(@intCast(gr.tableSelect[1])), .tableId = @intCast(gr.tableSelect[1]) };
            } else {
                return .{ .table = tables.getHuffmanTable(@intCast(gr.tableSelect[2])), .tableId = @intCast(gr.tableSelect[2]) };
            }
        }
    }.f;

    const decodeTable = struct {
        fn f(ctx: Ctx, bitoff: *usize, arr: []const u8) struct { size: usize, row: usize, col: usize, tableId: u8 } {
            if (ctx.tableId == 0) {
                return .{ .size = 0, .row = 0, .col = 0, .tableId = 0 };
            }
            var rowIndex: usize = 0;
            while (rowIndex < ctx.table.len) : (rowIndex += 1) {
                const row = ctx.table[rowIndex];
                var colIndex: usize = 0;
                while (colIndex < row.len) : (colIndex += 1) {
                    const cell = row[colIndex];
                    const read = bits.getBits2(bitoff.*, cell.codeLength, arr);
                    if (read.value == cell.code) {
                        bitoff.* += cell.codeLength;
                        return .{ .size = cell.codeLength, .row = rowIndex, .col = colIndex, .tableId = ctx.tableId };
                    }
                }
            }
            return .{ .size = 0, .row = 0, .col = 0, .tableId = 0 };
        }
    }.f;

    const extendSample = struct {
        fn f(tableId: u8, value: i32, bitoff: *usize, arr: []const u8) i32 {
            var linbit: i32 = 0;
            if (tables.bigValueLinbit[tableId] != 0 and value == (@as(i32, tables.bigValueMax[tableId]) - 1)) {
                const read = bits.getBits2(bitoff.*, tables.bigValueLinbit[tableId], arr);
                bitoff.* = read.next;
                linbit = @intCast(read.value);
            }
            var sign: i32 = 1;
            if (value > 0) {
                const read = bits.getBits2(bitoff.*, 1, arr);
                bitoff.* = read.next;
                if (read.value == 1) sign = -1;
            }
            return sign * (value + linbit);
        }
    }.f;

    // Decode big-values region
    const bigValueLimit: usize = granule.bigValues * 2;
    while (samplecount < bigValueLimit) {
        const tableCtx = getTable(samplecount, granule, region0, region1);
            const decoded = decodeTable(tableCtx, &bitoffset, bitsArray);
        var s0: i32 = 0;
        var s1: i32 = 0;
        if (!(decoded.size == 0 and decoded.row == 0 and decoded.col == 0)) {
            s0 = extendSample(decoded.tableId, @intCast(decoded.row), &bitoffset, bitsArray);
            s1 = extendSample(decoded.tableId, @intCast(decoded.col), &bitoffset, bitsArray);
        }
        samples[samplecount] = s0;
        samples[samplecount + 1] = s1;
        samplecount += 2;
    }

    // Decode count1 (quad-values) region
    const quadStart = samplecount;
    var quadCount: usize = 0;
    var quadSamples: [576]i32 = [_]i32{0} ** 576;

    while (bitoffset < maxbit and (samplecount + 4) <= 576) {
        var quadvalues: [4]u8 = .{ 0, 0, 0, 0 };
        if (granule.count1TableSelect == 1) {
            if (bitoffset + 4 > maxbit or bitoffset + 4 > bitsArray.len) break;
            // count1 table B (htB): fixed 4-bit Huffman words where the decoded
            // quad is the bitwise complement of the code nibble.
            quadvalues = .{
                1 - bitsArray[bitoffset],
                1 - bitsArray[bitoffset + 1],
                1 - bitsArray[bitoffset + 2],
                1 - bitsArray[bitoffset + 3],
            };
            bitoffset += 4;
        } else {
            var matched = false;
            for (tables.quadTable) |q| {
                const readBits = bits.getBits32(bitoffset, q.huff.codeLength, bitsArray).value;
                if (q.huff.code == readBits) {
                    bitoffset += q.huff.codeLength;
                    quadvalues = q.value;
                    matched = true;
                    break;
                }
            }
            if (!matched) quadvalues = .{ 0, 0, 0, 0 };
        }

        const nonzeroCount = quadvalues[0] + quadvalues[1] + quadvalues[2] + quadvalues[3];
        var signBits: [4]u8 = .{ 0, 0, 0, 0 };
        if (bitoffset + nonzeroCount > maxbit or bitoffset + nonzeroCount > bitsArray.len) break;
        var i: usize = 0;
        while (i < nonzeroCount) : (i += 1) signBits[i] = bitsArray[bitoffset + i];

        var signIdx: usize = 0;
        var result: [4]i32 = .{ 0, 0, 0, 0 };
        i = 0;
        while (i < 4) : (i += 1) {
            if (quadvalues[i] == 0) {
                result[i] = 0;
            } else {
                const sign = signBits[signIdx];
                signIdx += 1;
                result[i] = if (sign == 1) -@as(i32, quadvalues[i]) else @as(i32, quadvalues[i]);
            }
        }

        bitoffset += nonzeroCount;

        // Match reference decoder behavior: if this quad overruns maxbit
        // (common with stuffing-bit slop), discard the whole quad.
        if (bitoffset > maxbit) break;

        samplecount += 4;
        quadSamples[quadCount] = result[0];
        quadSamples[quadCount + 1] = result[1];
        quadSamples[quadCount + 2] = result[2];
        quadSamples[quadCount + 3] = result[3];
        quadCount += 4;
    }

    var i: usize = 0;
    while (i < quadCount) : (i += 1) {
        samples[quadStart + i] = quadSamples[i];
    }

    return samples;
}
