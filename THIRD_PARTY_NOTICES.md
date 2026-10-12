# Third-Party Notices

Travaso's own source code is under the MIT license (see [LICENSE](LICENSE)). The application bundles the following
separately built programs and libraries, which remain under their own licenses. Full license texts are copied into
the app at `Travaso.app/Contents/Resources/FFmpeg/LICENSES/` (and into `Vendor/ffmpeg/LICENSES/` by the build script).

| Component | Version | License | Source |
|---|---|---|---|
| FFmpeg (`ffmpeg`, `ffprobe`) | 9.0.2 | GNU LGPL 2.1 or later | https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz |
| LAME | 3.100 | GNU LGPL 2 or later | https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz |
| libogg | 1.3.6 | BSD-3-Clause (Xiph.Org Foundation) | https://downloads.xiph.org/releases/ogg/libogg-1.3.6.tar.xz |
| libvorbis | 1.3.7 | BSD-3-Clause (Xiph.Org Foundation) | https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz |

FFmpeg was configured without `--enable-gpl` and without `--enable-nonfree`. The exact build steps are in
`Scripts/build-ffmpeg.sh`; checksums and configuration are documented in [docs/FFMPEG.md](docs/FFMPEG.md).

This software uses code of FFmpeg (https://ffmpeg.org) licensed under the LGPLv2.1, and LAME
(https://lame.sourceforge.io) licensed under the LGPL.

No third-party source code is copied into Travaso's own files.
