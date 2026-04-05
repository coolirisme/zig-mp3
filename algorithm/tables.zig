// Huffman tables
// Each table is an array of rows. Each row is an array of [code, codeLength] pairs.
// Row index = x value, column index = y value of the decoded sample pair.

const std = @import("std");

pub const HuffCell = struct {
    code: u32,
    codeLength: u8,
};

pub const QuadCell = struct {
    huff: HuffCell,
    value: [4]u8,
};

pub const quadTable = [_]QuadCell{
    .{ .huff = .{ .code = 1, .codeLength = 1 }, .value = .{ 0, 0, 0, 0 } },
    .{ .huff = .{ .code = 5, .codeLength = 4 }, .value = .{ 0, 0, 0, 1 } },
    .{ .huff = .{ .code = 4, .codeLength = 4 }, .value = .{ 0, 0, 1, 0 } },
    .{ .huff = .{ .code = 5, .codeLength = 5 }, .value = .{ 0, 0, 1, 1 } },
    .{ .huff = .{ .code = 6, .codeLength = 4 }, .value = .{ 0, 1, 0, 0 } },
    .{ .huff = .{ .code = 5, .codeLength = 6 }, .value = .{ 0, 1, 0, 1 } },
    .{ .huff = .{ .code = 4, .codeLength = 5 }, .value = .{ 0, 1, 1, 0 } },
    .{ .huff = .{ .code = 4, .codeLength = 6 }, .value = .{ 0, 1, 1, 1 } },
    .{ .huff = .{ .code = 7, .codeLength = 4 }, .value = .{ 1, 0, 0, 0 } },
    .{ .huff = .{ .code = 3, .codeLength = 5 }, .value = .{ 1, 0, 0, 1 } },
    .{ .huff = .{ .code = 6, .codeLength = 5 }, .value = .{ 1, 0, 1, 0 } },
    .{ .huff = .{ .code = 0, .codeLength = 6 }, .value = .{ 1, 0, 1, 1 } },
    .{ .huff = .{ .code = 7, .codeLength = 5 }, .value = .{ 1, 1, 0, 0 } },
    .{ .huff = .{ .code = 2, .codeLength = 6 }, .value = .{ 1, 1, 0, 1 } },
    .{ .huff = .{ .code = 3, .codeLength = 6 }, .value = .{ 1, 1, 1, 0 } },
    .{ .huff = .{ .code = 1, .codeLength = 6 }, .value = .{ 1, 1, 1, 1 } },
};

const table0_row_0 = [_]HuffCell{ .{ .code = 0, .codeLength = 1 } };
pub const table0 = [_][]const HuffCell{
    table0_row_0[0..],
};

const table1_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 1, .codeLength = 3 } };
const table1_row_1 = [_]HuffCell{ .{ .code = 1, .codeLength = 2 }, .{ .code = 0, .codeLength = 3 } };
pub const table1 = [_][]const HuffCell{
    table1_row_0[0..],
    table1_row_1[0..],
};

const table2_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 2, .codeLength = 3 }, .{ .code = 1, .codeLength = 6 } };
const table2_row_1 = [_]HuffCell{ .{ .code = 3, .codeLength = 3 }, .{ .code = 1, .codeLength = 3 }, .{ .code = 1, .codeLength = 5 } };
const table2_row_2 = [_]HuffCell{ .{ .code = 3, .codeLength = 5 }, .{ .code = 2, .codeLength = 5 }, .{ .code = 0, .codeLength = 6 } };
pub const table2 = [_][]const HuffCell{
    table2_row_0[0..],
    table2_row_1[0..],
    table2_row_2[0..],
};

const table3_row_0 = [_]HuffCell{ .{ .code = 3, .codeLength = 2 }, .{ .code = 2, .codeLength = 2 }, .{ .code = 1, .codeLength = 6 } };
const table3_row_1 = [_]HuffCell{ .{ .code = 1, .codeLength = 3 }, .{ .code = 1, .codeLength = 2 }, .{ .code = 1, .codeLength = 5 } };
const table3_row_2 = [_]HuffCell{ .{ .code = 3, .codeLength = 5 }, .{ .code = 2, .codeLength = 5 }, .{ .code = 0, .codeLength = 6 } };
pub const table3 = [_][]const HuffCell{
    table3_row_0[0..],
    table3_row_1[0..],
    table3_row_2[0..],
};

const table5_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 2, .codeLength = 3 }, .{ .code = 6, .codeLength = 6 }, .{ .code = 5, .codeLength = 7 } };
const table5_row_1 = [_]HuffCell{ .{ .code = 3, .codeLength = 3 }, .{ .code = 1, .codeLength = 3 }, .{ .code = 4, .codeLength = 6 }, .{ .code = 4, .codeLength = 7 } };
const table5_row_2 = [_]HuffCell{ .{ .code = 7, .codeLength = 6 }, .{ .code = 5, .codeLength = 6 }, .{ .code = 7, .codeLength = 7 }, .{ .code = 1, .codeLength = 8 } };
const table5_row_3 = [_]HuffCell{ .{ .code = 6, .codeLength = 7 }, .{ .code = 1, .codeLength = 6 }, .{ .code = 1, .codeLength = 7 }, .{ .code = 0, .codeLength = 8 } };
pub const table5 = [_][]const HuffCell{
    table5_row_0[0..],
    table5_row_1[0..],
    table5_row_2[0..],
    table5_row_3[0..],
};

const table6_row_0 = [_]HuffCell{ .{ .code = 7, .codeLength = 3 }, .{ .code = 3, .codeLength = 3 }, .{ .code = 5, .codeLength = 5 }, .{ .code = 1, .codeLength = 7 } };
const table6_row_1 = [_]HuffCell{ .{ .code = 6, .codeLength = 3 }, .{ .code = 2, .codeLength = 2 }, .{ .code = 3, .codeLength = 4 }, .{ .code = 2, .codeLength = 5 } };
const table6_row_2 = [_]HuffCell{ .{ .code = 5, .codeLength = 4 }, .{ .code = 4, .codeLength = 4 }, .{ .code = 4, .codeLength = 5 }, .{ .code = 1, .codeLength = 6 } };
const table6_row_3 = [_]HuffCell{ .{ .code = 3, .codeLength = 6 }, .{ .code = 3, .codeLength = 5 }, .{ .code = 2, .codeLength = 6 }, .{ .code = 0, .codeLength = 7 } };
pub const table6 = [_][]const HuffCell{
    table6_row_0[0..],
    table6_row_1[0..],
    table6_row_2[0..],
    table6_row_3[0..],
};

const table7_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 2, .codeLength = 3 }, .{ .code = 10, .codeLength = 6 }, .{ .code = 19, .codeLength = 8 }, .{ .code = 16, .codeLength = 8 }, .{ .code = 10, .codeLength = 9 } };
const table7_row_1 = [_]HuffCell{ .{ .code = 3, .codeLength = 3 }, .{ .code = 3, .codeLength = 4 }, .{ .code = 7, .codeLength = 6 }, .{ .code = 10, .codeLength = 7 }, .{ .code = 5, .codeLength = 7 }, .{ .code = 3, .codeLength = 8 } };
const table7_row_2 = [_]HuffCell{ .{ .code = 11, .codeLength = 6 }, .{ .code = 4, .codeLength = 5 }, .{ .code = 13, .codeLength = 7 }, .{ .code = 17, .codeLength = 8 }, .{ .code = 8, .codeLength = 8 }, .{ .code = 4, .codeLength = 9 } };
const table7_row_3 = [_]HuffCell{ .{ .code = 12, .codeLength = 7 }, .{ .code = 11, .codeLength = 7 }, .{ .code = 18, .codeLength = 8 }, .{ .code = 15, .codeLength = 9 }, .{ .code = 11, .codeLength = 9 }, .{ .code = 2, .codeLength = 9 } };
const table7_row_4 = [_]HuffCell{ .{ .code = 7, .codeLength = 7 }, .{ .code = 6, .codeLength = 7 }, .{ .code = 9, .codeLength = 8 }, .{ .code = 14, .codeLength = 9 }, .{ .code = 3, .codeLength = 9 }, .{ .code = 1, .codeLength = 10 } };
const table7_row_5 = [_]HuffCell{ .{ .code = 6, .codeLength = 8 }, .{ .code = 4, .codeLength = 8 }, .{ .code = 5, .codeLength = 9 }, .{ .code = 3, .codeLength = 10 }, .{ .code = 2, .codeLength = 10 }, .{ .code = 0, .codeLength = 10 } };
pub const table7 = [_][]const HuffCell{
    table7_row_0[0..],
    table7_row_1[0..],
    table7_row_2[0..],
    table7_row_3[0..],
    table7_row_4[0..],
    table7_row_5[0..],
};

const table8_row_0 = [_]HuffCell{ .{ .code = 3, .codeLength = 2 }, .{ .code = 4, .codeLength = 3 }, .{ .code = 6, .codeLength = 6 }, .{ .code = 18, .codeLength = 8 }, .{ .code = 12, .codeLength = 8 }, .{ .code = 5, .codeLength = 9 } };
const table8_row_1 = [_]HuffCell{ .{ .code = 5, .codeLength = 3 }, .{ .code = 1, .codeLength = 2 }, .{ .code = 2, .codeLength = 4 }, .{ .code = 16, .codeLength = 8 }, .{ .code = 9, .codeLength = 8 }, .{ .code = 3, .codeLength = 8 } };
const table8_row_2 = [_]HuffCell{ .{ .code = 7, .codeLength = 6 }, .{ .code = 3, .codeLength = 4 }, .{ .code = 5, .codeLength = 6 }, .{ .code = 14, .codeLength = 8 }, .{ .code = 7, .codeLength = 8 }, .{ .code = 3, .codeLength = 9 } };
const table8_row_3 = [_]HuffCell{ .{ .code = 19, .codeLength = 8 }, .{ .code = 17, .codeLength = 8 }, .{ .code = 15, .codeLength = 8 }, .{ .code = 13, .codeLength = 9 }, .{ .code = 10, .codeLength = 9 }, .{ .code = 4, .codeLength = 10 } };
const table8_row_4 = [_]HuffCell{ .{ .code = 13, .codeLength = 8 }, .{ .code = 5, .codeLength = 7 }, .{ .code = 8, .codeLength = 8 }, .{ .code = 11, .codeLength = 9 }, .{ .code = 5, .codeLength = 10 }, .{ .code = 1, .codeLength = 10 } };
const table8_row_5 = [_]HuffCell{ .{ .code = 12, .codeLength = 9 }, .{ .code = 4, .codeLength = 8 }, .{ .code = 4, .codeLength = 9 }, .{ .code = 1, .codeLength = 9 }, .{ .code = 1, .codeLength = 11 }, .{ .code = 0, .codeLength = 11 } };
pub const table8 = [_][]const HuffCell{
    table8_row_0[0..],
    table8_row_1[0..],
    table8_row_2[0..],
    table8_row_3[0..],
    table8_row_4[0..],
    table8_row_5[0..],
};

