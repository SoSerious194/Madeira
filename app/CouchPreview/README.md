# Couch Preview

Runs Couch mode (`app/Madeira/CouchMode/`) in the iOS Simulator with mock
games, without Madeira's engine or JIT. Artwork comes from Steam's CDN. The
game states, playtimes and sizes are made up.

## Run

Needs Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). In this folder:

```sh
xcodegen
open CouchPreview.xcodeproj
```

Then pick an iPhone simulator and Run, and rotate it to landscape
(⌘← or ⌘→).

## Controls

| Input | Pad | Keyboard (Mac, in the Simulator) | Touch |
|---|---|---|---|
| Move | D-pad, left stick | Arrows | Tap a cover |
| Select / Play | A | Return, Space | Tap the focused cover |
| Back | B | Escape, Delete | B hint |
| Guide | Menu (Start) | Tab, M | Menu hint |

Click inside the Simulator window first so it gets the keyboard. A
controller paired with the Mac also reaches the Simulator.

To replay commands at launch, for screenshots or checks:

```sh
xcrun simctl launch --terminate-running-process booted dev.madeira.couchpreview \
  -couchScript "down,down,right,accept,accept"
```

## Files

- `CouchPreviewApp.swift`: hosts `CouchHomeView` with the mock store.
- `CouchPreviewStore.swift`: mock games, plus pretend Play and Install.
- `CouchPreviewInput.swift`: controller, keyboard and script input, mapped to
  `CouchCommand` the way `LibraryController` maps pads in Madeira.
