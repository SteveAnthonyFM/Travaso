# Travaso Developer Guide

## Requirements

- Apple Silicon Mac, macOS 26 or later
- Xcode 27 (first-launch components installed: `sudo xcodebuild -runFirstLaunch`)
- Homebrew `pkgconf` (only for building FFmpeg)

## Building

```
brew install pkgconf
./Scripts/build-ffmpeg.sh      # once; creates Vendor/ffmpeg (not in git)
open Travaso.xcodeproj         # ⌘R to run a debug build
./Scripts/build-release.sh     # release build, installed to /Applications/Travaso.app
```

Build settings worth knowing (all in `Travaso.xcodeproj`):
- arm64 only, deployment target macOS 26.0, Swift 5 language mode.
- Signed ad hoc ("Sign to Run Locally", identity `-`); no Apple developer account needed.
  Hardened Runtime and App Sandbox are **off**: the app writes converted files wherever you choose
  (next to the originals or in any folder) and runs the bundled FFmpeg as a separate program, which a sandbox
  would restrict. Turning them on would also require a paid developer account for signing and notarization.
- The `Travaso/` folder is a *synchronized folder*: new Swift files added there are compiled automatically.
- Build phase **Copy FFmpeg** puts `ffmpeg` and `ffprobe` in `Travaso.app/Contents/MacOS/` (code-signed on copy);
  **Copy FFmpeg Licenses** puts `Vendor/ffmpeg/LICENSES` in `Contents/Resources/FFmpeg/`.

## Project layout

```
Travaso.xcodeproj
Travaso/
  TravasoApp.swift            App entry, window, ⌘O command, forces dark appearance
  ContentView.swift           Window layout, drag-and-drop target, reads settings (@AppStorage)
  Theme.swift                 All colors, fonts and sizes
  FFmpeg.swift                Runs bundled ffprobe/ffmpeg; probe(), convert() with progress and cancellation
  Models/
    OutputFormat.swift        The 7 output formats (name, extension, lossless?, max sample rate)
    ConversionSettings.swift  Quality, keep rate/depth, output folder
    ConversionPlan.swift      Pure logic: output names, FFmpeg arguments, size estimates
    FileItem.swift            One row: source, file facts, status
    ConversionQueue.swift     The list: add/scan, remove, pre-flight questions, parallel batch
    RunQuestions.swift        Mono / conflict / message dialogs (NSAlert sheets)
  Views/
    FileListView.swift        List, empty drop prompt, context menu, double-click
    FileRowView.swift         Row content
    ProgressRing.swift        Ready / % / ✓ / ✕ / Skipped ring
    BottomBar.swift           Format menu, gear, status, Convert/Stop
    SettingsPanel.swift       Settings popover
  Assets.xcassets             App icon
Scripts/
  build-ffmpeg.sh             Builds LGPL FFmpeg + LAME + Vorbis from official sources
  build-release.sh            Release build + install to /Applications
  make-icon.swift             Generates the icon set from a picture
Vendor/ffmpeg/                Build output of build-ffmpeg.sh (git-ignored)
docs/                         Documentation
```

## How a conversion works

1. **Adding:** `ConversionQueue.add` scans folders off the main thread (by extension, plus a UTType audio check),
   skips duplicates, then runs `FFmpeg.probe` (ffprobe JSON) 8 at a time to read duration, channels, sample rate,
   bit depth and codec.
2. **Pre-flight** (`ConversionQueue.askQuestions`), in list order, before anything converts:
   - mono sources → Keep Mono / Convert to Stereo (with Apply to all);
   - output already on disk → Overwrite / Skip / Keep Both (with Apply to all);
   - output already claimed by an earlier file in the run → automatically numbered.
3. **Batch:** a task group runs up to `maxParallel = 4` conversions. Each writes to a hidden
   `.travaso-<UUID>.<ext>` temp file next to the destination, then `replaceItemAt` moves it into place.
4. **Progress:** ffmpeg runs with `-progress pipe:1`; `out_time_us` ÷ duration drives the ring.
5. **Stop:** cancelling the run task terminates running ffmpeg processes (`withTaskCancellationHandler`);
   temp files are removed and rows return to Ready.

FFmpeg arguments (`ConversionPlan.arguments`) always include `-map 0:a:0 -vn` (first audio stream, no
album art), `-map_metadata 0` (tags), and `-af aresample=filter_size=64` (high-quality resampling, plus
`:dither_method=triangular` when a >16-bit source is written as 16-bit lossless). Per format:

| Format | Encoder arguments |
|---|---|
| MP3 | `libmp3lame -b:a 320k/192k -id3v2_version 3` |
| AAC | `aac_at -b:a 256k/160k` (Apple AudioToolbox) |
| OGG | `libvorbis -q:a 8/5` |
| WAV | `pcm_s16le` / `pcm_s24le` |
| AIFF | `pcm_s16be` / `pcm_s24be -write_id3v2 1` |
| FLAC | `flac -sample_fmt s16` / `s32 -bits_per_raw_sample 24` |
| ALAC | `alac -sample_fmt s16p` / `s32p -bits_per_raw_sample 24` |

Channels: `-ac 2` for surround sources, or for mono when the user chooses Convert to Stereo.
Sample rate: 44.1 kHz unless "keep original" is on, capped by `OutputFormat.maxSampleRate` (48 kHz for MP3/AAC).

## Restyling

Edit `Travaso/Theme.swift` only. It holds every color (`Color(hex: 0xRRGGBB)` helper included), font and size,
grouped as Backgrounds, Text, Accents and status, Fonts, Sizes. The app is dark-only
(`NSApp.appearance = .darkAqua` and `.preferredColorScheme(.dark)`).

## App icon

```
swift Scripts/make-icon.swift <picture>      # any picture of the icon on a plain background
```
The script finds the rounded-square icon in the picture (where it differs from the corner background color),
crops inside its edge, fits it to the macOS icon grid (824 px body on a 1024 canvas, ~22.5% corner radius) and
writes all sizes to `Travaso/Assets.xcassets/AppIcon.appiconset`. Rebuild and reinstall to see it in the Dock.

## Testing

There is no automated test target. Verification used during development:
- `build-ffmpeg.sh` self-check: LGPL license, required encoders, no non-Apple dynamic libraries.
- A command-line harness compiling `FFmpeg.swift` + `Models/ConversionPlan.swift` etc. that converts sample
  files to all 7 formats (default and "keep" settings) and checks codec, rate, bit depth, channels, tags and
  size estimates with ffprobe.
- Manual tests with a folder of varied files: 24-bit stereo WAV, mono AIFF, MP3, 96 kHz FLAC, 6-channel WAV,
  a broken file and a non-audio file, across subfolders.

## Known limitations

- Output-folder mode puts all files in one folder (no subfolder mirroring).
- No album art, logs or "recent" menu (by design).
- FLAC/ALAC/OGG size estimates are rough (they depend on the audio).