const table9_row_0 = [_]HuffCell{ .{ .code = 7, .codeLength = 3 }, .{ .code = 5, .codeLength = 3 }, .{ .code = 9, .codeLength = 5 }, .{ .code = 14, .codeLength = 6 }, .{ .code = 15, .codeLength = 8 }, .{ .code = 7, .codeLength = 9 } };
const table9_row_1 = [_]HuffCell{ .{ .code = 6, .codeLength = 3 }, .{ .code = 4, .codeLength = 3 }, .{ .code = 5, .codeLength = 4 }, .{ .code = 5, .codeLength = 5 }, .{ .code = 6, .codeLength = 6 }, .{ .code = 7, .codeLength = 8 } };
const table9_row_2 = [_]HuffCell{ .{ .code = 7, .codeLength = 4 }, .{ .code = 6, .codeLength = 4 }, .{ .code = 8, .codeLength = 5 }, .{ .code = 8, .codeLength = 6 }, .{ .code = 8, .codeLength = 7 }, .{ .code = 5, .codeLength = 8 } };
const table9_row_3 = [_]HuffCell{ .{ .code = 15, .codeLength = 6 }, .{ .code = 6, .codeLength = 5 }, .{ .code = 9, .codeLength = 6 }, .{ .code = 10, .codeLength = 7 }, .{ .code = 5, .codeLength = 7 }, .{ .code = 1, .codeLength = 8 } };
const table9_row_4 = [_]HuffCell{ .{ .code = 11, .codeLength = 7 }, .{ .code = 7, .codeLength = 6 }, .{ .code = 9, .codeLength = 7 }, .{ .code = 6, .codeLength = 7 }, .{ .code = 4, .codeLength = 8 }, .{ .code = 1, .codeLength = 9 } };
const table9_row_5 = [_]HuffCell{ .{ .code = 14, .codeLength = 8 }, .{ .code = 4, .codeLength = 7 }, .{ .code = 6, .codeLength = 8 }, .{ .code = 2, .codeLength = 8 }, .{ .code = 6, .codeLength = 9 }, .{ .code = 0, .codeLength = 9 } };
pub const table9 = [_][]const HuffCell{
    table9_row_0[0..],
    table9_row_1[0..],
    table9_row_2[0..],
    table9_row_3[0..],
    table9_row_4[0..],
    table9_row_5[0..],
};

const table10_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 2, .codeLength = 3 }, .{ .code = 10, .codeLength = 6 }, .{ .code = 23, .codeLength = 8 }, .{ .code = 35, .codeLength = 9 }, .{ .code = 30, .codeLength = 9 }, .{ .code = 12, .codeLength = 9 }, .{ .code = 17, .codeLength = 10 } };
const table10_row_1 = [_]HuffCell{ .{ .code = 3, .codeLength = 3 }, .{ .code = 3, .codeLength = 4 }, .{ .code = 8, .codeLength = 6 }, .{ .code = 12, .codeLength = 7 }, .{ .code = 18, .codeLength = 8 }, .{ .code = 21, .codeLength = 9 }, .{ .code = 12, .codeLength = 8 }, .{ .code = 7, .codeLength = 8 } };
const table10_row_2 = [_]HuffCell{ .{ .code = 11, .codeLength = 6 }, .{ .code = 9, .codeLength = 6 }, .{ .code = 15, .codeLength = 7 }, .{ .code = 21, .codeLength = 8 }, .{ .code = 32, .codeLength = 9 }, .{ .code = 40, .codeLength = 10 }, .{ .code = 19, .codeLength = 9 }, .{ .code = 6, .codeLength = 9 } };
const table10_row_3 = [_]HuffCell{ .{ .code = 14, .codeLength = 7 }, .{ .code = 13, .codeLength = 7 }, .{ .code = 22, .codeLength = 8 }, .{ .code = 34, .codeLength = 9 }, .{ .code = 46, .codeLength = 10 }, .{ .code = 23, .codeLength = 10 }, .{ .code = 18, .codeLength = 9 }, .{ .code = 7, .codeLength = 10 } };
const table10_row_4 = [_]HuffCell{ .{ .code = 20, .codeLength = 8 }, .{ .code = 19, .codeLength = 8 }, .{ .code = 33, .codeLength = 9 }, .{ .code = 47, .codeLength = 10 }, .{ .code = 27, .codeLength = 10 }, .{ .code = 22, .codeLength = 10 }, .{ .code = 9, .codeLength = 10 }, .{ .code = 3, .codeLength = 10 } };
const table10_row_5 = [_]HuffCell{ .{ .code = 31, .codeLength = 9 }, .{ .code = 22, .codeLength = 9 }, .{ .code = 41, .codeLength = 10 }, .{ .code = 26, .codeLength = 10 }, .{ .code = 21, .codeLength = 11 }, .{ .code = 20, .codeLength = 11 }, .{ .code = 5, .codeLength = 10 }, .{ .code = 3, .codeLength = 11 } };
const table10_row_6 = [_]HuffCell{ .{ .code = 14, .codeLength = 8 }, .{ .code = 13, .codeLength = 8 }, .{ .code = 10, .codeLength = 9 }, .{ .code = 11, .codeLength = 10 }, .{ .code = 16, .codeLength = 10 }, .{ .code = 6, .codeLength = 10 }, .{ .code = 5, .codeLength = 11 }, .{ .code = 1, .codeLength = 11 } };
const table10_row_7 = [_]HuffCell{ .{ .code = 9, .codeLength = 9 }, .{ .code = 8, .codeLength = 8 }, .{ .code = 7, .codeLength = 9 }, .{ .code = 8, .codeLength = 10 }, .{ .code = 4, .codeLength = 10 }, .{ .code = 4, .codeLength = 11 }, .{ .code = 2, .codeLength = 11 }, .{ .code = 0, .codeLength = 11 } };
pub const table10 = [_][]const HuffCell{
    table10_row_0[0..],
    table10_row_1[0..],
    table10_row_2[0..],
    table10_row_3[0..],
    table10_row_4[0..],
    table10_row_5[0..],
    table10_row_6[0..],
    table10_row_7[0..],
};

const table11_row_0 = [_]HuffCell{ .{ .code = 3, .codeLength = 2 }, .{ .code = 4, .codeLength = 3 }, .{ .code = 10, .codeLength = 5 }, .{ .code = 24, .codeLength = 7 }, .{ .code = 34, .codeLength = 8 }, .{ .code = 33, .codeLength = 9 }, .{ .code = 21, .codeLength = 8 }, .{ .code = 15, .codeLength = 9 } };
const table11_row_1 = [_]HuffCell{ .{ .code = 5, .codeLength = 3 }, .{ .code = 3, .codeLength = 3 }, .{ .code = 4, .codeLength = 4 }, .{ .code = 10, .codeLength = 6 }, .{ .code = 32, .codeLength = 8 }, .{ .code = 17, .codeLength = 8 }, .{ .code = 11, .codeLength = 7 }, .{ .code = 10, .codeLength = 8 } };
const table11_row_2 = [_]HuffCell{ .{ .code = 11, .codeLength = 5 }, .{ .code = 7, .codeLength = 5 }, .{ .code = 13, .codeLength = 6 }, .{ .code = 18, .codeLength = 7 }, .{ .code = 30, .codeLength = 8 }, .{ .code = 31, .codeLength = 9 }, .{ .code = 20, .codeLength = 8 }, .{ .code = 5, .codeLength = 8 } };
const table11_row_3 = [_]HuffCell{ .{ .code = 25, .codeLength = 7 }, .{ .code = 11, .codeLength = 6 }, .{ .code = 19, .codeLength = 7 }, .{ .code = 59, .codeLength = 9 }, .{ .code = 27, .codeLength = 8 }, .{ .code = 18, .codeLength = 10 }, .{ .code = 12, .codeLength = 8 }, .{ .code = 5, .codeLength = 9 } };
const table11_row_4 = [_]HuffCell{ .{ .code = 35, .codeLength = 8 }, .{ .code = 33, .codeLength = 8 }, .{ .code = 31, .codeLength = 8 }, .{ .code = 58, .codeLength = 9 }, .{ .code = 30, .codeLength = 9 }, .{ .code = 16, .codeLength = 10 }, .{ .code = 7, .codeLength = 9 }, .{ .code = 5, .codeLength = 10 } };
const table11_row_5 = [_]HuffCell{ .{ .code = 28, .codeLength = 8 }, .{ .code = 26, .codeLength = 8 }, .{ .code = 32, .codeLength = 9 }, .{ .code = 19, .codeLength = 10 }, .{ .code = 17, .codeLength = 10 }, .{ .code = 15, .codeLength = 11 }, .{ .code = 8, .codeLength = 10 }, .{ .code = 14, .codeLength = 11 } };
const table11_row_6 = [_]HuffCell{ .{ .code = 14, .codeLength = 8 }, .{ .code = 12, .codeLength = 7 }, .{ .code = 9, .codeLength = 7 }, .{ .code = 13, .codeLength = 8 }, .{ .code = 14, .codeLength = 9 }, .{ .code = 9, .codeLength = 10 }, .{ .code = 4, .codeLength = 10 }, .{ .code = 1, .codeLength = 10 } };
const table11_row_7 = [_]HuffCell{ .{ .code = 11, .codeLength = 8 }, .{ .code = 4, .codeLength = 7 }, .{ .code = 6, .codeLength = 8 }, .{ .code = 6, .codeLength = 9 }, .{ .code = 6, .codeLength = 10 }, .{ .code = 3, .codeLength = 10 }, .{ .code = 2, .codeLength = 10 }, .{ .code = 0, .codeLength = 10 } };
pub const table11 = [_][]const HuffCell{
    table11_row_0[0..],
    table11_row_1[0..],
    table11_row_2[0..],
    table11_row_3[0..],
    table11_row_4[0..],
    table11_row_5[0..],
    table11_row_6[0..],
    table11_row_7[0..],
};

const table12_row_0 = [_]HuffCell{ .{ .code = 9, .codeLength = 4 }, .{ .code = 6, .codeLength = 3 }, .{ .code = 16, .codeLength = 5 }, .{ .code = 33, .codeLength = 7 }, .{ .code = 41, .codeLength = 8 }, .{ .code = 39, .codeLength = 9 }, .{ .code = 38, .codeLength = 9 }, .{ .code = 26, .codeLength = 9 } };
const table12_row_1 = [_]HuffCell{ .{ .code = 7, .codeLength = 3 }, .{ .code = 5, .codeLength = 3 }, .{ .code = 6, .codeLength = 4 }, .{ .code = 9, .codeLength = 5 }, .{ .code = 23, .codeLength = 7 }, .{ .code = 16, .codeLength = 7 }, .{ .code = 26, .codeLength = 8 }, .{ .code = 11, .codeLength = 8 } };
const table12_row_2 = [_]HuffCell{ .{ .code = 17, .codeLength = 5 }, .{ .code = 7, .codeLength = 4 }, .{ .code = 11, .codeLength = 5 }, .{ .code = 14, .codeLength = 6 }, .{ .code = 21, .codeLength = 7 }, .{ .code = 30, .codeLength = 8 }, .{ .code = 10, .codeLength = 7 }, .{ .code = 7, .codeLength = 8 } };
const table12_row_3 = [_]HuffCell{ .{ .code = 17, .codeLength = 6 }, .{ .code = 10, .codeLength = 5 }, .{ .code = 15, .codeLength = 6 }, .{ .code = 12, .codeLength = 6 }, .{ .code = 18, .codeLength = 7 }, .{ .code = 28, .codeLength = 8 }, .{ .code = 14, .codeLength = 8 }, .{ .code = 5, .codeLength = 8 } };
const table12_row_4 = [_]HuffCell{ .{ .code = 32, .codeLength = 7 }, .{ .code = 13, .codeLength = 6 }, .{ .code = 22, .codeLength = 7 }, .{ .code = 19, .codeLength = 7 }, .{ .code = 18, .codeLength = 8 }, .{ .code = 16, .codeLength = 8 }, .{ .code = 9, .codeLength = 8 }, .{ .code = 5, .codeLength = 9 } };
const table12_row_5 = [_]HuffCell{ .{ .code = 40, .codeLength = 8 }, .{ .code = 17, .codeLength = 7 }, .{ .code = 31, .codeLength = 8 }, .{ .code = 29, .codeLength = 8 }, .{ .code = 17, .codeLength = 8 }, .{ .code = 13, .codeLength = 9 }, .{ .code = 4, .codeLength = 8 }, .{ .code = 2, .codeLength = 9 } };
const table12_row_6 = [_]HuffCell{ .{ .code = 27, .codeLength = 8 }, .{ .code = 12, .codeLength = 7 }, .{ .code = 11, .codeLength = 7 }, .{ .code = 15, .codeLength = 8 }, .{ .code = 10, .codeLength = 8 }, .{ .code = 7, .codeLength = 9 }, .{ .code = 4, .codeLength = 9 }, .{ .code = 1, .codeLength = 10 } };
const table12_row_7 = [_]HuffCell{ .{ .code = 27, .codeLength = 9 }, .{ .code = 12, .codeLength = 8 }, .{ .code = 8, .codeLength = 8 }, .{ .code = 12, .codeLength = 9 }, .{ .code = 6, .codeLength = 9 }, .{ .code = 3, .codeLength = 9 }, .{ .code = 1, .codeLength = 9 }, .{ .code = 0, .codeLength = 10 } };
pub const table12 = [_][]const HuffCell{
    table12_row_0[0..],
    table12_row_1[0..],
    table12_row_2[0..],
    table12_row_3[0..],
    table12_row_4[0..],
    table12_row_5[0..],
    table12_row_6[0..],
    table12_row_7[0..],
};

