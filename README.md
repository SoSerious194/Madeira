<p align="center">
  <img src="docs/assets/banner.png" alt="Madeira — Bringing PC gaming to your iPhone." width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0--or--later-yellow?style=for-the-badge" alt="License: GPL-3.0-or-later"></a>
  &nbsp;&nbsp;&nbsp;
  <a href="https://github.com/willfaust/Madeira"><img src="https://img.shields.io/badge/Fork_of-willfaust%2FMadeira-555?style=for-the-badge&logo=github" alt="Fork of willfaust/Madeira"></a>
</p>

This is an independent fork of [Madeira](https://github.com/willfaust/Madeira),
which runs Windows PC games on an iPhone with no jailbreak. The games run
unmodified, inside a single iOS app.

The fork follows Madeira closely and adds its own features on top. The first
is **Couch mode**, a full-screen, controller-first library in the spirit of
Steam's Big Picture.

> [!IMPORTANT]
> This is **not the official Madeira**, and it is not affiliated with or
> endorsed by its authors. Please report problems with this fork
> [here](https://github.com/SoSerious194/Madeira/issues), not to the Madeira
> project or its Discord.

> [!NOTE]
> Madeira is an active research project, and so is this fork. Many games start
> and some play well, but performance and compatibility vary from game to game,
> and things change quickly. Expect rough edges.

## What this fork adds

### Couch mode

A full-screen library for playing with a controller, designed for landscape.
Turn it on in **Settings › Appearance › Couch mode**.

- **Home**: the focused game's artwork fills the screen behind its logo, its
  status and playtime. Below are shelves of covers: **Continue playing**,
  **Installed**, **Library** (Steam games not installed yet) and **Other
  games**.
- **Game page**: press A for **Play**, **Install** (with live download
  progress) or **Properties**, which opens Madeira's own per-game settings.
- **Guide**: press Start for Home, the standard Madeira library, Settings and
  JIT status.
- **Input**: D-pad or stick to move, A to select, B to go back. Each shelf
  remembers where you left it. A hardware keyboard and touch work too.
- **Orientation**: the app holds landscape while Couch mode is open, and goes
  back to normal when you leave it.

It's built from Madeira's own library, Steam and launch code, so games start
exactly as they do from the standard library. The design and status are in
[`docs/COUCH_MODE_PLAN.md`](docs/COUCH_MODE_PLAN.md).

### Fixes ahead of upstream

Some fixes from open [Madeira pull requests](https://github.com/willfaust/Madeira/pulls)
are merged here before upstream merges them, with their authors kept. One
example is a fix for a crash when the Steam connection drops mid-request. The
list is in [`docs/FORK.md`](docs/FORK.md#community-pull-requests-merged-here).

### Working on the interface without a device

- [`app/CouchPreview`](app/CouchPreview): Couch mode with sample games, in the
  iOS Simulator.
- [`app/MadeiraUIShell`](app/MadeiraUIShell): the whole app's real interface
  in the iOS Simulator, with the engine stubbed out. Games can't start in it.

## How this fork relates to Madeira

- **Changes from Madeira come in.** The fork regularly merges Madeira's `main`,
  so its engine work, game fixes and features arrive here too.
- **Changes from here don't go back.** This fork doesn't open pull requests
  against Madeira; it develops on its own.
- **Selected community fixes** from Madeira's open pull requests may be merged
  early, after review and a build check.

[`docs/FORK.md`](docs/FORK.md) records the upstream commit this fork is synced
to, which pull requests were merged early, and how to sync.

## How it works

| Layer | What it does |
|---|---|
| **[FEX-Emu](https://github.com/FEX-Emu/FEX)** | Translates the game's x86 and x86-64 code to ARM64 as it runs. |
| **[Wine](https://www.winehq.org/)** 11.4 | Provides Windows. It is built for ARM64EC, so Wine itself runs natively and only the game's own code is translated. 32-bit games run through WoW64. |
| **[DXMT](https://github.com/3Shain/DXMT)** | Draws Direct3D 9, 10 and 11 with Metal. |
| **[madeira-d3d12](madeira-d3d12)** | Madeira's own Direct3D 12 implementation on Metal, converting DXIL shaders at run time with Apple's Metal Shader Converter. |

iOS apps cannot start other programs, so everything runs in one process: even
Wine's server runs as a thread instead of a separate program.

## Features

- **Couch mode** (this fork): a controller-first, full-screen library, as
  described above.
- **Game library** with artwork, search and a Windows desktop session.
- **Steam**: sign in, browse the games you own, install and update them, and
  start them through Valve's own Windows Steam client (Madeira Dock).
- **Steam Cloud saves**: saves sync with Steam Cloud when Madeira starts and
  before a game starts, and **Upload saves and close Madeira** in the game
  menu sends them when you stop playing. Saves that changed on both sides are
  never overwritten without asking, and anything a sync replaces is backed up.
- **Controllers**: Bluetooth controllers through XInput, plus customisable
  on-screen touch controls.
- **Keyboard, mouse and trackpad** passed through to games as real input.
- **Video and audio** for cutscenes and music, through FFmpeg, VideoToolbox and AudioToolbox.

## Requirements

- An iPhone on **iOS 26 or later**, the only version Madeira currently runs
  on reliably. Development happens on recent Pro iPhones.
- **JIT**, which iOS only allows while a debugger is attached. Madeira can use
  [StikDebug](https://github.com/StikDebug/StikDebug) or its built-in StikJIT
  helper. On iOS 27 the built-in helper can pair the iPhone itself, without a
  computer.
- An **Apple ID** to sideload the app. A free account works; its signing
  expires after 7 days, so the app needs refreshing weekly. Your games and
  saves are kept across reinstalls.

Because JIT needs a debugger, Madeira cannot be offered on the App Store.

## Installing

This fork doesn't publish IPAs yet, so for now [build it from source](#building-from-source).
Madeira's official IPAs are on [its releases page](https://github.com/willfaust/Madeira/releases);
they don't include this fork's changes.

With an IPA:

1. Sideload it with your own Apple ID using SideStore, AltStore, Sideloadly,
   Plume or a similar tool.
2. Open Madeira and enable JIT. Automatic mode uses StikDebug when installed,
   otherwise it guides you through the built-in setup; see
   [JIT setup](docs/JIT.md).
3. In **Settings**, check that **JIT** and **Memory+** both show a green check:
   Madeira then says **Ready to play**.

Some 64-bit games need Microsoft's Visual C++ runtime, which is not included
(see [Licensing](#licensing)).

## Building from source

```sh
git clone --recurse-submodules https://github.com/SoSerious194/Madeira.git
```

`FEX`, `wine`, `dxmt` and `madeira-dock` are submodules that point at Madeira's
own forks; upstream checkouts will not build here. The build has several parts
(the Wine unix libraries, the ARM64EC Windows modules, FEX, DXMT and the app)
and some inputs that are not in the repository, such as the toolchains.
[`docs/BUILDING.md`](docs/BUILDING.md) walks through all of it.

For interface work only, [`app/MadeiraUIShell`](app/MadeiraUIShell/README.md)
and [`app/CouchPreview`](app/CouchPreview/README.md) build in a few minutes
with Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen), and need
none of the engine build.

### Repository layout

| Path | Contents |
|---|---|
| [`app/`](app) | The iOS app: SwiftUI front end, Wine bridge and bundled resources |
| [`app/Madeira/CouchMode/`](app/Madeira/CouchMode) | Couch mode (this fork); `Live/` connects it to the app |
| [`app/CouchPreview/`](app/CouchPreview), [`app/MadeiraUIShell/`](app/MadeiraUIShell) | Simulator builds for interface work (this fork) |
| [`wine/`](https://github.com/willfaust/wine), [`FEX/`](https://github.com/willfaust/FEX), [`dxmt/`](https://github.com/willfaust/dxmt), [`madeira-dock/`](https://github.com/willfaust/madeira-dock) | Madeira's forks and the Steam client launcher (submodules) |
| [`madeira-d3d12/`](madeira-d3d12) | The native Direct3D 12 runtime |
| [`build/`](build) | Build scripts and iOS-side sources, one folder per component |
| [`tests/`](tests) | Host checks and x86, x86-64 and DXMT test programs |
| [`tools/`](tools) | Helper scripts |
| [`docs/`](docs) | Documentation |
| [`research/`](research) | Experiments that are not part of the app |

## Documentation

| Topic | Document |
|---|---|
| This fork: upstream sync and merged pull requests | [`docs/FORK.md`](docs/FORK.md) |
| Couch mode: design, status and plans | [`docs/COUCH_MODE_PLAN.md`](docs/COUCH_MODE_PLAN.md) |
| Building from a clean checkout | [`docs/BUILDING.md`](docs/BUILDING.md) |
| StikDebug and built-in JIT setup | [`docs/JIT.md`](docs/JIT.md) |
| The game library | [`docs/LIBRARY.md`](docs/LIBRARY.md) |
| Steam sign-in, library and downloads | [`docs/STEAM_SIGNIN.md`](docs/STEAM_SIGNIN.md), [`docs/STEAM_LIBRARY.md`](docs/STEAM_LIBRARY.md) |
| Steam Cloud saves | [`docs/STEAM_CLOUD.md`](docs/STEAM_CLOUD.md) |
| Madeira Dock (the Steam client) | [`docs/MADEIRA_DOCK.md`](docs/MADEIRA_DOCK.md) |
| 32-bit games (WoW64) | [`docs/WOW64.md`](docs/WOW64.md) |
| Controllers and touch controls | [`docs/CONTROLLERS.md`](docs/CONTROLLERS.md) |
| Keyboard, mouse and trackpad | [`docs/KEYBOARD_MOUSE.md`](docs/KEYBOARD_MOUSE.md) |
| Audio and video | [`docs/MEDIA.md`](docs/MEDIA.md) |
| Licensing in detail | [`docs/LICENSING.md`](docs/LICENSING.md) |

## Licensing

This fork is a modified version of Madeira. It is distributed under the same
terms as Madeira: **GPL-3.0-or-later** ([`LICENSE`](LICENSE)) with the
**Madeira Converter Exception** ([`LICENSE-EXCEPTION.md`](LICENSE-EXCEPTION.md)),
an additional permission that allows it to work with Apple's Metal Shader
Converter. The fork's own changes are under the same terms. They are listed in
[`docs/FORK.md`](docs/FORK.md), and the git history records each one.

The projects Madeira builds on keep their own licenses upstream, but Madeira's
forks are not all licensed the same way as their upstreams:

| Component | License |
|---|---|
| [Wine fork](https://github.com/willfaust/wine) | LGPL-2.1-or-later, like upstream Wine |
| [FEX-Emu fork](https://github.com/willfaust/FEX), [DXMT fork](https://github.com/willfaust/dxmt) | Upstream code stays MIT; Madeira's changes are GPL-3.0-or-later with the exception |
| [rpmalloc fork](https://github.com/willfaust/rpmalloc) | Upstream code stays 0BSD; Madeira's changes are GPL-3.0-or-later with the exception |
| [Madeira Dock](https://github.com/willfaust/madeira-dock) | GPL-3.0-or-later with the exception |

Anything obtained earlier under a permissive license stays available under it.
Per-component details, including GnuTLS, Nettle, GMP, FFmpeg and LLVM, are in
[`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md); the license texts are in
[`LICENSES/`](LICENSES).

Microsoft's Visual C++ runtime DLLs are **not** distributed with Madeira. To
build with them, supply them yourself as described in
[`tools/fetch-vcruntime.md`](tools/fetch-vcruntime.md).

## Contributing

Issues and pull requests for this fork are welcome
[here](https://github.com/SoSerious194/Madeira), under GPL-3.0-or-later; see
[`CONTRIBUTING.md`](CONTRIBUTING.md). Changes to Madeira itself belong in
[Madeira's repository](https://github.com/willfaust/Madeira).

Madeira's forks contain a lot of AI-assisted work. FEX-Emu does not accept
AI-generated code, so please **do not send changes from these forks upstream**
to FEX-Emu, and check each upstream project's contribution policy before
proposing anything to it.

## Credits

This fork:

- **SoSerious194** ([@SoSerious194](https://github.com/SoSerious194)):
  maintains this fork; Couch mode
- The authors of the Madeira pull requests merged here, credited on their
  commits and in [`docs/FORK.md`](docs/FORK.md)

Madeira:

- **Will Faust** ([@willfaust](https://github.com/willfaust)): created Madeira
- **Nick** ([@125hz](https://github.com/125hz)): 32-bit game support, the game library and Madeira Dock
- **Jfishin** ([@Jfishin](https://github.com/Jfishin)): the original native Steam sign-in, library and downloads
- **Jesse** ([@JesseLovelace](https://github.com/JesseLovelace)): Steam Cloud saves, faster game launches, and fixes that let more games run
- **Dan Perks** ([@danperks](https://github.com/danperks)): in-app JIT without StikDebug, and pairing without a computer
- **bahacan16** ([@bahacan16](https://github.com/bahacan16)): Direct3D 12 and DXMT fixes, game launcher windows, per-game settings, PlayStation controllers, and save backups
- **spitefulowl** ([@spitefulowl](https://github.com/spitefulowl)): Wine and FEX runtime fixes, DXMT texture and memory fixes, audio, the swap tier, and library launch options
- **meshoklv** ([@meshoklv](https://github.com/meshoklv)): controller fixes for games that ship their own XInput or need focus, touch taps that stay off the mouse, and a crash-guard fix
- **TheHadesc** ([@TheHadesc](https://github.com/TheHadesc)): Madeira Dock starts for games whose Steam launch entries do not start at zero, and a touch gamepad that survives the in-game keyboard

Madeira is built on [Wine](https://www.winehq.org/), [FEX-Emu](https://github.com/FEX-Emu/FEX),
[DXMT](https://github.com/3Shain/DXMT) by Feifan He (3Shain) with the Direct3D 9
frontend by David Acevedo (dacevedo12), [rpmalloc](https://github.com/mjansson/rpmalloc)
by Mattias Jansson, [StikDebug](https://github.com/StikDebug/StikDebug),
[StikJIT](https://github.com/StikDebug/StikJIT) and
[idevice](https://github.com/jkcoxson/idevice) for enabling JIT. Thank you to everyone who contributes to them.
