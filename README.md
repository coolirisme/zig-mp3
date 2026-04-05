# zig-mp3

A Zig implementation of the MPEG I Layer III (mp3) decoder.

## What It Does

- Parses and decodes MPEG-1 Layer III (MP3) frames.
- Produces interleaved PCM samples.
- Can:
  - print decode stats
  - write decoded WAV output
  - play audio directly in terminal
  - stream decode+play in realtime mode
  - fetch YouTube audio (`yt-dlp` + `ffmpeg`) and decode it

## Project Layout

- `cli.zig` - CLI entry point and runtime orchestration.
- `mp3decoder.zig` - frame parsing + decode pipeline + full/realtime decode APIs.
- `wav.zig` - PCM16 and WAV encoding helpers.
- `algorithm/` - decoding stages:
  - `bits.zig`
  - `sideinfo.zig`
  - `huffman.zig`
  - `requantize.zig`
  - `stereo.zig`
  - `reorder.zig`
  - `antialias.zig`
  - `imdct.zig`
  - `pqmf.zig`
  - `tables.zig`

## Decode Pipeline

The decoder follows the standard MPEG-1 Layer III flow in `mp3decoder.zig`.

1. **Frame sync + header parse**
   - Scan bytes for sync words and parse MPEG header fields (`parseFrameHeader`).
   - Validate version/layer/rate/length and skip inconsistent candidates.
   - Skip ID3v2 and optional Xing/Info metadata frame in full-file decode.

2. **Side info + bit reservoir setup**
   - Read side info (`sideinfo.parseSideInfo`) and derive frame band indices.
   - Append current frame main data to reservoir tail from prior frames.
   - Use `mainDataBegin` to pick the true Huffman bitstream start.

3. **Scale factors + Huffman spectral decode**
   - Parse scale factors per granule/channel (`huffman.parseScaleFactors`).
   - Decode Huffman-coded spectral lines (`huffman.parseHuffmanData`).
   - Preserve granule-0 long-block scale factors for `scfsi` reuse.

4. **Requantize + stereo processing**
   - Requantize integer Huffman output to frequency-domain amplitudes (`requantize.requantizeGranule`).
   - For joint stereo, apply MS/intensity stereo transforms (`stereo.processStereo`).

5. **Reorder + anti-alias + IMDCT**
   - Reorder short/mixed blocks to frequency order (`reorder.reorderSpectrum`).
   - Apply alias reduction for eligible bands (`antialias.applyAntiAlias`).
   - Run IMDCT with overlap-add state per channel (`imdct.applyIMDCT`).

6. **Polyphase synthesis (PQMF) + output**
   - Process each 32-subband time slice through synthesis filterbank (`pqmf.synthFilterStep`).
   - Clamp to `[-1, 1]` float PCM and interleave channels.
   - Emit either:
     - one contiguous PCM buffer (`decodeAllFrames`), or
     - streaming chunks via callback (`decodeAllFramesRealtime`).

## Build

```bash
zig build
```

Run directly:

```bash
zig build run -- <args>
```

Or compile the executable and run it:

```bash
zig build
./zig-out/bin/cli <args>
```

## CLI Usage

```bash
zig build run -- [--play|-p] [--interactive] [--seek <sec|mm:ss|hh:mm:ss>] <input.mp3|-> [output.wav]
zig build run -- [--play|-p] [--interactive] [--seek <sec|mm:ss|hh:mm:ss>] --yt <youtube-url> [output.wav]
```

### Options

- `--play`, `-p`  
  Decode and play in terminal (`aplay`, `paplay`, or `ffplay`).

- `--interactive`  
  Enable keyboard controls (`<-` / `->` seek, `q` quit). Requires a TTY.

- `--seek <t>`  
  Seek offset in seconds or `mm:ss` / `hh:mm:ss`.

- `--yt <url>`  
  Pull audio from YouTube via `yt-dlp`, transcode to MP3 via `ffmpeg`, then decode.

- `-` (input path)  
  Read MP3 bytes from stdin.

## Examples

Decode and print stats:

```bash
zig build run -- song.mp3
```

Decode and write WAV:

```bash
zig build run -- song.mp3 output.wav
```

Play audio:

```bash
zig build run -- --play song.mp3
```

Play audio with interactive controls:

```bash
zig build run -- --play --interactive song.mp3
```

Play with seek:

```bash
zig build run -- --play --seek 1:30 song.mp3
```

Pipe input:

```bash
cat song.mp3 | zig build run -- --play -
```

YouTube source:

```bash
zig build run -- --play --yt "https://www.youtube.com/watch?v=VIDEO_ID"
```

## Runtime Dependencies

- Required for `--yt`:
  - [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)
  - [`ffmpeg`](https://ffmpeg.org/)
- Required for `--play` (at least one):
  - `aplay` or
  - `paplay` or
  - `ffplay`
