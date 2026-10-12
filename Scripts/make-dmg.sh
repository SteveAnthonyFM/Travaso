#!/bin/zsh
# Packages build/DerivedData/.../Travaso.app into build/Travaso-<version>.dmg
# (drag-to-Applications layout). Run after build-release.sh or the CI build step.
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/build/DerivedData/Build/Products/Release/Travaso.app"
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")}"
DMG="$ROOT/build/Travaso-$VERSION.dmg"
STAGE="$ROOT/build/dmg-stage"

[[ -d "$APP" ]] || { echo "Build the app first (xcodebuild ... Release)"; exit 1; }

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/Travaso.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Travaso" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
rm -rf "$STAGE"
echo "Created $DMG"
