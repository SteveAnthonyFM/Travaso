# Changelog

## 1.0.1 — 2026-11-03

Security hardening and a data-safety fix, from a full security audit (no exploitable vulnerabilities were found).

- Fixed: converting `Song.MP3` to MP3 on a case-insensitive disk could offer to overwrite the original itself. Source
  files are now recognised by file identity, and an output name that matches any file in the batch is numbered.
- The name-conflict question now defaults to **Keep Both** instead of **Overwrite**.
- Numbers read from damaged or hostile files are range-checked, so they can't crash the app.
- Only regular files are accepted from folders and drops (no pipes or devices); web links dropped on the window are ignored.
- Reading a file's details times out after 60 s; captured ffmpeg output is capped at 1 MB per stream.
- ffmpeg and ffprobe are limited to the `file` protocol.
- Quitting during a batch now stops ffmpeg and deletes its temporary files.
- Release workflow: actions pinned to commit SHAs, build job is read-only, release job alone can write, and the
  bundled ffmpeg is re-verified on every run (including cache hits).

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
