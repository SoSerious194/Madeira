# Madeira UI shell

Builds Madeira's own app (`app/Madeira`) for the **iOS Simulator** with the
engine replaced by `EngineStubs.m`. All the screens are the real ones: the
library, Settings, the Steam sign-in and the game sheets. Games can't start.

It's for working on the interface without a device, an IPA or the engine
build (FEX, Wine, DXMT). It isn't a way to play.

## Run

`project.yml` leaves out Madeira's Metal shaders (the cards' ambient glow and
the liquid-metal look), because they need Xcode's Metal Toolchain. With it
installed (`xcodebuild -downloadComponent MetalToolchain`), remove the
`"*.metal"` exclude to get those effects too.

```sh
xcodegen
open MadeiraUIShell.xcodeproj
```

To skip first-run setup and fill the library with the same games as
`app/CouchPreview`, launch it once, then:

```sh
xcrun simctl spawn booted defaults write dev.madeira.uishell madeiraOnboardingRevision -int 3
python3 seed-library.py "$(xcrun simctl get_app_container booted dev.madeira.uishell data)/Documents"
```

## What's stubbed

`EngineStubs.m` answers every engine call with "not running" or a failure:

- FEX and the Wine server and process
- the display shim
- DXMT's frame pacing and the GPU meter
- winios.drv's window calls
- in-app JIT pairing
- liblzma, so Steam downloads fail

When Madeira calls a new engine function, the link fails with its name; add
a stub for it there.
