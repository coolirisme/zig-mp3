// Frequency-line reordering for MPEG1 Layer III short blocks
//
// Background
// ----------
// The Huffman bitstream (and requantizer output) stores short-block spectral
// values interleaved across the three sub-windows, indexed by scalefactor band:
//
//   xr[bandIndex.short[sfb] * 3 + k * 3 + win]
//     = per-window line (bandIndex.short[sfb] + k), window win
//
// The IMDCT operates on 32 subbands × 6 lines per window. To give it a clean
// sequential view, we un-interleave into window-contiguous blocks.

const std = @import("std");

pub const SfType = enum {
    long,
    short,
    mixed,
};

pub const BandIndex = struct {
    long: []const u32,
    short: []const u32,
};

/// Reorder short-block frequency lines from scalefactor-band-interleaved format
/// to window-contiguous format.
///
/// Long blocks are returned unchanged (same reference, no copy).
pub fn reorderSpectrum(allocator: std.mem.Allocator, xr: []const f64, sfType: SfType, bandIndex: BandIndex) ![]f64 {
    if (sfType == .long) {
        const out = try allocator.alloc(f64, xr.len);
        @memcpy(out, xr);
        return out;
    }

    const output = try allocator.alloc(f64, 576);
    @memset(output, 0);

    // bandIndex.short layout (all sample rates share these two sentinel values):
    //   [3]  = 12   - per-window start of the mixed-block short region
    //   [12] = n    - last non-zero per-window line (sfb 0..11 covered)
    //   [13] = 192  - total per-window lines  (32 subbands × 6)
    const perWin = bandIndex.short[13]; // always 192

    if (sfType == .short) {
        // Scatter from sequential per-window layout to window-contiguous layout.
        var srcOff: usize = 0;
        var sfb: usize = 0;
        while (sfb < 12) : (sfb += 1) {
            const width = bandIndex.short[sfb + 1] - bandIndex.short[sfb];
            const pWinOff = bandIndex.short[sfb];
            var win: usize = 0;
            while (win < 3) : (win += 1) {
                var k: usize = 0;
                while (k < width) : (k += 1) {
                    output[win * perWin + pWinOff + k] = xr[srcOff];
                    srcOff += 1;
                }
            }
        }
    } else {
        // Mixed block
        // - Long portion (subbands 0-1, lines 0..35): copy as-is
        @memcpy(output[0..36], xr[0..36]);

        // - Short portion (subbands 2-31): scatter from sequential layout
        const shortBase = bandIndex.short[3]; // always 12
        const shortPerWin = perWin - shortBase; // always 180

        var srcOff: usize = 36;
        var sfb: usize = 3;
        while (sfb < 12) : (sfb += 1) {
            const width = bandIndex.short[sfb + 1] - bandIndex.short[sfb];
            const pWinOff = bandIndex.short[sfb] - shortBase;
            var win: usize = 0;
            while (win < 3) : (win += 1) {
                var k: usize = 0;
                while (k < width) : (k += 1) {
                    output[36 + win * shortPerWin + pWinOff + k] = xr[srcOff];
                    srcOff += 1;
                }
            }
        }
    }

    return output;
}
