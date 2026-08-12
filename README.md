# upto

upto is a macOS app that sets a custom Discord Rich Presence. It is built with SwiftUI.

CustomRP for Windows inspired this project. upto is not a port. It is a new app made for the Mac.

## Status

Early development. The current release is 0.1.0.

## Features

- Edit every Rich Presence field: details, state, images with tooltips, timestamps, party size, and buttons
- See a live preview that matches how Discord shows each activity type
- Override the app name that Discord displays
- Save presets, switch between them, and share them as `.upto` files
- Start, stop, and switch presets from the menu bar
- Launch at login and connect on start
- Reconnect on its own when Discord restarts

Planned for a later phase: support for Discord custom widgets.

## Requirements

- macOS 14 Sonoma or later
- A Mac with Apple silicon
- The Discord desktop app

## Install

1. Download `upto-<version>.dmg` from the [Releases](https://github.com/azhang03/upto/releases) page.
2. Open the DMG.
3. Drag upto into the Applications folder. Do not run the app from inside the DMG window.
4. Open upto from Applications. macOS blocks the first launch because the app is not signed.
5. Open System Settings, then Privacy & Security. Scroll down and click "Open Anyway". Confirm the dialog.

You only do the last step once. Each release also has a zip file if you prefer that over a DMG.

## Build from source

You need macOS 14 or later and the Xcode Command Line Tools.

1. Clone the repository.
2. Run `./scripts/build-app.sh`.
3. Open `build/upto.app`.

An app you build yourself opens without the security prompt.
