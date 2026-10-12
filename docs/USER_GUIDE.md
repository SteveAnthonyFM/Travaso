# Travaso User Guide

Travaso converts audio files between common formats. It runs entirely on your Mac; nothing is uploaded.

## The window

- **File list:** one row per file, showing:
  - the file name
  - **→ output name** (with the folder name in front if you save to a chosen folder)
  - **original size › estimated new size** (a `~` means a rough estimate)
  - a **progress ring**: *Ready* → percentage while converting → ✓ done, ✕ failed, or *Skipped*
- **Bottom bar:** format menu · settings gear · status text · **Convert** button (becomes **Stop** while running).

## Adding files

- Drag files or folders onto the window. Folders are scanned, including subfolders; non-audio files are ignored.
- Or press **⌘O** (File ▸ Add Files…), or click the empty window.
- A file already in the list is not added twice.
- Remove files: select and press **Delete**, or right-click ▸ **Remove** / **Remove All**.

Readable source formats include WAV, AIFF, FLAC, MP3, M4A/AAC, Apple Lossless, OGG, Opus, WMA, CAF and others
that FFmpeg understands. A file that can't be read shows ✕ *Not a readable audio file*.

## Choosing a format

| Format | File | Type | Notes |
|---|---|---|---|
| MP3 (default) | .mp3 | compressed | Most compatible |
| WAV | .wav | uncompressed | Exact, large |
| FLAC | .flac | lossless | Exact, about half the size of WAV |
| AIFF | .aiff | uncompressed | Apple's WAV equivalent |
| AAC | .m4a | compressed | Apple's encoder; good quality at smaller sizes |
| Apple Lossless | .m4a | lossless | Exact; plays everywhere in Apple's ecosystem |
| OGG Vorbis | .ogg | compressed | Open format |

Changing the format updates every row's output name and size estimate. Finished rows return to *Ready* so they
can be converted again in the new format.

## Settings (gear button)

| Setting | Default | What it does |
|---|---|---|
| Quality | High | High: MP3 320 kbps, AAC 256 kbps, OGG ≈256 kbps. Medium: MP3 192, AAC 160, OGG ≈160. |
| Keep original sample rate | Off | Off: every file is saved at 44.1 kHz. On: keeps the source rate (MP3 and AAC max 48 kHz). |
| Keep original bit depth | Off | WAV, FLAC, AIFF, Apple Lossless. Off: 16-bit (with gentle dither when reducing from 24-bit). On: 24-bit sources stay 24-bit. |
| Save converted files | Next to the originals | Or **In a folder:** click **Choose…** to pick one. |

Settings are remembered between launches.

Good to know:
- Converting an MP3 (or AAC/OGG) to WAV or FLAC makes the file bigger, not better: lost detail can't come back.
- Stereo stays stereo. Surround files (more than 2 channels) are mixed down to stereo.
- Text tags (title, artist, album, year, track, …) are copied. Album art is not.
- With an output folder set, all files go directly into it (subfolders are not recreated).

## Converting

Click **Convert** (or press **⌘↩**). Before anything converts, Travaso may ask two kinds of questions, in list
order, so nothing pops up in the middle of a batch:

**Mono files** — *"song.aiff" is mono.*
- **Keep Mono** (default, Return key): stays a single channel.
- **Convert to Stereo**: the same sound in both left and right.

**Existing files** — *"song.mp3" already exists in "Music".*
- **Overwrite** (default): replace the existing file.
- **Skip**: don't convert this file (ring shows *Skipped*).
- **Keep Both**: save the new file as `song 1.mp3` (or the next free number).

Tick **Apply to all** to use the same answer for the rest of that run. The next Convert asks again.

Then up to 4 files convert at once. The bottom bar shows a summary, e.g. *8 converted, 1 skipped, 1 failed*.
Click **Stop** to cancel; unfinished files return to *Ready* and no partial files are left behind.

Automatic protections:
- The original file is never overwritten. (MP3 → MP3 in the same folder saves as `song 1.mp3`.)
- If two files in one batch would get the same output name (e.g. `song.wav` and `song.flac` → `song.mp3`),
  the second is numbered automatically.
- Each file is written to a hidden temporary file first and only moved into place when complete.

## After converting

Double-click a converted row, or right-click ▸ **Show in Finder**, to see the new file.

## Troubleshooting

| Message | Meaning / fix |
|---|---|
| Not a readable audio file | The file is damaged, empty, or not audio. |
| The file seems damaged or isn't really audio | FFmpeg couldn't decode it. Try opening it in Music or QuickTime. |
| Can't save in this folder (no permission) | Pick a different output folder, or check the folder's permissions in Finder ▸ Get Info. |
| The disk is full | Free up space or choose a folder on another drive. |
| The output folder "…" can't be found | It was moved, renamed or its drive is disconnected. Choose it again in Settings. |
| Conversion failed: … | FFmpeg's own error; the text after the colon gives the detail. |