const table13_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 5, .codeLength = 4 }, .{ .code = 14, .codeLength = 6 }, .{ .code = 21, .codeLength = 7 }, .{ .code = 34, .codeLength = 8 }, .{ .code = 51, .codeLength = 9 }, .{ .code = 46, .codeLength = 9 }, .{ .code = 71, .codeLength = 10 }, .{ .code = 42, .codeLength = 9 }, .{ .code = 52, .codeLength = 10 }, .{ .code = 68, .codeLength = 11 }, .{ .code = 52, .codeLength = 11 }, .{ .code = 67, .codeLength = 12 }, .{ .code = 44, .codeLength = 12 }, .{ .code = 43, .codeLength = 13 }, .{ .code = 19, .codeLength = 13 } };
const table13_row_1 = [_]HuffCell{ .{ .code = 3, .codeLength = 3 }, .{ .code = 4, .codeLength = 4 }, .{ .code = 12, .codeLength = 6 }, .{ .code = 19, .codeLength = 7 }, .{ .code = 31, .codeLength = 8 }, .{ .code = 26, .codeLength = 8 }, .{ .code = 44, .codeLength = 9 }, .{ .code = 33, .codeLength = 9 }, .{ .code = 31, .codeLength = 9 }, .{ .code = 24, .codeLength = 9 }, .{ .code = 32, .codeLength = 10 }, .{ .code = 24, .codeLength = 10 }, .{ .code = 31, .codeLength = 11 }, .{ .code = 35, .codeLength = 12 }, .{ .code = 22, .codeLength = 12 }, .{ .code = 14, .codeLength = 12 } };
const table13_row_2 = [_]HuffCell{ .{ .code = 15, .codeLength = 6 }, .{ .code = 13, .codeLength = 6 }, .{ .code = 23, .codeLength = 7 }, .{ .code = 36, .codeLength = 8 }, .{ .code = 59, .codeLength = 9 }, .{ .code = 49, .codeLength = 9 }, .{ .code = 77, .codeLength = 10 }, .{ .code = 65, .codeLength = 10 }, .{ .code = 29, .codeLength = 9 }, .{ .code = 40, .codeLength = 10 }, .{ .code = 30, .codeLength = 10 }, .{ .code = 40, .codeLength = 11 }, .{ .code = 27, .codeLength = 11 }, .{ .code = 33, .codeLength = 12 }, .{ .code = 42, .codeLength = 13 }, .{ .code = 16, .codeLength = 13 } };
const table13_row_3 = [_]HuffCell{ .{ .code = 22, .codeLength = 7 }, .{ .code = 20, .codeLength = 7 }, .{ .code = 37, .codeLength = 8 }, .{ .code = 61, .codeLength = 9 }, .{ .code = 56, .codeLength = 9 }, .{ .code = 79, .codeLength = 10 }, .{ .code = 73, .codeLength = 10 }, .{ .code = 64, .codeLength = 10 }, .{ .code = 43, .codeLength = 10 }, .{ .code = 76, .codeLength = 11 }, .{ .code = 56, .codeLength = 11 }, .{ .code = 37, .codeLength = 11 }, .{ .code = 26, .codeLength = 11 }, .{ .code = 31, .codeLength = 12 }, .{ .code = 25, .codeLength = 13 }, .{ .code = 14, .codeLength = 13 } };
const table13_row_4 = [_]HuffCell{ .{ .code = 35, .codeLength = 8 }, .{ .code = 16, .codeLength = 7 }, .{ .code = 60, .codeLength = 9 }, .{ .code = 57, .codeLength = 9 }, .{ .code = 97, .codeLength = 10 }, .{ .code = 75, .codeLength = 10 }, .{ .code = 114, .codeLength = 11 }, .{ .code = 91, .codeLength = 11 }, .{ .code = 54, .codeLength = 10 }, .{ .code = 73, .codeLength = 11 }, .{ .code = 55, .codeLength = 11 }, .{ .code = 41, .codeLength = 12 }, .{ .code = 48, .codeLength = 12 }, .{ .code = 53, .codeLength = 13 }, .{ .code = 23, .codeLength = 13 }, .{ .code = 24, .codeLength = 14 } };
const table13_row_5 = [_]HuffCell{ .{ .code = 58, .codeLength = 9 }, .{ .code = 27, .codeLength = 8 }, .{ .code = 50, .codeLength = 9 }, .{ .code = 96, .codeLength = 10 }, .{ .code = 76, .codeLength = 10 }, .{ .code = 70, .codeLength = 10 }, .{ .code = 93, .codeLength = 11 }, .{ .code = 84, .codeLength = 11 }, .{ .code = 77, .codeLength = 11 }, .{ .code = 58, .codeLength = 11 }, .{ .code = 79, .codeLength = 12 }, .{ .code = 29, .codeLength = 11 }, .{ .code = 74, .codeLength = 13 }, .{ .code = 49, .codeLength = 13 }, .{ .code = 41, .codeLength = 14 }, .{ .code = 17, .codeLength = 14 } };
const table13_row_6 = [_]HuffCell{ .{ .code = 47, .codeLength = 9 }, .{ .code = 45, .codeLength = 9 }, .{ .code = 78, .codeLength = 10 }, .{ .code = 74, .codeLength = 10 }, .{ .code = 115, .codeLength = 11 }, .{ .code = 94, .codeLength = 11 }, .{ .code = 90, .codeLength = 11 }, .{ .code = 79, .codeLength = 11 }, .{ .code = 69, .codeLength = 11 }, .{ .code = 83, .codeLength = 12 }, .{ .code = 71, .codeLength = 12 }, .{ .code = 50, .codeLength = 12 }, .{ .code = 59, .codeLength = 13 }, .{ .code = 38, .codeLength = 13 }, .{ .code = 36, .codeLength = 14 }, .{ .code = 15, .codeLength = 14 } };
const table13_row_7 = [_]HuffCell{ .{ .code = 72, .codeLength = 10 }, .{ .code = 34, .codeLength = 9 }, .{ .code = 56, .codeLength = 10 }, .{ .code = 95, .codeLength = 11 }, .{ .code = 92, .codeLength = 11 }, .{ .code = 85, .codeLength = 11 }, .{ .code = 91, .codeLength = 12 }, .{ .code = 90, .codeLength = 12 }, .{ .code = 86, .codeLength = 12 }, .{ .code = 73, .codeLength = 12 }, .{ .code = 77, .codeLength = 13 }, .{ .code = 65, .codeLength = 13 }, .{ .code = 51, .codeLength = 13 }, .{ .code = 44, .codeLength = 14 }, .{ .code = 43, .codeLength = 16 }, .{ .code = 42, .codeLength = 16 } };
const table13_row_8 = [_]HuffCell{ .{ .code = 43, .codeLength = 9 }, .{ .code = 20, .codeLength = 8 }, .{ .code = 30, .codeLength = 9 }, .{ .code = 44, .codeLength = 10 }, .{ .code = 55, .codeLength = 10 }, .{ .code = 78, .codeLength = 11 }, .{ .code = 72, .codeLength = 11 }, .{ .code = 87, .codeLength = 12 }, .{ .code = 78, .codeLength = 12 }, .{ .code = 61, .codeLength = 12 }, .{ .code = 46, .codeLength = 12 }, .{ .code = 54, .codeLength = 13 }, .{ .code = 37, .codeLength = 13 }, .{ .code = 30, .codeLength = 14 }, .{ .code = 20, .codeLength = 15 }, .{ .code = 16, .codeLength = 15 } };
const table13_row_9 = [_]HuffCell{ .{ .code = 53, .codeLength = 10 }, .{ .code = 25, .codeLength = 9 }, .{ .code = 41, .codeLength = 10 }, .{ .code = 37, .codeLength = 10 }, .{ .code = 44, .codeLength = 11 }, .{ .code = 59, .codeLength = 11 }, .{ .code = 54, .codeLength = 11 }, .{ .code = 81, .codeLength = 13 }, .{ .code = 66, .codeLength = 12 }, .{ .code = 76, .codeLength = 13 }, .{ .code = 57, .codeLength = 13 }, .{ .code = 54, .codeLength = 14 }, .{ .code = 37, .codeLength = 14 }, .{ .code = 18, .codeLength = 14 }, .{ .code = 39, .codeLength = 16 }, .{ .code = 11, .codeLength = 15 } };
const table13_row_10 = [_]HuffCell{ .{ .code = 35, .codeLength = 10 }, .{ .code = 33, .codeLength = 10 }, .{ .code = 31, .codeLength = 10 }, .{ .code = 57, .codeLength = 11 }, .{ .code = 42, .codeLength = 11 }, .{ .code = 82, .codeLength = 12 }, .{ .code = 72, .codeLength = 12 }, .{ .code = 80, .codeLength = 13 }, .{ .code = 47, .codeLength = 12 }, .{ .code = 58, .codeLength = 13 }, .{ .code = 55, .codeLength = 14 }, .{ .code = 21, .codeLength = 13 }, .{ .code = 22, .codeLength = 14 }, .{ .code = 26, .codeLength = 15 }, .{ .code = 38, .codeLength = 16 }, .{ .code = 22, .codeLength = 17 } };
const table13_row_11 = [_]HuffCell{ .{ .code = 53, .codeLength = 11 }, .{ .code = 25, .codeLength = 10 }, .{ .code = 23, .codeLength = 10 }, .{ .code = 38, .codeLength = 11 }, .{ .code = 70, .codeLength = 12 }, .{ .code = 60, .codeLength = 12 }, .{ .code = 51, .codeLength = 12 }, .{ .code = 36, .codeLength = 12 }, .{ .code = 55, .codeLength = 13 }, .{ .code = 26, .codeLength = 13 }, .{ .code = 34, .codeLength = 13 }, .{ .code = 23, .codeLength = 14 }, .{ .code = 27, .codeLength = 15 }, .{ .code = 14, .codeLength = 15 }, .{ .code = 9, .codeLength = 15 }, .{ .code = 7, .codeLength = 16 } };
const table13_row_12 = [_]HuffCell{ .{ .code = 34, .codeLength = 11 }, .{ .code = 32, .codeLength = 11 }, .{ .code = 28, .codeLength = 11 }, .{ .code = 39, .codeLength = 12 }, .{ .code = 49, .codeLength = 12 }, .{ .code = 75, .codeLength = 13 }, .{ .code = 30, .codeLength = 12 }, .{ .code = 52, .codeLength = 13 }, .{ .code = 48, .codeLength = 14 }, .{ .code = 40, .codeLength = 14 }, .{ .code = 52, .codeLength = 15 }, .{ .code = 28, .codeLength = 15 }, .{ .code = 18, .codeLength = 15 }, .{ .code = 17, .codeLength = 16 }, .{ .code = 9, .codeLength = 16 }, .{ .code = 5, .codeLength = 16 } };
const table13_row_13 = [_]HuffCell{ .{ .code = 45, .codeLength = 12 }, .{ .code = 21, .codeLength = 11 }, .{ .code = 34, .codeLength = 12 }, .{ .code = 64, .codeLength = 13 }, .{ .code = 56, .codeLength = 13 }, .{ .code = 50, .codeLength = 13 }, .{ .code = 49, .codeLength = 14 }, .{ .code = 45, .codeLength = 14 }, .{ .code = 31, .codeLength = 14 }, .{ .code = 19, .codeLength = 14 }, .{ .code = 12, .codeLength = 14 }, .{ .code = 15, .codeLength = 15 }, .{ .code = 10, .codeLength = 16 }, .{ .code = 7, .codeLength = 15 }, .{ .code = 6, .codeLength = 16 }, .{ .code = 3, .codeLength = 16 } };
const table13_row_14 = [_]HuffCell{ .{ .code = 48, .codeLength = 13 }, .{ .code = 23, .codeLength = 12 }, .{ .code = 20, .codeLength = 12 }, .{ .code = 39, .codeLength = 13 }, .{ .code = 36, .codeLength = 13 }, .{ .code = 35, .codeLength = 13 }, .{ .code = 53, .codeLength = 15 }, .{ .code = 21, .codeLength = 14 }, .{ .code = 16, .codeLength = 14 }, .{ .code = 23, .codeLength = 17 }, .{ .code = 13, .codeLength = 15 }, .{ .code = 10, .codeLength = 15 }, .{ .code = 6, .codeLength = 15 }, .{ .code = 1, .codeLength = 17 }, .{ .code = 4, .codeLength = 16 }, .{ .code = 2, .codeLength = 16 } };
const table13_row_15 = [_]HuffCell{ .{ .code = 16, .codeLength = 12 }, .{ .code = 15, .codeLength = 12 }, .{ .code = 17, .codeLength = 13 }, .{ .code = 27, .codeLength = 14 }, .{ .code = 25, .codeLength = 14 }, .{ .code = 20, .codeLength = 14 }, .{ .code = 29, .codeLength = 15 }, .{ .code = 11, .codeLength = 14 }, .{ .code = 17, .codeLength = 15 }, .{ .code = 12, .codeLength = 15 }, .{ .code = 16, .codeLength = 16 }, .{ .code = 8, .codeLength = 16 }, .{ .code = 1, .codeLength = 19 }, .{ .code = 1, .codeLength = 18 }, .{ .code = 0, .codeLength = 19 }, .{ .code = 1, .codeLength = 16 } };
pub const table13 = [_][]const HuffCell{
    table13_row_0[0..],
    table13_row_1[0..],
    table13_row_2[0..],
    table13_row_3[0..],
    table13_row_4[0..],
    table13_row_5[0..],
    table13_row_6[0..],
    table13_row_7[0..],
    table13_row_8[0..],
    table13_row_9[0..],
    table13_row_10[0..],
    table13_row_11[0..],
    table13_row_12[0..],
    table13_row_13[0..],
    table13_row_14[0..],
    table13_row_15[0..],
};

