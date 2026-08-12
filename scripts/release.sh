#!/bin/bash
# Builds the release artifacts for a GitHub release: a DMG and a zip.
# The version comes from Resources/Info.plist.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
echo "Building upto $VERSION"

# Try a universal build first. Older command line tools may not have the
# x86_64 slice. In that case build for arm64 only and say so.
ARCH_FLAGS=(--arch arm64 --arch x86_64)
ARCH_NOTE="universal (arm64 + x86_64)"
if ! swift build -c release "${ARCH_FLAGS[@]}"; then
    echo ""
    echo "Universal build failed. Falling back to arm64 only."
    echo "Note this in the release notes: the build runs on Apple silicon only."
    echo ""
    ARCH_FLAGS=(--arch arm64)
    ARCH_NOTE="arm64 only"
    swift build -c release "${ARCH_FLAGS[@]}"
fi

# Builds with explicit arch flags land in a different folder than plain
# builds, so ask swift for the real path.
BIN_DIR=$(swift build -c release "${ARCH_FLAGS[@]}" --show-bin-path)

APP="build/upto.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/upto" "$APP/Contents/MacOS/upto"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Apple silicon refuses to run unsigned binaries. An ad hoc signature is enough.
codesign --force --sign - "$APP"

# The DMG shows the app next to an Applications shortcut for drag installs.
STAGE="build/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/upto.app"
ln -s /Applications "$STAGE/Applications"

DMG="build/upto-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "upto" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

ZIP="build/upto-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo ""
echo "Done."
echo "Architectures: $(lipo -archs "$APP/Contents/MacOS/upto") ($ARCH_NOTE)"
echo "Artifacts:"
shasum -a 256 "$DMG" "$ZIP"
