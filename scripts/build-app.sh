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

# Apple silicon refuses to run unsigned binaries. An ad hoc signature is enough for local use.
codesign --force --sign - "$APP"

echo "Done. Start the app with: open $APP"