const table15_row_0 = [_]HuffCell{ .{ .code = 7, .codeLength = 3 }, .{ .code = 12, .codeLength = 4 }, .{ .code = 18, .codeLength = 5 }, .{ .code = 53, .codeLength = 7 }, .{ .code = 47, .codeLength = 7 }, .{ .code = 76, .codeLength = 8 }, .{ .code = 124, .codeLength = 9 }, .{ .code = 108, .codeLength = 9 }, .{ .code = 89, .codeLength = 9 }, .{ .code = 123, .codeLength = 10 }, .{ .code = 108, .codeLength = 10 }, .{ .code = 119, .codeLength = 11 }, .{ .code = 107, .codeLength = 11 }, .{ .code = 81, .codeLength = 11 }, .{ .code = 122, .codeLength = 12 }, .{ .code = 63, .codeLength = 13 } };
const table15_row_1 = [_]HuffCell{ .{ .code = 13, .codeLength = 4 }, .{ .code = 5, .codeLength = 3 }, .{ .code = 16, .codeLength = 5 }, .{ .code = 27, .codeLength = 6 }, .{ .code = 46, .codeLength = 7 }, .{ .code = 36, .codeLength = 7 }, .{ .code = 61, .codeLength = 8 }, .{ .code = 51, .codeLength = 8 }, .{ .code = 42, .codeLength = 8 }, .{ .code = 70, .codeLength = 9 }, .{ .code = 52, .codeLength = 9 }, .{ .code = 83, .codeLength = 10 }, .{ .code = 65, .codeLength = 10 }, .{ .code = 41, .codeLength = 10 }, .{ .code = 59, .codeLength = 11 }, .{ .code = 36, .codeLength = 11 } };
const table15_row_2 = [_]HuffCell{ .{ .code = 19, .codeLength = 5 }, .{ .code = 17, .codeLength = 5 }, .{ .code = 15, .codeLength = 5 }, .{ .code = 24, .codeLength = 6 }, .{ .code = 41, .codeLength = 7 }, .{ .code = 34, .codeLength = 7 }, .{ .code = 59, .codeLength = 8 }, .{ .code = 48, .codeLength = 8 }, .{ .code = 40, .codeLength = 8 }, .{ .code = 64, .codeLength = 9 }, .{ .code = 50, .codeLength = 9 }, .{ .code = 78, .codeLength = 10 }, .{ .code = 62, .codeLength = 10 }, .{ .code = 80, .codeLength = 11 }, .{ .code = 56, .codeLength = 11 }, .{ .code = 33, .codeLength = 11 } };
const table15_row_3 = [_]HuffCell{ .{ .code = 29, .codeLength = 6 }, .{ .code = 28, .codeLength = 6 }, .{ .code = 25, .codeLength = 6 }, .{ .code = 43, .codeLength = 7 }, .{ .code = 39, .codeLength = 7 }, .{ .code = 63, .codeLength = 8 }, .{ .code = 55, .codeLength = 8 }, .{ .code = 93, .codeLength = 9 }, .{ .code = 76, .codeLength = 9 }, .{ .code = 59, .codeLength = 9 }, .{ .code = 93, .codeLength = 10 }, .{ .code = 72, .codeLength = 10 }, .{ .code = 54, .codeLength = 10 }, .{ .code = 75, .codeLength = 11 }, .{ .code = 50, .codeLength = 11 }, .{ .code = 29, .codeLength = 11 } };
const table15_row_4 = [_]HuffCell{ .{ .code = 52, .codeLength = 7 }, .{ .code = 22, .codeLength = 6 }, .{ .code = 42, .codeLength = 7 }, .{ .code = 40, .codeLength = 7 }, .{ .code = 67, .codeLength = 8 }, .{ .code = 57, .codeLength = 8 }, .{ .code = 95, .codeLength = 9 }, .{ .code = 79, .codeLength = 9 }, .{ .code = 72, .codeLength = 9 }, .{ .code = 57, .codeLength = 9 }, .{ .code = 89, .codeLength = 10 }, .{ .code = 69, .codeLength = 10 }, .{ .code = 49, .codeLength = 10 }, .{ .code = 66, .codeLength = 11 }, .{ .code = 46, .codeLength = 11 }, .{ .code = 27, .codeLength = 11 } };
const table15_row_5 = [_]HuffCell{ .{ .code = 77, .codeLength = 8 }, .{ .code = 37, .codeLength = 7 }, .{ .code = 35, .codeLength = 7 }, .{ .code = 66, .codeLength = 8 }, .{ .code = 58, .codeLength = 8 }, .{ .code = 52, .codeLength = 8 }, .{ .code = 91, .codeLength = 9 }, .{ .code = 74, .codeLength = 9 }, .{ .code = 62, .codeLength = 9 }, .{ .code = 48, .codeLength = 9 }, .{ .code = 79, .codeLength = 10 }, .{ .code = 63, .codeLength = 10 }, .{ .code = 90, .codeLength = 11 }, .{ .code = 62, .codeLength = 11 }, .{ .code = 40, .codeLength = 11 }, .{ .code = 38, .codeLength = 12 } };
const table15_row_6 = [_]HuffCell{ .{ .code = 125, .codeLength = 9 }, .{ .code = 32, .codeLength = 7 }, .{ .code = 60, .codeLength = 8 }, .{ .code = 56, .codeLength = 8 }, .{ .code = 50, .codeLength = 8 }, .{ .code = 92, .codeLength = 9 }, .{ .code = 78, .codeLength = 9 }, .{ .code = 65, .codeLength = 9 }, .{ .code = 55, .codeLength = 9 }, .{ .code = 87, .codeLength = 10 }, .{ .code = 71, .codeLength = 10 }, .{ .code = 51, .codeLength = 10 }, .{ .code = 73, .codeLength = 11 }, .{ .code = 51, .codeLength = 11 }, .{ .code = 70, .codeLength = 12 }, .{ .code = 30, .codeLength = 12 } };
const table15_row_7 = [_]HuffCell{ .{ .code = 109, .codeLength = 9 }, .{ .code = 53, .codeLength = 8 }, .{ .code = 49, .codeLength = 8 }, .{ .code = 94, .codeLength = 9 }, .{ .code = 88, .codeLength = 9 }, .{ .code = 75, .codeLength = 9 }, .{ .code = 66, .codeLength = 9 }, .{ .code = 122, .codeLength = 10 }, .{ .code = 91, .codeLength = 10 }, .{ .code = 73, .codeLength = 10 }, .{ .code = 56, .codeLength = 10 }, .{ .code = 42, .codeLength = 10 }, .{ .code = 64, .codeLength = 11 }, .{ .code = 44, .codeLength = 11 }, .{ .code = 21, .codeLength = 11 }, .{ .code = 25, .codeLength = 12 } };
const table15_row_8 = [_]HuffCell{ .{ .code = 90, .codeLength = 9 }, .{ .code = 43, .codeLength = 8 }, .{ .code = 41, .codeLength = 8 }, .{ .code = 77, .codeLength = 9 }, .{ .code = 73, .codeLength = 9 }, .{ .code = 63, .codeLength = 9 }, .{ .code = 56, .codeLength = 9 }, .{ .code = 92, .codeLength = 10 }, .{ .code = 77, .codeLength = 10 }, .{ .code = 66, .codeLength = 10 }, .{ .code = 47, .codeLength = 10 }, .{ .code = 67, .codeLength = 11 }, .{ .code = 48, .codeLength = 11 }, .{ .code = 53, .codeLength = 12 }, .{ .code = 36, .codeLength = 12 }, .{ .code = 20, .codeLength = 12 } };
const table15_row_9 = [_]HuffCell{ .{ .code = 71, .codeLength = 9 }, .{ .code = 34, .codeLength = 8 }, .{ .code = 67, .codeLength = 9 }, .{ .code = 60, .codeLength = 9 }, .{ .code = 58, .codeLength = 9 }, .{ .code = 49, .codeLength = 9 }, .{ .code = 88, .codeLength = 10 }, .{ .code = 76, .codeLength = 10 }, .{ .code = 67, .codeLength = 10 }, .{ .code = 106, .codeLength = 11 }, .{ .code = 71, .codeLength = 11 }, .{ .code = 54, .codeLength = 11 }, .{ .code = 38, .codeLength = 11 }, .{ .code = 39, .codeLength = 12 }, .{ .code = 23, .codeLength = 12 }, .{ .code = 15, .codeLength = 12 } };
const table15_row_10 = [_]HuffCell{ .{ .code = 109, .codeLength = 10 }, .{ .code = 53, .codeLength = 9 }, .{ .code = 51, .codeLength = 9 }, .{ .code = 47, .codeLength = 9 }, .{ .code = 90, .codeLength = 10 }, .{ .code = 82, .codeLength = 10 }, .{ .code = 58, .codeLength = 10 }, .{ .code = 57, .codeLength = 10 }, .{ .code = 48, .codeLength = 10 }, .{ .code = 72, .codeLength = 11 }, .{ .code = 57, .codeLength = 11 }, .{ .code = 41, .codeLength = 11 }, .{ .code = 23, .codeLength = 11 }, .{ .code = 27, .codeLength = 12 }, .{ .code = 62, .codeLength = 13 }, .{ .code = 9, .codeLength = 12 } };
const table15_row_11 = [_]HuffCell{ .{ .code = 86, .codeLength = 10 }, .{ .code = 42, .codeLength = 9 }, .{ .code = 40, .codeLength = 9 }, .{ .code = 37, .codeLength = 9 }, .{ .code = 70, .codeLength = 10 }, .{ .code = 64, .codeLength = 10 }, .{ .code = 52, .codeLength = 10 }, .{ .code = 43, .codeLength = 10 }, .{ .code = 70, .codeLength = 11 }, .{ .code = 55, .codeLength = 11 }, .{ .code = 42, .codeLength = 11 }, .{ .code = 25, .codeLength = 11 }, .{ .code = 29, .codeLength = 12 }, .{ .code = 18, .codeLength = 12 }, .{ .code = 11, .codeLength = 12 }, .{ .code = 11, .codeLength = 13 } };
const table15_row_12 = [_]HuffCell{ .{ .code = 118, .codeLength = 11 }, .{ .code = 68, .codeLength = 10 }, .{ .code = 30, .codeLength = 9 }, .{ .code = 55, .codeLength = 10 }, .{ .code = 50, .codeLength = 10 }, .{ .code = 46, .codeLength = 10 }, .{ .code = 74, .codeLength = 11 }, .{ .code = 65, .codeLength = 11 }, .{ .code = 49, .codeLength = 11 }, .{ .code = 39, .codeLength = 11 }, .{ .code = 24, .codeLength = 11 }, .{ .code = 16, .codeLength = 11 }, .{ .code = 22, .codeLength = 12 }, .{ .code = 13, .codeLength = 12 }, .{ .code = 14, .codeLength = 13 }, .{ .code = 7, .codeLength = 13 } };
const table15_row_13 = [_]HuffCell{ .{ .code = 91, .codeLength = 11 }, .{ .code = 44, .codeLength = 10 }, .{ .code = 39, .codeLength = 10 }, .{ .code = 38, .codeLength = 10 }, .{ .code = 34, .codeLength = 10 }, .{ .code = 63, .codeLength = 11 }, .{ .code = 52, .codeLength = 11 }, .{ .code = 45, .codeLength = 11 }, .{ .code = 31, .codeLength = 11 }, .{ .code = 52, .codeLength = 12 }, .{ .code = 28, .codeLength = 12 }, .{ .code = 19, .codeLength = 12 }, .{ .code = 14, .codeLength = 12 }, .{ .code = 8, .codeLength = 12 }, .{ .code = 9, .codeLength = 13 }, .{ .code = 3, .codeLength = 13 } };
const table15_row_14 = [_]HuffCell{ .{ .code = 123, .codeLength = 12 }, .{ .code = 60, .codeLength = 11 }, .{ .code = 58, .codeLength = 11 }, .{ .code = 53, .codeLength = 11 }, .{ .code = 47, .codeLength = 11 }, .{ .code = 43, .codeLength = 11 }, .{ .code = 32, .codeLength = 11 }, .{ .code = 22, .codeLength = 11 }, .{ .code = 37, .codeLength = 12 }, .{ .code = 24, .codeLength = 12 }, .{ .code = 17, .codeLength = 12 }, .{ .code = 12, .codeLength = 12 }, .{ .code = 15, .codeLength = 13 }, .{ .code = 10, .codeLength = 13 }, .{ .code = 2, .codeLength = 12 }, .{ .code = 1, .codeLength = 13 } };
const table15_row_15 = [_]HuffCell{ .{ .code = 71, .codeLength = 12 }, .{ .code = 37, .codeLength = 11 }, .{ .code = 34, .codeLength = 11 }, .{ .code = 30, .codeLength = 11 }, .{ .code = 28, .codeLength = 11 }, .{ .code = 20, .codeLength = 11 }, .{ .code = 17, .codeLength = 11 }, .{ .code = 26, .codeLength = 12 }, .{ .code = 21, .codeLength = 12 }, .{ .code = 16, .codeLength = 12 }, .{ .code = 10, .codeLength = 12 }, .{ .code = 6, .codeLength = 12 }, .{ .code = 8, .codeLength = 13 }, .{ .code = 6, .codeLength = 13 }, .{ .code = 2, .codeLength = 13 }, .{ .code = 0, .codeLength = 13 } };
pub const table15 = [_][]const HuffCell{
    table15_row_0[0..],
    table15_row_1[0..],
    table15_row_2[0..],
    table15_row_3[0..],
    table15_row_4[0..],
    table15_row_5[0..],
    table15_row_6[0..],
    table15_row_7[0..],
    table15_row_8[0..],
    table15_row_9[0..],
    table15_row_10[0..],
    table15_row_11[0..],
    table15_row_12[0..],
    table15_row_13[0..],
    table15_row_14[0..],
    table15_row_15[0..],
};

