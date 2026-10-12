#!/bin/zsh
# Builds a self-contained, LGPL, audio-focused FFmpeg for Apple Silicon.
# Output: Vendor/ffmpeg/bin/{ffmpeg,ffprobe} and Vendor/ffmpeg/LICENSES/
#
# All sources come from the official projects and are checked against pinned
# SHA-256 checksums. Needs: Xcode command line tools, pkg-config (brew install pkgconf).
set -euo pipefail

ROOT="${0:A:h:h}"
WORK="$ROOT/build/ffmpeg-work"
SRC="$WORK/src"
PREFIX="$WORK/prefix"
OUT="$ROOT/Vendor/ffmpeg"
MIN_MACOS="26.0"
JOBS="$(sysctl -n hw.ncpu)"

FFMPEG_VER="9.0.2"
LAME_VER="3.100"
OGG_VER="1.3.6"
VORBIS_VER="1.3.7"

# name | url | sha256
SOURCES=(
  "ffmpeg-$FFMPEG_VER.tar.xz|https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VER.tar.xz|8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e"
  "lame-$LAME_VER.tar.gz|https://downloads.sourceforge.net/project/lame/lame/$LAME_VER/lame-$LAME_VER.tar.gz|ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e"
  "libogg-$OGG_VER.tar.xz|https://downloads.xiph.org/releases/ogg/libogg-$OGG_VER.tar.xz|5c8253428e181840cd20d41f3ca16557a9cc04bad4a3d04cce84808677fa1061"
  "libvorbis-$VORBIS_VER.tar.xz|https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VER.tar.xz|b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"
)

command -v pkg-config >/dev/null || { echo "pkg-config missing: run 'brew install pkgconf'"; exit 1; }

export CC="clang"
export CFLAGS="-arch arm64 -mmacosx-version-min=$MIN_MACOS -O2"
export LDFLAGS="-arch arm64 -mmacosx-version-min=$MIN_MACOS"
# Only look at our own freshly built libraries, never Homebrew's.
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
unset PKG_CONFIG_PATH

rm -rf "$PREFIX" "$WORK/build"
mkdir -p "$SRC" "$PREFIX" "$WORK/build"

echo "==> Downloading and verifying sources"
for entry in $SOURCES; do
  name="${entry%%|*}"; rest="${entry#*|}"; url="${rest%%|*}"; sum="${rest#*|}"
  [[ -f "$SRC/$name" ]] || curl -fL --retry 3 -o "$SRC/$name" "$url"
  echo "$sum  $SRC/$name" | shasum -a 256 -c - || { echo "Checksum mismatch for $name"; exit 1; }
  tar -xf "$SRC/$name" -C "$WORK/build"
done

echo "==> Building LAME $LAME_VER (MP3 encoder, LGPL)"
cd "$WORK/build/lame-$LAME_VER"
./configure --prefix="$PREFIX" --host=aarch64-apple-darwin --enable-static --disable-shared --disable-frontend --disable-gtktest >/dev/null
make -j"$JOBS" >/dev/null && make install >/dev/null

echo "==> Building libogg $OGG_VER (BSD)"
cd "$WORK/build/libogg-$OGG_VER"
./configure --prefix="$PREFIX" --host=aarch64-apple-darwin --enable-static --disable-shared >/dev/null
make -j"$JOBS" >/dev/null && make install >/dev/null

echo "==> Building libvorbis $VORBIS_VER (BSD)"
cd "$WORK/build/libvorbis-$VORBIS_VER"
# Old configure adds a flag modern Apple linkers reject.
sed -i '' 's/ -force_cpusubtype_ALL//g' configure
./configure --prefix="$PREFIX" --host=aarch64-apple-darwin --enable-static --disable-shared \
  --with-ogg="$PREFIX" --disable-examples --disable-docs >/dev/null
make -j"$JOBS" >/dev/null && make install >/dev/null

echo "==> Building FFmpeg $FFMPEG_VER (LGPL; no --enable-gpl, no --enable-nonfree)"
cd "$WORK/build/ffmpeg-$FFMPEG_VER"
./configure \
  --prefix="$PREFIX" \
  --arch=arm64 --cc=clang \
  --enable-static --disable-shared \
  --disable-autodetect \
  --enable-audiotoolbox \
  --enable-libmp3lame \
  --enable-libvorbis \
  --disable-ffplay --disable-network --disable-doc --disable-debug --disable-avdevice \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$PREFIX/include -mmacosx-version-min=$MIN_MACOS" \
  --extra-ldflags="-L$PREFIX/lib -mmacosx-version-min=$MIN_MACOS" >/dev/null
make -j"$JOBS" >/dev/null && make install >/dev/null

echo "==> Installing into Vendor/ffmpeg"
rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/LICENSES"
cp "$PREFIX/bin/ffmpeg" "$PREFIX/bin/ffprobe" "$OUT/bin/"
strip "$OUT/bin/ffmpeg" "$OUT/bin/ffprobe"
cp "$WORK/build/ffmpeg-$FFMPEG_VER/COPYING.LGPLv2.1" "$OUT/LICENSES/FFmpeg-LGPL-2.1.txt"
cp "$WORK/build/ffmpeg-$FFMPEG_VER/LICENSE.md"       "$OUT/LICENSES/FFmpeg-LICENSE.md"
cp "$WORK/build/lame-$LAME_VER/COPYING"              "$OUT/LICENSES/LAME-LGPL.txt"
cp "$WORK/build/libogg-$OGG_VER/COPYING"             "$OUT/LICENSES/libogg-BSD.txt"
cp "$WORK/build/libvorbis-$VORBIS_VER/COPYING"       "$OUT/LICENSES/libvorbis-BSD.txt"

echo "==> Self-check"
FF="$OUT/bin/ffmpeg"
"$FF" -hide_banner -L 2>&1 | grep -qi "Lesser General Public License" && echo "  license: LGPL ✓" || { echo "  license is NOT LGPL"; exit 1; }
"$FF" -hide_banner -buildconf 2>&1 | grep -q -- "--enable-gpl" && { echo "  GPL flag found!"; exit 1; } || true
for enc in libmp3lame flac alac aac_at libvorbis pcm_s16le pcm_s24le pcm_s16be; do
  "$FF" -hide_banner -encoders 2>/dev/null | grep -q " $enc " && echo "  encoder $enc ✓" || { echo "  encoder $enc missing"; exit 1; }
done
if otool -L "$FF" "$OUT/bin/ffprobe" | tail -n +2 | grep -v ':$' | grep -vE '/usr/lib/|/System/Library/'; then
  echo "  non-system library dependency found!"; exit 1
fi
echo "  only macOS system libraries ✓"
echo "Done: $OUT/bin"
