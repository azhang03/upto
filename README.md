<div align="center">

<h1>upto</h1>

<img src="docs/images/app-icon.png" width="128" alt="The upto app icon, a green cross on a dark square">

<p><b>Custom Discord Rich Presence for the Mac.</b><br>
A native SwiftUI app.</p>

<p>
<a href="https://github.com/azhang03/upto/releases"><img src="https://img.shields.io/github/v/release/azhang03/upto?style=flat&labelColor=23262C&color=6ED0B1" alt="Latest release"></a>
<img src="https://img.shields.io/badge/macOS-14%2B-6ED0B1?style=flat&labelColor=23262C&logo=apple&logoColor=F2F3F4" alt="Runs on macOS 14 or later">
<img src="https://img.shields.io/badge/Apple%20silicon-arm64-6ED0B1?style=flat&labelColor=23262C" alt="Built for Apple silicon">
<img src="https://img.shields.io/badge/SwiftUI-native-6ED0B1?style=flat&labelColor=23262C&logo=swift&logoColor=F2F3F4" alt="Built with SwiftUI">
<a href="LICENSE"><img src="https://img.shields.io/github/license/azhang03/upto?style=flat&labelColor=23262C&color=6ED0B1" alt="MIT license"></a>
</p>

<img src="docs/images/editor-activity.png" width="760" alt="The main upto window with the presets row, the tabbed editor, and the live preview">

</div>

upto sets a custom Rich Presence on your Discord profile. You fill in the fields, press Push, and Discord shows your status. CustomRP for Windows inspired this project. upto is not a port. It is a new app made for the Mac, and it is in early development.

## Features

<table>
<tr>
<td width="50%">🎛️ <b>Full editor</b><br>Edit details, state, images with tooltips, timestamps, party size, and buttons.</td>
<td width="50%">👀 <b>Live preview</b><br>See the presence as Discord shows it, for every activity type.</td>
</tr>
<tr>
<td width="50%">📁 <b>Presets</b><br>Save setups, switch with one click, and share them as <code>.upto</code> files.</td>
<td width="50%">📍 <b>Menu bar</b><br>Start, stop, and switch presets without opening the window.</td>
</tr>
<tr>
<td width="50%">🚀 <b>Automation</b><br>Launch at login, connect on start, and reconnect when Discord restarts.</td>
<td width="50%">🧹 <b>Clean uninstall</b><br>One button in Settings removes the app and every file it made.</td>
</tr>
</table>

You can also override the app name that Discord displays. Support for Discord custom widgets is planned for a later phase.

## A closer look

<table>
<tr>
<td align="center"><img src="docs/images/timing-calendar.png" width="470" alt="The Timing tab with the themed calendar popover open"><br><sub>Pick timestamps in the themed calendar.</sub></td>
<td align="center"><img src="docs/images/about.png" width="345" alt="The upto About window"><br><sub>The About window.</sub></td>
</tr>
</table>

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

## License

MIT. See [LICENSE](LICENSE).