const table16_row_0 = [_]HuffCell{ .{ .code = 1, .codeLength = 1 }, .{ .code = 5, .codeLength = 4 }, .{ .code = 14, .codeLength = 6 }, .{ .code = 44, .codeLength = 8 }, .{ .code = 74, .codeLength = 9 }, .{ .code = 63, .codeLength = 9 }, .{ .code = 110, .codeLength = 10 }, .{ .code = 93, .codeLength = 10 }, .{ .code = 172, .codeLength = 11 }, .{ .code = 149, .codeLength = 11 }, .{ .code = 138, .codeLength = 11 }, .{ .code = 242, .codeLength = 12 }, .{ .code = 225, .codeLength = 12 }, .{ .code = 195, .codeLength = 12 }, .{ .code = 376, .codeLength = 13 }, .{ .code = 17, .codeLength = 9 } };
const table16_row_1 = [_]HuffCell{ .{ .code = 3, .codeLength = 3 }, .{ .code = 4, .codeLength = 4 }, .{ .code = 12, .codeLength = 6 }, .{ .code = 20, .codeLength = 7 }, .{ .code = 35, .codeLength = 8 }, .{ .code = 62, .codeLength = 9 }, .{ .code = 53, .codeLength = 9 }, .{ .code = 47, .codeLength = 9 }, .{ .code = 83, .codeLength = 10 }, .{ .code = 75, .codeLength = 10 }, .{ .code = 68, .codeLength = 10 }, .{ .code = 119, .codeLength = 11 }, .{ .code = 201, .codeLength = 12 }, .{ .code = 107, .codeLength = 11 }, .{ .code = 207, .codeLength = 12 }, .{ .code = 9, .codeLength = 8 } };
const table16_row_2 = [_]HuffCell{ .{ .code = 15, .codeLength = 6 }, .{ .code = 13, .codeLength = 6 }, .{ .code = 23, .codeLength = 7 }, .{ .code = 38, .codeLength = 8 }, .{ .code = 67, .codeLength = 9 }, .{ .code = 58, .codeLength = 9 }, .{ .code = 103, .codeLength = 10 }, .{ .code = 90, .codeLength = 10 }, .{ .code = 161, .codeLength = 11 }, .{ .code = 72, .codeLength = 10 }, .{ .code = 127, .codeLength = 11 }, .{ .code = 117, .codeLength = 11 }, .{ .code = 110, .codeLength = 11 }, .{ .code = 209, .codeLength = 12 }, .{ .code = 206, .codeLength = 12 }, .{ .code = 16, .codeLength = 9 } };
const table16_row_3 = [_]HuffCell{ .{ .code = 45, .codeLength = 8 }, .{ .code = 21, .codeLength = 7 }, .{ .code = 39, .codeLength = 8 }, .{ .code = 69, .codeLength = 9 }, .{ .code = 64, .codeLength = 9 }, .{ .code = 114, .codeLength = 10 }, .{ .code = 99, .codeLength = 10 }, .{ .code = 87, .codeLength = 10 }, .{ .code = 158, .codeLength = 11 }, .{ .code = 140, .codeLength = 11 }, .{ .code = 252, .codeLength = 12 }, .{ .code = 212, .codeLength = 12 }, .{ .code = 199, .codeLength = 12 }, .{ .code = 387, .codeLength = 13 }, .{ .code = 365, .codeLength = 13 }, .{ .code = 26, .codeLength = 10 } };
const table16_row_4 = [_]HuffCell{ .{ .code = 75, .codeLength = 9 }, .{ .code = 36, .codeLength = 8 }, .{ .code = 68, .codeLength = 9 }, .{ .code = 65, .codeLength = 9 }, .{ .code = 115, .codeLength = 10 }, .{ .code = 101, .codeLength = 10 }, .{ .code = 179, .codeLength = 11 }, .{ .code = 164, .codeLength = 11 }, .{ .code = 155, .codeLength = 11 }, .{ .code = 264, .codeLength = 12 }, .{ .code = 246, .codeLength = 12 }, .{ .code = 226, .codeLength = 12 }, .{ .code = 395, .codeLength = 13 }, .{ .code = 382, .codeLength = 13 }, .{ .code = 362, .codeLength = 13 }, .{ .code = 9, .codeLength = 9 } };
const table16_row_5 = [_]HuffCell{ .{ .code = 66, .codeLength = 9 }, .{ .code = 30, .codeLength = 8 }, .{ .code = 59, .codeLength = 9 }, .{ .code = 56, .codeLength = 9 }, .{ .code = 102, .codeLength = 10 }, .{ .code = 185, .codeLength = 11 }, .{ .code = 173, .codeLength = 11 }, .{ .code = 265, .codeLength = 12 }, .{ .code = 142, .codeLength = 11 }, .{ .code = 253, .codeLength = 12 }, .{ .code = 232, .codeLength = 12 }, .{ .code = 400, .codeLength = 13 }, .{ .code = 388, .codeLength = 13 }, .{ .code = 378, .codeLength = 13 }, .{ .code = 445, .codeLength = 14 }, .{ .code = 16, .codeLength = 10 } };
const table16_row_6 = [_]HuffCell{ .{ .code = 111, .codeLength = 10 }, .{ .code = 54, .codeLength = 9 }, .{ .code = 52, .codeLength = 9 }, .{ .code = 100, .codeLength = 10 }, .{ .code = 184, .codeLength = 11 }, .{ .code = 178, .codeLength = 11 }, .{ .code = 160, .codeLength = 11 }, .{ .code = 133, .codeLength = 11 }, .{ .code = 257, .codeLength = 12 }, .{ .code = 244, .codeLength = 12 }, .{ .code = 228, .codeLength = 12 }, .{ .code = 217, .codeLength = 12 }, .{ .code = 385, .codeLength = 13 }, .{ .code = 366, .codeLength = 13 }, .{ .code = 715, .codeLength = 14 }, .{ .code = 10, .codeLength = 10 } };
const table16_row_7 = [_]HuffCell{ .{ .code = 98, .codeLength = 10 }, .{ .code = 48, .codeLength = 9 }, .{ .code = 91, .codeLength = 10 }, .{ .code = 88, .codeLength = 10 }, .{ .code = 165, .codeLength = 11 }, .{ .code = 157, .codeLength = 11 }, .{ .code = 148, .codeLength = 11 }, .{ .code = 261, .codeLength = 12 }, .{ .code = 248, .codeLength = 12 }, .{ .code = 407, .codeLength = 13 }, .{ .code = 397, .codeLength = 13 }, .{ .code = 372, .codeLength = 13 }, .{ .code = 380, .codeLength = 13 }, .{ .code = 889, .codeLength = 15 }, .{ .code = 884, .codeLength = 15 }, .{ .code = 8, .codeLength = 10 } };
const table16_row_8 = [_]HuffCell{ .{ .code = 85, .codeLength = 10 }, .{ .code = 84, .codeLength = 10 }, .{ .code = 81, .codeLength = 10 }, .{ .code = 159, .codeLength = 11 }, .{ .code = 156, .codeLength = 11 }, .{ .code = 143, .codeLength = 11 }, .{ .code = 260, .codeLength = 12 }, .{ .code = 249, .codeLength = 12 }, .{ .code = 427, .codeLength = 13 }, .{ .code = 401, .codeLength = 13 }, .{ .code = 392, .codeLength = 13 }, .{ .code = 383, .codeLength = 13 }, .{ .code = 727, .codeLength = 14 }, .{ .code = 713, .codeLength = 14 }, .{ .code = 708, .codeLength = 14 }, .{ .code = 7, .codeLength = 10 } };
const table16_row_9 = [_]HuffCell{ .{ .code = 154, .codeLength = 11 }, .{ .code = 76, .codeLength = 10 }, .{ .code = 73, .codeLength = 10 }, .{ .code = 141, .codeLength = 11 }, .{ .code = 131, .codeLength = 11 }, .{ .code = 256, .codeLength = 12 }, .{ .code = 245, .codeLength = 12 }, .{ .code = 426, .codeLength = 13 }, .{ .code = 406, .codeLength = 13 }, .{ .code = 394, .codeLength = 13 }, .{ .code = 384, .codeLength = 13 }, .{ .code = 735, .codeLength = 14 }, .{ .code = 359, .codeLength = 13 }, .{ .code = 710, .codeLength = 14 }, .{ .code = 352, .codeLength = 13 }, .{ .code = 11, .codeLength = 11 } };
const table16_row_10 = [_]HuffCell{ .{ .code = 139, .codeLength = 11 }, .{ .code = 129, .codeLength = 11 }, .{ .code = 67, .codeLength = 10 }, .{ .code = 125, .codeLength = 11 }, .{ .code = 247, .codeLength = 12 }, .{ .code = 233, .codeLength = 12 }, .{ .code = 229, .codeLength = 12 }, .{ .code = 219, .codeLength = 12 }, .{ .code = 393, .codeLength = 13 }, .{ .code = 743, .codeLength = 14 }, .{ .code = 737, .codeLength = 14 }, .{ .code = 720, .codeLength = 14 }, .{ .code = 885, .codeLength = 15 }, .{ .code = 882, .codeLength = 15 }, .{ .code = 439, .codeLength = 14 }, .{ .code = 4, .codeLength = 10 } };
const table16_row_11 = [_]HuffCell{ .{ .code = 243, .codeLength = 12 }, .{ .code = 120, .codeLength = 11 }, .{ .code = 118, .codeLength = 11 }, .{ .code = 115, .codeLength = 11 }, .{ .code = 227, .codeLength = 12 }, .{ .code = 223, .codeLength = 12 }, .{ .code = 396, .codeLength = 13 }, .{ .code = 746, .codeLength = 14 }, .{ .code = 742, .codeLength = 14 }, .{ .code = 736, .codeLength = 14 }, .{ .code = 721, .codeLength = 14 }, .{ .code = 712, .codeLength = 14 }, .{ .code = 706, .codeLength = 14 }, .{ .code = 223, .codeLength = 13 }, .{ .code = 436, .codeLength = 14 }, .{ .code = 6, .codeLength = 11 } };
const table16_row_12 = [_]HuffCell{ .{ .code = 202, .codeLength = 12 }, .{ .code = 224, .codeLength = 12 }, .{ .code = 222, .codeLength = 12 }, .{ .code = 218, .codeLength = 12 }, .{ .code = 216, .codeLength = 12 }, .{ .code = 389, .codeLength = 13 }, .{ .code = 386, .codeLength = 13 }, .{ .code = 381, .codeLength = 13 }, .{ .code = 364, .codeLength = 13 }, .{ .code = 888, .codeLength = 15 }, .{ .code = 443, .codeLength = 14 }, .{ .code = 707, .codeLength = 14 }, .{ .code = 440, .codeLength = 14 }, .{ .code = 437, .codeLength = 14 }, .{ .code = 1728, .codeLength = 16 }, .{ .code = 4, .codeLength = 11 } };
const table16_row_13 = [_]HuffCell{ .{ .code = 747, .codeLength = 14 }, .{ .code = 211, .codeLength = 12 }, .{ .code = 210, .codeLength = 12 }, .{ .code = 208, .codeLength = 12 }, .{ .code = 370, .codeLength = 13 }, .{ .code = 379, .codeLength = 13 }, .{ .code = 734, .codeLength = 14 }, .{ .code = 723, .codeLength = 14 }, .{ .code = 714, .codeLength = 14 }, .{ .code = 1735, .codeLength = 16 }, .{ .code = 883, .codeLength = 15 }, .{ .code = 877, .codeLength = 15 }, .{ .code = 876, .codeLength = 15 }, .{ .code = 3459, .codeLength = 17 }, .{ .code = 865, .codeLength = 15 }, .{ .code = 2, .codeLength = 11 } };
const table16_row_14 = [_]HuffCell{ .{ .code = 377, .codeLength = 13 }, .{ .code = 369, .codeLength = 13 }, .{ .code = 102, .codeLength = 11 }, .{ .code = 187, .codeLength = 12 }, .{ .code = 726, .codeLength = 14 }, .{ .code = 722, .codeLength = 14 }, .{ .code = 358, .codeLength = 13 }, .{ .code = 711, .codeLength = 14 }, .{ .code = 709, .codeLength = 14 }, .{ .code = 866, .codeLength = 15 }, .{ .code = 1734, .codeLength = 16 }, .{ .code = 871, .codeLength = 15 }, .{ .code = 3458, .codeLength = 17 }, .{ .code = 870, .codeLength = 15 }, .{ .code = 434, .codeLength = 14 }, .{ .code = 0, .codeLength = 11 } };
const table16_row_15 = [_]HuffCell{ .{ .code = 12, .codeLength = 9 }, .{ .code = 10, .codeLength = 8 }, .{ .code = 7, .codeLength = 8 }, .{ .code = 11, .codeLength = 9 }, .{ .code = 10, .codeLength = 9 }, .{ .code = 17, .codeLength = 10 }, .{ .code = 11, .codeLength = 10 }, .{ .code = 9, .codeLength = 10 }, .{ .code = 13, .codeLength = 11 }, .{ .code = 12, .codeLength = 11 }, .{ .code = 10, .codeLength = 11 }, .{ .code = 7, .codeLength = 11 }, .{ .code = 5, .codeLength = 11 }, .{ .code = 3, .codeLength = 11 }, .{ .code = 1, .codeLength = 11 }, .{ .code = 3, .codeLength = 8 } };
pub const table16 = [_][]const HuffCell{
    table16_row_0[0..],
    table16_row_1[0..],
    table16_row_2[0..],
    table16_row_3[0..],
    table16_row_4[0..],
    table16_row_5[0..],
    table16_row_6[0..],
    table16_row_7[0..],
    table16_row_8[0..],
    table16_row_9[0..],
    table16_row_10[0..],
    table16_row_11[0..],
    table16_row_12[0..],
    table16_row_13[0..],
    table16_row_14[0..],
    table16_row_15[0..],
};

