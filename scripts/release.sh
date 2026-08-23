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

# The app icon comes from the iconset. The menu bar images live in the
# resource bundle that swift build makes for the executable target.
iconutil -c icns Design/upto.iconset -o "$APP/Contents/Resources/AppIcon.icns"
cp -R "$BIN_DIR/upto_upto.bundle" "$APP/Contents/Resources/"

# Apple silicon refuses to run unsigned binaries. An ad hoc signature is enough.
codesign --force --sign - "$APP"

# The DMG opens as a styled drag install window. Finder reads the layout
# from the .DS_Store template that scripts/author-dmg-layout.sh saved.
# The volume name and the background path must not change, because the
# template points at both.
STAGE="build/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/.background"
cp -R "$APP" "$STAGE/upto.app"
ln -s /Applications "$STAGE/Applications"
cp Design/dmg/background.tiff "$STAGE/.background/background.tiff"
cp Design/dmg/DS_Store "$STAGE/.DS_Store"
iconutil -c icns Design/upto.iconset -o "$STAGE/.VolumeIcon.icns"

# Build read write first, flag the custom volume icon, then compress.
DMG="build/upto-$VERSION.dmg"
RW_DMG="build/upto-rw.dmg"
MOUNT_DIR="build/dmg-mount"
rm -f "$DMG" "$RW_DMG"
hdiutil create -volname "upto" -srcfolder "$STAGE" -ov -format UDRW "$RW_DMG"
hdiutil attach -readwrite -noverify -nobrowse -mountpoint "$MOUNT_DIR" "$RW_DMG"
xcrun SetFile -a C "$MOUNT_DIR"
hdiutil detach "$MOUNT_DIR"
hdiutil convert "$RW_DMG" -format UDZO -o "$DMG"
rm -f "$RW_DMG"

ZIP="build/upto-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo ""
echo "Done."
echo "Architectures: $(lipo -archs "$APP/Contents/MacOS/upto") ($ARCH_NOTE)"
echo "Artifacts:"
shasum -a 256 "$DMG" "$ZIP"
