#!/bin/zsh
# Builds a release copy of Travaso and installs it in /Applications.
# Run ./Scripts/build-ffmpeg.sh once first (it creates Vendor/ffmpeg).
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/build/DerivedData/Build/Products/Release/Travaso.app"

[[ -x "$ROOT/Vendor/ffmpeg/bin/ffmpeg" ]] || { echo "FFmpeg not built yet: run ./Scripts/build-ffmpeg.sh"; exit 1; }

echo "==> Building Travaso (Release)"
xcodebuild -project "$ROOT/Travaso.xcodeproj" -scheme Travaso -configuration Release \
  -derivedDataPath "$ROOT/build/DerivedData" clean build -quiet
codesign --verify --deep --strict "$APP"

echo "==> Installing to /Applications"
pkill -x Travaso 2>/dev/null || true
rm -rf /Applications/Travaso.app
ditto "$APP" /Applications/Travaso.app
# Make Finder and the Dock pick up a changed icon.
touch /Applications/Travaso.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Travaso.app
echo "Done: /Applications/Travaso.app"
