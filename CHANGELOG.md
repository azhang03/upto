# Changelog

## 0.1.0 - 2026-08-11

First public release.

### Added

- Editor for every Rich Presence field: details, state, images with tooltips, timestamps, party size, and buttons
- Live preview that matches how Discord shows each activity type
- Override for the app name that Discord displays
- Presets with import and export as `.upto` files
- Menu bar controls to start, stop, and switch presets
- Launch at login and connect on start
- Automatic reconnect when Discord restarts

### Known limitations

- The app is not signed. macOS blocks the first launch. The README explains the fix.
- The build runs on Apple silicon only.
- The app sets one presence at a time.
