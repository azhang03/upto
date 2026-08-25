#!/bin/bash
# Builds the release binary and packages it as build/upto.app.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release

APP="build/upto.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/upto "$APP/Contents/MacOS/upto"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# The app icon comes from the iconset. The menu bar images live in the
# resource bundle that swift build makes for the executable target.
iconutil -c icns Design/upto.iconset -o "$APP/Contents/Resources/AppIcon.icns"
cp -R .build/release/upto_upto.bundle "$APP/Contents/Resources/"

# swift build makes that bundle without an Info.plist. macOS 26.5.1 and
# newer refuse to load a bundle that has none, and the app then crashes
# at launch. Write a minimal one.
cat > "$APP/Contents/Resources/upto_upto.bundle/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleIdentifier</key>
	<string>io.github.azhang03.upto.resources</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>upto_upto</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
</dict>
</plist>
PLIST

# Apple silicon refuses to run unsigned binaries. An ad hoc signature is enough for local use.
codesign --force --sign - "$APP"

echo "Done. Start the app with: open $APP"
