# FFmpeg in Travaso

Travaso bundles its own `ffmpeg` and `ffprobe` (inside `Travaso.app/Contents/MacOS/`), so it does not depend on
anything installed on the Mac and keeps working on future macOS versions.

## Source

Built by `Scripts/build-ffmpeg.sh` from the official source releases. No pre-built binaries are used.
Each download is checked against the SHA-256 checksum below before building.

| Component | Version | Source (official) | SHA-256 | License |
|---|---|---|---|---|
| FFmpeg | 9.0.2 | https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz | `8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e` | LGPL 2.1+ |
| LAME (MP3 encoder) | 3.100 | https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz | `ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e` | LGPL 2+ |
| libogg | 1.3.6 | https://downloads.xiph.org/releases/ogg/libogg-1.3.6.tar.xz | `5c8253428e181840cd20d41f3ca16557a9cc04bad4a3d04cce84808677fa1061` | BSD-3-Clause |
| libvorbis | 1.3.7 | https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz | `b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b` | BSD-3-Clause |

Verification notes:
- libogg, libvorbis and LAME checksums match the values published by those projects.
- FFmpeg publishes a GPG signature (`ffmpeg-9.0.2.tar.xz.asc`) rather than a checksum. The checksum above is of
  the copy downloaded over HTTPS from ffmpeg.org on 2026-10-05. To verify the signature: `brew install gnupg`,
  import the FFmpeg release key listed at https://ffmpeg.org/download.html, then
  `gpg --verify ffmpeg-9.0.2.tar.xz.asc ffmpeg-9.0.2.tar.xz`.

## Why build from source

The macOS builds linked from ffmpeg.org (evermeet.cx) are GPL builds for Intel Macs, and Homebrew's FFmpeg is GPL
and depends on many other installed libraries. Building from source gives a small, self-contained, Apple Silicon,
**LGPL** binary with exactly the audio features Travaso needs.

## Configuration

Static libraries, arm64, minimum macOS 26.0:

```
--arch=arm64 --enable-static --disable-shared --disable-autodetect
--enable-audiotoolbox --enable-libmp3lame --enable-libvorbis
--disable-ffplay --disable-network --disable-doc --disable-debug --disable-avdevice
```

- **No** `--enable-gpl` and **no** `--enable-nonfree` → the result is LGPL.
- `--disable-autodetect` stops it from picking up Homebrew libraries by accident.
- AAC uses Apple's AudioToolbox encoder (`aac_at`); FLAC, ALAC, WAV and AIFF use FFmpeg's built-in encoders.

The script's final self-check confirms: the license reported by `ffmpeg -L` is LGPL; the encoders `libmp3lame`,
`flac`, `alac`, `aac_at`, `libvorbis`, `pcm_s16le`, `pcm_s24le`, `pcm_s16be` exist; and `otool -L` shows only
macOS system libraries.

## Updating FFmpeg

1. Change the version and SHA-256 in `Scripts/build-ffmpeg.sh` (and this file).
2. Run `./Scripts/build-ffmpeg.sh`; check the self-check passes.
3. Rebuild the app (`./Scripts/build-release.sh`).

## Licensing obligations if the app is ever shared

Travaso runs FFmpeg as a separate program (it is not linked into Travaso's own code). When distributing:
include the license texts (already copied into `Travaso.app/Contents/Resources/FFmpeg/LICENSES/`), state that
FFmpeg and LAME are LGPL, and point to the exact sources above (or provide them). See
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