const table24_row_0 = [_]HuffCell{ .{ .code = 15, .codeLength = 4 }, .{ .code = 13, .codeLength = 4 }, .{ .code = 46, .codeLength = 6 }, .{ .code = 80, .codeLength = 7 }, .{ .code = 146, .codeLength = 8 }, .{ .code = 262, .codeLength = 9 }, .{ .code = 248, .codeLength = 9 }, .{ .code = 434, .codeLength = 10 }, .{ .code = 426, .codeLength = 10 }, .{ .code = 669, .codeLength = 11 }, .{ .code = 653, .codeLength = 11 }, .{ .code = 649, .codeLength = 11 }, .{ .code = 621, .codeLength = 11 }, .{ .code = 517, .codeLength = 11 }, .{ .code = 1032, .codeLength = 12 }, .{ .code = 88, .codeLength = 9 } };
const table24_row_1 = [_]HuffCell{ .{ .code = 14, .codeLength = 4 }, .{ .code = 12, .codeLength = 4 }, .{ .code = 21, .codeLength = 5 }, .{ .code = 38, .codeLength = 6 }, .{ .code = 71, .codeLength = 7 }, .{ .code = 130, .codeLength = 8 }, .{ .code = 122, .codeLength = 8 }, .{ .code = 216, .codeLength = 9 }, .{ .code = 209, .codeLength = 9 }, .{ .code = 198, .codeLength = 9 }, .{ .code = 327, .codeLength = 10 }, .{ .code = 345, .codeLength = 10 }, .{ .code = 319, .codeLength = 10 }, .{ .code = 297, .codeLength = 10 }, .{ .code = 279, .codeLength = 10 }, .{ .code = 42, .codeLength = 8 } };
const table24_row_2 = [_]HuffCell{ .{ .code = 47, .codeLength = 6 }, .{ .code = 22, .codeLength = 5 }, .{ .code = 41, .codeLength = 6 }, .{ .code = 74, .codeLength = 7 }, .{ .code = 68, .codeLength = 7 }, .{ .code = 128, .codeLength = 8 }, .{ .code = 120, .codeLength = 8 }, .{ .code = 221, .codeLength = 9 }, .{ .code = 207, .codeLength = 9 }, .{ .code = 194, .codeLength = 9 }, .{ .code = 182, .codeLength = 9 }, .{ .code = 340, .codeLength = 10 }, .{ .code = 315, .codeLength = 10 }, .{ .code = 295, .codeLength = 10 }, .{ .code = 541, .codeLength = 11 }, .{ .code = 18, .codeLength = 7 } };
const table24_row_3 = [_]HuffCell{ .{ .code = 81, .codeLength = 7 }, .{ .code = 39, .codeLength = 6 }, .{ .code = 75, .codeLength = 7 }, .{ .code = 70, .codeLength = 7 }, .{ .code = 134, .codeLength = 8 }, .{ .code = 125, .codeLength = 8 }, .{ .code = 116, .codeLength = 8 }, .{ .code = 220, .codeLength = 9 }, .{ .code = 204, .codeLength = 9 }, .{ .code = 190, .codeLength = 9 }, .{ .code = 178, .codeLength = 9 }, .{ .code = 325, .codeLength = 10 }, .{ .code = 311, .codeLength = 10 }, .{ .code = 293, .codeLength = 10 }, .{ .code = 271, .codeLength = 10 }, .{ .code = 16, .codeLength = 7 } };
const table24_row_4 = [_]HuffCell{ .{ .code = 147, .codeLength = 8 }, .{ .code = 72, .codeLength = 7 }, .{ .code = 69, .codeLength = 7 }, .{ .code = 135, .codeLength = 8 }, .{ .code = 127, .codeLength = 8 }, .{ .code = 118, .codeLength = 8 }, .{ .code = 112, .codeLength = 8 }, .{ .code = 210, .codeLength = 9 }, .{ .code = 200, .codeLength = 9 }, .{ .code = 188, .codeLength = 9 }, .{ .code = 352, .codeLength = 10 }, .{ .code = 323, .codeLength = 10 }, .{ .code = 306, .codeLength = 10 }, .{ .code = 285, .codeLength = 10 }, .{ .code = 540, .codeLength = 11 }, .{ .code = 14, .codeLength = 7 } };
const table24_row_5 = [_]HuffCell{ .{ .code = 263, .codeLength = 9 }, .{ .code = 66, .codeLength = 7 }, .{ .code = 129, .codeLength = 8 }, .{ .code = 126, .codeLength = 8 }, .{ .code = 119, .codeLength = 8 }, .{ .code = 114, .codeLength = 8 }, .{ .code = 214, .codeLength = 9 }, .{ .code = 202, .codeLength = 9 }, .{ .code = 192, .codeLength = 9 }, .{ .code = 180, .codeLength = 9 }, .{ .code = 341, .codeLength = 10 }, .{ .code = 317, .codeLength = 10 }, .{ .code = 301, .codeLength = 10 }, .{ .code = 281, .codeLength = 10 }, .{ .code = 262, .codeLength = 10 }, .{ .code = 12, .codeLength = 7 } };
const table24_row_6 = [_]HuffCell{ .{ .code = 249, .codeLength = 9 }, .{ .code = 123, .codeLength = 8 }, .{ .code = 121, .codeLength = 8 }, .{ .code = 117, .codeLength = 8 }, .{ .code = 113, .codeLength = 8 }, .{ .code = 215, .codeLength = 9 }, .{ .code = 206, .codeLength = 9 }, .{ .code = 195, .codeLength = 9 }, .{ .code = 185, .codeLength = 9 }, .{ .code = 347, .codeLength = 10 }, .{ .code = 330, .codeLength = 10 }, .{ .code = 308, .codeLength = 10 }, .{ .code = 291, .codeLength = 10 }, .{ .code = 272, .codeLength = 10 }, .{ .code = 520, .codeLength = 11 }, .{ .code = 10, .codeLength = 7 } };
const table24_row_7 = [_]HuffCell{ .{ .code = 435, .codeLength = 10 }, .{ .code = 115, .codeLength = 8 }, .{ .code = 111, .codeLength = 8 }, .{ .code = 109, .codeLength = 8 }, .{ .code = 211, .codeLength = 9 }, .{ .code = 203, .codeLength = 9 }, .{ .code = 196, .codeLength = 9 }, .{ .code = 187, .codeLength = 9 }, .{ .code = 353, .codeLength = 10 }, .{ .code = 332, .codeLength = 10 }, .{ .code = 313, .codeLength = 10 }, .{ .code = 298, .codeLength = 10 }, .{ .code = 283, .codeLength = 10 }, .{ .code = 531, .codeLength = 11 }, .{ .code = 381, .codeLength = 11 }, .{ .code = 17, .codeLength = 8 } };
const table24_row_8 = [_]HuffCell{ .{ .code = 427, .codeLength = 10 }, .{ .code = 212, .codeLength = 9 }, .{ .code = 208, .codeLength = 9 }, .{ .code = 205, .codeLength = 9 }, .{ .code = 201, .codeLength = 9 }, .{ .code = 193, .codeLength = 9 }, .{ .code = 186, .codeLength = 9 }, .{ .code = 177, .codeLength = 9 }, .{ .code = 169, .codeLength = 9 }, .{ .code = 320, .codeLength = 10 }, .{ .code = 303, .codeLength = 10 }, .{ .code = 286, .codeLength = 10 }, .{ .code = 268, .codeLength = 10 }, .{ .code = 514, .codeLength = 11 }, .{ .code = 377, .codeLength = 11 }, .{ .code = 16, .codeLength = 8 } };
const table24_row_9 = [_]HuffCell{ .{ .code = 335, .codeLength = 10 }, .{ .code = 199, .codeLength = 9 }, .{ .code = 197, .codeLength = 9 }, .{ .code = 191, .codeLength = 9 }, .{ .code = 189, .codeLength = 9 }, .{ .code = 181, .codeLength = 9 }, .{ .code = 174, .codeLength = 9 }, .{ .code = 333, .codeLength = 10 }, .{ .code = 321, .codeLength = 10 }, .{ .code = 305, .codeLength = 10 }, .{ .code = 289, .codeLength = 10 }, .{ .code = 275, .codeLength = 10 }, .{ .code = 521, .codeLength = 11 }, .{ .code = 379, .codeLength = 11 }, .{ .code = 371, .codeLength = 11 }, .{ .code = 11, .codeLength = 8 } };
const table24_row_10 = [_]HuffCell{ .{ .code = 668, .codeLength = 11 }, .{ .code = 184, .codeLength = 9 }, .{ .code = 183, .codeLength = 9 }, .{ .code = 179, .codeLength = 9 }, .{ .code = 175, .codeLength = 9 }, .{ .code = 344, .codeLength = 10 }, .{ .code = 331, .codeLength = 10 }, .{ .code = 314, .codeLength = 10 }, .{ .code = 304, .codeLength = 10 }, .{ .code = 290, .codeLength = 10 }, .{ .code = 277, .codeLength = 10 }, .{ .code = 530, .codeLength = 11 }, .{ .code = 383, .codeLength = 11 }, .{ .code = 373, .codeLength = 11 }, .{ .code = 366, .codeLength = 11 }, .{ .code = 10, .codeLength = 8 } };
const table24_row_11 = [_]HuffCell{ .{ .code = 652, .codeLength = 11 }, .{ .code = 346, .codeLength = 10 }, .{ .code = 171, .codeLength = 9 }, .{ .code = 168, .codeLength = 9 }, .{ .code = 164, .codeLength = 9 }, .{ .code = 318, .codeLength = 10 }, .{ .code = 309, .codeLength = 10 }, .{ .code = 299, .codeLength = 10 }, .{ .code = 287, .codeLength = 10 }, .{ .code = 276, .codeLength = 10 }, .{ .code = 263, .codeLength = 10 }, .{ .code = 513, .codeLength = 11 }, .{ .code = 375, .codeLength = 11 }, .{ .code = 368, .codeLength = 11 }, .{ .code = 362, .codeLength = 11 }, .{ .code = 6, .codeLength = 8 } };
const table24_row_12 = [_]HuffCell{ .{ .code = 648, .codeLength = 11 }, .{ .code = 322, .codeLength = 10 }, .{ .code = 316, .codeLength = 10 }, .{ .code = 312, .codeLength = 10 }, .{ .code = 307, .codeLength = 10 }, .{ .code = 302, .codeLength = 10 }, .{ .code = 292, .codeLength = 10 }, .{ .code = 284, .codeLength = 10 }, .{ .code = 269, .codeLength = 10 }, .{ .code = 261, .codeLength = 10 }, .{ .code = 512, .codeLength = 11 }, .{ .code = 376, .codeLength = 11 }, .{ .code = 370, .codeLength = 11 }, .{ .code = 364, .codeLength = 11 }, .{ .code = 359, .codeLength = 11 }, .{ .code = 4, .codeLength = 8 } };
const table24_row_13 = [_]HuffCell{ .{ .code = 620, .codeLength = 11 }, .{ .code = 300, .codeLength = 10 }, .{ .code = 296, .codeLength = 10 }, .{ .code = 294, .codeLength = 10 }, .{ .code = 288, .codeLength = 10 }, .{ .code = 282, .codeLength = 10 }, .{ .code = 273, .codeLength = 10 }, .{ .code = 266, .codeLength = 10 }, .{ .code = 515, .codeLength = 11 }, .{ .code = 380, .codeLength = 11 }, .{ .code = 374, .codeLength = 11 }, .{ .code = 369, .codeLength = 11 }, .{ .code = 365, .codeLength = 11 }, .{ .code = 361, .codeLength = 11 }, .{ .code = 357, .codeLength = 11 }, .{ .code = 2, .codeLength = 8 } };
const table24_row_14 = [_]HuffCell{ .{ .code = 1033, .codeLength = 12 }, .{ .code = 280, .codeLength = 10 }, .{ .code = 278, .codeLength = 10 }, .{ .code = 274, .codeLength = 10 }, .{ .code = 267, .codeLength = 10 }, .{ .code = 264, .codeLength = 10 }, .{ .code = 259, .codeLength = 10 }, .{ .code = 382, .codeLength = 11 }, .{ .code = 378, .codeLength = 11 }, .{ .code = 372, .codeLength = 11 }, .{ .code = 367, .codeLength = 11 }, .{ .code = 363, .codeLength = 11 }, .{ .code = 360, .codeLength = 11 }, .{ .code = 358, .codeLength = 11 }, .{ .code = 356, .codeLength = 11 }, .{ .code = 0, .codeLength = 8 } };
const table24_row_15 = [_]HuffCell{ .{ .code = 43, .codeLength = 8 }, .{ .code = 20, .codeLength = 7 }, .{ .code = 19, .codeLength = 7 }, .{ .code = 17, .codeLength = 7 }, .{ .code = 15, .codeLength = 7 }, .{ .code = 13, .codeLength = 7 }, .{ .code = 11, .codeLength = 7 }, .{ .code = 9, .codeLength = 7 }, .{ .code = 7, .codeLength = 7 }, .{ .code = 6, .codeLength = 7 }, .{ .code = 4, .codeLength = 7 }, .{ .code = 7, .codeLength = 8 }, .{ .code = 5, .codeLength = 8 }, .{ .code = 3, .codeLength = 8 }, .{ .code = 1, .codeLength = 8 }, .{ .code = 3, .codeLength = 4 } };
pub const table24 = [_][]const HuffCell{
    table24_row_0[0..],
    table24_row_1[0..],
    table24_row_2[0..],
    table24_row_3[0..],
    table24_row_4[0..],
    table24_row_5[0..],
    table24_row_6[0..],
    table24_row_7[0..],
    table24_row_8[0..],
    table24_row_9[0..],
    table24_row_10[0..],
    table24_row_11[0..],
    table24_row_12[0..],
    table24_row_13[0..],
    table24_row_14[0..],
    table24_row_15[0..],
};

