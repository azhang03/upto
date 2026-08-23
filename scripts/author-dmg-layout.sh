#!/bin/bash
# Writes the Finder layout template for the release DMG.
#
# The styled DMG window comes from a .DS_Store file that Finder writes.
# This script builds a scratch read write DMG, tells Finder to lay out
# the window, and saves the result to Design/dmg/DS_Store. Run it once
# after a change to the window geometry or the icon positions. The
# release script copies the saved file into every DMG it builds.
#
# Keep the volume name "upto" and the background path
# .background/background.tiff stable. The saved layout points at both.
set -euo pipefail

cd "$(dirname "$0")/.."

VOLNAME="upto"
VOL="/Volumes/$VOLNAME"

if [ -e "$VOL" ]; then
    echo "A volume named $VOLNAME is already mounted. Eject it first." >&2
    exit 1
fi

# Stage the same content a release stages, so the layout matches.
if [ ! -d build/upto.app ]; then
    scripts/build-app.sh
fi
if [ ! -f Design/dmg/background.tiff ]; then
    swift Design/dmg/render-background.swift
fi

STAGE="build/dmg-author-stage"
SCRATCH="build/dmg-author.dmg"
rm -rf "$STAGE"
rm -f "$SCRATCH"
mkdir -p "$STAGE/.background"
cp -R build/upto.app "$STAGE/upto.app"
ln -s /Applications "$STAGE/Applications"
cp Design/dmg/background.tiff "$STAGE/.background/background.tiff"

# The release DMG also carries a volume icon. Stage one here so its
# position gets recorded with the others.
iconutil -c icns Design/upto.iconset -o "$STAGE/.VolumeIcon.icns"

hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDRW "$SCRATCH"
hdiutil attach -readwrite -noverify "$SCRATCH"

# Let Finder draw the window and record the layout. The window bounds
# add 28 points of title bar to the 660 by 420 background art.
osascript <<'OSA'
tell application "Finder"
    tell disk "upto"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 860, 568}
        set viewOpts to the icon view options of container window
        set arrangement of viewOpts to not arranged
        set icon size of viewOpts to 128
        set background picture of viewOpts to file ".background:background.tiff"
        set position of item "upto.app" to {165, 195}
        set position of item "Applications" to {495, 195}
        -- Park the support files far below the window edge. Most Macs
        -- hide them. A Mac set to show hidden files still gets a clean
        -- window this way.
        repeat with hiddenName in {".background", ".fseventsd", ".VolumeIcon.icns", ".DS_Store"}
            try
                set position of item (hiddenName as text) to {330, 700}
            end try
        end repeat
        update without registering applications
        delay 2
        close
    end tell
end tell
OSA

# Finder writes the .DS_Store shortly after the window closes. Wait for
# the background and position records before saving the file.
check_layout() {
    python3 -c 'import sys
d = open(sys.argv[1], "rb").read()
sys.exit(0 if b"icvp" in d and b"Iloc" in d else 1)' "$VOL/.DS_Store" 2>/dev/null
}

sync
for _ in $(seq 1 15); do
    if check_layout; then
        break
    fi
    sleep 1
done

# Finder sometimes holds the file until the volume unmounts. In that
# case detach, attach again, and read the flushed file.
if ! check_layout; then
    hdiutil detach "$VOL"
    hdiutil attach -readwrite -noverify "$SCRATCH"
    sleep 2
fi

if ! check_layout; then
    echo "Finder did not write the layout. Try again." >&2
    hdiutil detach "$VOL"
    exit 1
fi

cp "$VOL/.DS_Store" Design/dmg/DS_Store
hdiutil detach "$VOL"
rm -f "$SCRATCH"
rm -rf "$STAGE"

echo "Saved Design/dmg/DS_Store"
