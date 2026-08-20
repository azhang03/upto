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

# Apple silicon refuses to run unsigned binaries. An ad hoc signature is enough for local use.
codesign --force --sign - "$APP"

echo "Done. Start the app with: open $APP"