pub const bigValueLinbit = [_]u8{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 6, 8, 10, 13, 4, 5, 6, 7, 8, 9, 11, 13,
};

pub const bigValueMax = [_]u8{
    1, 2, 3, 3, 0, 4, 4, 6, 6, 6, 8, 8, 8, 16, 0, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
};

// Sine window tables from MsharP3/Tables.fs (SineTables module).
pub const sineBlock = [4][36]f64{
    .{ 0.043619387, 0.130526185, 0.216439620, 0.300705791, 0.382683426, 0.461748600, 0.537299633, 0.608761430, 0.675590217, 0.737277329, 0.793353319, 0.843391418, 0.887010813, 0.923879504, 0.953716934, 0.976296008, 0.991444886, 0.999048233, 0.999048233, 0.991444886, 0.976296008, 0.953716934, 0.923879504, 0.887010813, 0.843391418, 0.793353319, 0.737277329, 0.675590217, 0.608761430, 0.537299633, 0.461748600, 0.382683426, 0.300705791, 0.216439620, 0.130526185, 0.043619387 },
    .{ 0.043619387, 0.130526185, 0.216439620, 0.300705791, 0.382683426, 0.461748600, 0.537299633, 0.608761430, 0.675590217, 0.737277329, 0.793353319, 0.843391418, 0.887010813, 0.923879504, 0.953716934, 0.976296008, 0.991444886, 0.999048233, 1.000000000, 1.000000000, 1.000000000, 1.000000000, 1.000000000, 1.000000000, 0.991444886, 0.923879504, 0.793353319, 0.608761430, 0.382683426, 0.130526185, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000 },
    .{ 0.130526185, 0.382683426, 0.608761430, 0.793353319, 0.923879504, 0.991444886, 0.991444886, 0.923879504, 0.793353319, 0.608761430, 0.382683426, 0.130526185, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000 },
    .{ 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.130526185, 0.382683426, 0.608761430, 0.793353319, 0.923879504, 0.991444886, 1.000000000, 1.000000000, 1.000000000, 1.000000000, 1.000000000, 1.000000000, 0.999048233, 0.991444886, 0.976296008, 0.953716934, 0.923879504, 0.887010813, 0.843391418, 0.793353319, 0.737277329, 0.675590217, 0.608761430, 0.537299633, 0.461748600, 0.382683426, 0.300705791, 0.216439620, 0.130526185, 0.043619387 },
};

