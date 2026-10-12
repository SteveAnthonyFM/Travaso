# Changelog

## 1.0 — 2026-10-05

First release.

- Native SwiftUI app for Apple Silicon, macOS 26+, dark mode only, custom icon and palette.
- Bundled LGPL FFmpeg 9.0.2 with LAME 3.100 (MP3), libogg 1.3.6 and libvorbis 1.3.7, built from official sources.
- File list with output name, size estimate and per-file progress ring.
- Drag and drop of files and folders (recursive scan), ⌘O to add files.
- Output formats: MP3, WAV, FLAC, AIFF, AAC (.m4a), Apple Lossless (.m4a), OGG Vorbis.
- Quality High/Medium; default 44.1 kHz / 16-bit with options to keep source sample rate and bit depth.
- Parallel conversion (4 at a time) with Stop, failure messages and a run summary.
- Mono warning (Keep Mono / Convert to Stereo) and name-conflict dialog (Overwrite / Skip / Keep Both),
  each with "Apply to all".
- Save next to originals or to a chosen folder.
- Text tags carried over; original files never overwritten; temp-file-then-move safety.
