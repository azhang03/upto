# upto

upto is a macOS app that sets a custom Discord Rich Presence. It is built with SwiftUI.

CustomRP for Windows inspired this project. upto is not a port. It is a new app made for the Mac.

## Status

Early development. There is no release yet.

## Planned features

- Edit all Rich Presence fields: details, state, images, tooltips, timestamps, party data, and buttons
- Show a live preview of the presence
- Save presets and switch between them
- Control the app from the menu bar
- Support Discord custom widgets (later phase)

## Requirements

- macOS 14 Sonoma or later

## Build from source

You need macOS 14 or later and the Xcode Command Line Tools.

1. Clone the repository.
2. Run `./scripts/build-app.sh`.
3. Open `build/upto.app`.

The build is not signed with a developer certificate. When you open the app for the first time, right-click it and select Open.