// Polyphase synthesis filter window D[i], i=0..511.
// Source: MsharP3/Tables.fs SynthTables.synthWindow
pub const synthWindow = [512]f64{
    0.000000000, -0.000015259, -0.000015259, -0.000015259, -0.000015259, -0.000015259, -0.000015259, -0.000030518,
    -0.000030518, -0.000030518, -0.000030518, -0.000045776, -0.000045776, -0.000061035, -0.000061035, -0.000076294,
    -0.000076294, -0.000091553, -0.000106812, -0.000106812, -0.000122070, -0.000137329, -0.000152588, -0.000167847,
    -0.000198364, -0.000213623, -0.000244141, -0.000259399, -0.000289917, -0.000320435, -0.000366211, -0.000396729,
    -0.000442505, -0.000473022, -0.000534058, -0.000579834, -0.000625610, -0.000686646, -0.000747681, -0.000808716,
    -0.000885010, -0.000961304, -0.001037598, -0.001113892, -0.001205444, -0.001296997, -0.001388550, -0.001480103,
    -0.001586914, -0.001693726, -0.001785278, -0.001907349, -0.002014160, -0.002120972, -0.002243042, -0.002349854,
    -0.002456665, -0.002578735, -0.002685547, -0.002792358, -0.002899170, -0.002990723, -0.003082275, -0.003173828,
    0.003250122, 0.003326416, 0.003387451, 0.003433228, 0.003463745, 0.003479004, 0.003479004, 0.003463745,
    0.003417969, 0.003372192, 0.003280640, 0.003173828, 0.003051758, 0.002883911, 0.002700806, 0.002487183,
    0.002227783, 0.001937866, 0.001617432, 0.001266479, 0.000869751, 0.000442505, -0.000030518, -0.000549316,
    -0.001098633, -0.001693726, -0.002334595, -0.003005981, -0.003723145, -0.004486084, -0.005294800, -0.006118774,
    -0.007003784, -0.007919312, -0.008865356, -0.009841919, -0.010848999, -0.011886597, -0.012939453, -0.014022827,
    -0.015121460, -0.016235352, -0.017349243, -0.018463135, -0.019577026, -0.020690918, -0.021789551, -0.022857666,
    -0.023910522, -0.024932861, -0.025909424, -0.026840210, -0.027725220, -0.028533936, -0.029281616, -0.029937744,
    -0.030532837, -0.031005859, -0.031387329, -0.031661987, -0.031814575, -0.031845093, -0.031738281, -0.031478882,
    0.031082153, 0.030517578, 0.029785156, 0.028884888, 0.027801514, 0.026535034, 0.025085449, 0.023422241,
    0.021575928, 0.019531250, 0.017257690, 0.014801025, 0.012115479, 0.009231567, 0.006134033, 0.002822876,
    -0.000686646, -0.004394531, -0.008316040, -0.012420654, -0.016708374, -0.021179199, -0.025817871, -0.030609131,
    -0.035552979, -0.040634155, -0.045837402, -0.051132202, -0.056533813, -0.061996460, -0.067520142, -0.073059082,
    -0.078628540, -0.084182739, -0.089706421, -0.095169067, -0.100540161, -0.105819702, -0.110946655, -0.115921021,
    -0.120697021, -0.125259399, -0.129562378, -0.133590698, -0.137298584, -0.140670776, -0.143676758, -0.146255493,
    -0.148422241, -0.150115967, -0.151306152, -0.151962280, -0.152069092, -0.151596069, -0.150497437, -0.148773193,
    -0.146362305, -0.143264771, -0.139450073, -0.134887695, -0.129577637, -0.123474121, -0.116577148, -0.108856201,
    0.100311279, 0.090927124, 0.080688477, 0.069595337, 0.057617188, 0.044784546, 0.031082153, 0.016510010,
    0.001068115, -0.015228271, -0.032379150, -0.050354004, -0.069168091, -0.088775635, -0.109161377, -0.130310059,
    -0.152206421, -0.174789429, -0.198059082, -0.221984863, -0.246505737, -0.271591187, -0.297210693, -0.323318481,
    -0.349868774, -0.376800537, -0.404083252, -0.431655884, -0.459472656, -0.487472534, -0.515609741, -0.543823242,
    -0.572036743, -0.600219727, -0.628295898, -0.656219482, -0.683914185, -0.711318970, -0.738372803, -0.765029907,
    -0.791213989, -0.816864014, -0.841949463, -0.866363525, -0.890090942, -0.913055420, -0.935195923, -0.956481934,
    -0.976852417, -0.996246338, -1.014617920, -1.031936646, -1.048156738, -1.063217163, -1.077117920, -1.089782715,
    -1.101211548, -1.111373901, -1.120223999, -1.127746582, -1.133926392, -1.138763428, -1.142211914, -1.144287109,
    1.144989014, 1.144287109, 1.142211914, 1.138763428, 1.133926392, 1.127746582, 1.120223999, 1.111373901,
    1.101211548, 1.089782715, 1.077117920, 1.063217163, 1.048156738, 1.031936646, 1.014617920, 0.996246338,
    0.976852417, 0.956481934, 0.935195923, 0.913055420, 0.890090942, 0.866363525, 0.841949463, 0.816864014,
    0.791213989, 0.765029907, 0.738372803, 0.711318970, 0.683914185, 0.656219482, 0.628295898, 0.600219727,
    0.572036743, 0.543823242, 0.515609741, 0.487472534, 0.459472656, 0.431655884, 0.404083252, 0.376800537,
    0.349868774, 0.323318481, 0.297210693, 0.271591187, 0.246505737, 0.221984863, 0.198059082, 0.174789429,
    0.152206421, 0.130310059, 0.109161377, 0.088775635, 0.069168091, 0.050354004, 0.032379150, 0.015228271,
    -0.001068115, -0.016510010, -0.031082153, -0.044784546, -0.057617188, -0.069595337, -0.080688477, -0.090927124,
    0.100311279, 0.108856201, 0.116577148, 0.123474121, 0.129577637, 0.134887695, 0.139450073, 0.143264771,
    0.146362305, 0.148773193, 0.150497437, 0.151596069, 0.152069092, 0.151962280, 0.151306152, 0.150115967,
    0.148422241, 0.146255493, 0.143676758, 0.140670776, 0.137298584, 0.133590698, 0.129562378, 0.125259399,
    0.120697021, 0.115921021, 0.110946655, 0.105819702, 0.100540161, 0.095169067, 0.089706421, 0.084182739,
    0.078628540, 0.073059082, 0.067520142, 0.061996460, 0.056533813, 0.051132202, 0.045837402, 0.040634155,
    0.035552979, 0.030609131, 0.025817871, 0.021179199, 0.016708374, 0.012420654, 0.008316040, 0.004394531,
    0.000686646, -0.002822876, -0.006134033, -0.009231567, -0.012115479, -0.014801025, -0.017257690, -0.019531250,
    -0.021575928, -0.023422241, -0.025085449, -0.026535034, -0.027801514, -0.028884888, -0.029785156, -0.030517578,
    0.031082153, 0.031478882, 0.031738281, 0.031845093, 0.031814575, 0.031661987, 0.031387329, 0.031005859,
    0.030532837, 0.029937744, 0.029281616, 0.028533936, 0.027725220, 0.026840210, 0.025909424, 0.024932861,
    0.023910522, 0.022857666, 0.021789551, 0.020690918, 0.019577026, 0.018463135, 0.017349243, 0.016235352,
    0.015121460, 0.014022827, 0.012939453, 0.011886597, 0.010848999, 0.009841919, 0.008865356, 0.007919312,
    0.007003784, 0.006118774, 0.005294800, 0.004486084, 0.003723145, 0.003005981, 0.002334595, 0.001693726,
    0.001098633, 0.000549316, 0.000030518, -0.000442505, -0.000869751, -0.001266479, -0.001617432, -0.001937866,
    -0.002227783, -0.002487183, -0.002700806, -0.002883911, -0.003051758, -0.003173828, -0.003280640, -0.003372192,
    -0.003417969, -0.003463745, -0.003479004, -0.003479004, -0.003463745, -0.003433228, -0.003387451, -0.003326416,
    0.003250122, 0.003173828, 0.003082275, 0.002990723, 0.002899170, 0.002792358, 0.002685547, 0.002578735,
    0.002456665, 0.002349854, 0.002243042, 0.002120972, 0.002014160, 0.001907349, 0.001785278, 0.001693726,
    0.001586914, 0.001480103, 0.001388550, 0.001296997, 0.001205444, 0.001113892, 0.001037598, 0.000961304,
    0.000885010, 0.000808716, 0.000747681, 0.000686646, 0.000625610, 0.000579834, 0.000534058, 0.000473022,
    0.000442505, 0.000396729, 0.000366211, 0.000320435, 0.000289917, 0.000259399, 0.000244141, 0.000213623,
    0.000198364, 0.000167847, 0.000152588, 0.000137329, 0.000122070, 0.000106812, 0.000106812, 0.000091553,
    0.000076294, 0.000076294, 0.000061035, 0.000061035, 0.000045776, 0.000045776, 0.000030518, 0.000030518,
    0.000030518, 0.000030518, 0.000015259, 0.000015259, 0.000015259, 0.000015259, 0.000015259, 0.000015259,
};

// Cosine matrixing matrix N[i][k] = cos((16+i)(2k+1)pi/64), i=0..63, k=0..31.
// Computed at runtime in pqmf.zig to avoid large compile-time loops.
pub const lookup = [_]f64{0} ** (64 * 32);

pub fn getHuffmanTable(id: u8) []const []const HuffCell {
    if (id >= 32) @panic("Table ID should be between 0-31");
    return switch (id) {
        0, 4, 14 => table0[0..],
        1 => table1[0..],
        2 => table2[0..],
        3 => table3[0..],
        5 => table5[0..],
        6 => table6[0..],
        7 => table7[0..],
        8 => table8[0..],
        9 => table9[0..],
        10 => table10[0..],
        11 => table11[0..],
        12 => table12[0..],
        13 => table13[0..],
        15 => table15[0..],
        16, 17, 18, 19, 20, 21, 22, 23 => table16[0..],
        else => table24[0..],
    };
}
