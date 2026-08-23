# Changelog

## 0.2.0 - 2026-08-23

The look and feel release. The app now has its own visual identity.

### Added

- App icon and menu bar icons
- Uninstall button in Settings. It removes the app and every file the app made. The app and your presets go to the Trash.
- Themed calendar popover for timestamps
- Character counters on text fields
- About window
- Tooltips on the header and preset buttons

### Changed

- Full visual redesign: dark theme, custom header, preset chips, a tabbed editor, and a restyled preview
- The Update button is now named Push
- The DMG opens as a styled drag install window
- Preset errors now show under the presets row instead of failing silently

### Fixed

- The Application ID field showed an empty value while the app was connected

### Known limitations

- The app is not signed. macOS blocks the first launch. The README explains the fix.
- The build runs on Apple silicon only.
- The app sets one presence at a time.

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
