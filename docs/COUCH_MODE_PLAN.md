# Couch mode: a Big Picture-style frontend for Madeira

Plan for a personal fork. Written 2026-10-23 against Madeira `279fd0f`
(2026-10-15).

## 1. Can the app be built without rebuilding Wine, FEX and DXMT?

**Partly. The Windows-side DLLs are already in git, but the native engine
must be built once.**

| Piece | Where it lives | Needs building? |
|---|---|---|
| Wine PE DLLs, FEX `xtajit64.dll`, DXMT `winemetal.dll`/`d3d11.dll`, `d3d12.dll` | `app/Madeira/arm64ec-windows/` (tracked) | No |
| GnuTLS / Nettle / GMP static libs | `app/Madeira/*.a` (tracked) | No |
| FEXCore (iOS) | `libFEXCore*.a`, `libJemallocLibs.a`, `External/*` | **Yes**: `build/fex-ios/build.sh` |
| Wine unix side | `libntdll_unix.a`, `libwineserver.a`, `libwin32u_unix.a` | **Yes**: `build/ntdll-unix`, `build/wineserver`, `build/win32u-unix` |
| DXMT unix side | `libdxmt_combined.a` | **Yes**: `build/dxmt-ios/build.sh`. This needs **LLVM built for iOS first**, which takes hours. |
| FFmpeg | `libav*.a`, `libswresample.a` | **Yes**: `build/ffmpeg/build.sh` |
| In-app JIT pairing | `libmadeira_rppairing.a` | **Yes**: `build/rppairing-ios/build.sh` (Rust) |
| VC++ runtime DLLs | `app/Madeira/x86_64-vcruntime/` | Copy from Microsoft's `vc_redist.x64.exe` |

**The engine in a release IPA can't be reused.** These native libraries are
linked statically into the same Mach-O executable as the SwiftUI code. There's
no separate engine file to lift out of the IPA, so any change to the UI means
relinking the whole binary.

**Good news:**

- The submodule commits are pushed. The pinned FEX, wine, dxmt and
  madeira-dock commits equal the heads of their branches on github.com/willfaust,
  so `git submodule update --init` works.
- The native libraries only need rebuilding when a submodule moves. After the
  first build, a UI change is just an Xcode build.
- A community repo, **Aettarrass-sys/madeira-bcd**, has a working GitHub
  Actions workflow, `.github/workflows/build-ipa.yml` (1,240 lines). It builds
  the whole IPA from source on a `macos-15` runner, LLVM-for-iOS included, with
  caches. Its cached runs took about 15–20 minutes. It last ran on 2026-09-30
  against an older Madeira, so it will need updating.

**Constraints on this Mac** (M3, 8 cores, 16 GB RAM, Xcode 27.0):

- **Only about 32 GB of disk is free.** LLVM-for-iOS plus the Wine and FEX
  build trees likely won't fit comfortably.
- **bison is 2.3.** Wine's tools need bison 3: `brew install bison`.
- **Ninja and meson are missing:** `brew install ninja meson`.
- Upstream says **Debug** is the configuration that runs games; Release builds
  have crashed the guest.
- Madeira can't run in the iOS Simulator, because the engine is iphoneos-only
  and needs JIT. Testing the real thing needs a device.

### Recommended build route

1. **Design the UI in the Simulator with mock data (now).** Write the Couch
   mode views so they take plain data and actions (section 4). Then a small
   preview app, or Xcode Previews, renders them with fake games and real Steam
   CDN artwork. You don't need the engine for this, and it iterates fastest.
2. **Build real IPAs in CI (soon).** Fork Madeira on GitHub and adapt
   madeira-bcd's `build-ipa.yml` to the current upstream. Then every push
   produces an unsigned IPA artifact to sideload with SideStore or Sideloadly.
   This uses no local disk, and public repos get free macOS runner minutes.
3. **Build locally only if you free up disk (optional).** Follow
   `docs/BUILDING.md` steps 1–6 once. After that, the edit → build → install
   loop on a cable-connected iPhone is the quickest.

## 2. What Madeira already provides (the seams to build on)

| Need | Existing piece | File |
|---|---|---|
| Controller navigation events | `LibraryController.shared.commands` publishes `up/down/left/right/accept/back/add/menu/tab` from player 1's pad (D-pad and left stick, A, B, Y, Start, shoulders) | `Library.swift:93` |
| Choosing which interface starts | `FrontendChoice` (library or developer UI), stored in UserDefaults | `Library.swift:138` |
| Where the interface is chosen | `if library.enabled { LibraryView(play:enableJIT:startDock:) }` | `ContentView.swift:1291` |
| Games you added | `LibraryModel.shared.entries: [LibraryEntry]` (title, exe, lastPlayed, art) | `Library.swift:168`, `:607` |
| Installed Steam games | `SteamGamesModel.shared.games: [DockGame]` | `SteamGames.swift:357` |
| Owned Steam games, playtime, downloads | `SteamOwnedLibrary.shared` (`owned`, `playtime`, `downloads`, `install(_:)`, `signedIn`) | `SteamOwnedLibrary.swift:182` |
| Artwork | `SteamCatalog.cover(id)` (600×900), `SteamCatalog.hero(id)` (library hero); `SteamOwnedGame.libraryHero/libraryCapsule/headerImage` | `Library.swift:1592`, `SteamGames.swift:170` |
| Launching | `play(LibraryEntry)` for games you added, `startDock(DockGame, compactPool)` for Steam games | `ContentView.swift` |
| In-game menu | Back+Start already opens Madeira's session menu | `Library.swift:120` |

Upstream changes fast: 88 commits touched `Library.swift` or `ContentView.swift`
between Oct 1 and Oct 15. **Keep Couch mode in its own files** and touch
upstream files in only two places, so rebasing on upstream stays painless.

## 3. What Couch mode looks like

A full-screen, landscape, dark interface driven entirely by the controller.
It's inspired by Big Picture's layout but uses no Valve branding or assets
other than each game's own Steam artwork, which Madeira already loads.

**Home**

- **Hero:** the focused game's `library_hero` image fills the background, with
  a soft gradient. It shows the title, "Last played 2 days ago · 14 hrs" and
  install state.
- **Shelves** (horizontal rows of 600×900 covers):
  1. *Continue playing*: Steam and added games, sorted by last played.
  2. *Installed*.
  3. *Library*: owned but not installed, with a download badge or progress ring.
  4. *Other games*: the games you added.
- The focused cover scales up to about 1.08× with a glow. Moving the focus
  scrolls its shelf, and the hero fades over to the new game.

**Game page** (A on a cover)

- A big hero and logo, then **Play / Install / Resume download**.
- Rows for playtime, Steam Cloud status and size.
- A per-game settings row that opens Madeira's existing settings sheet.

**Guide overlay** (Start, or the Back+Start chord in game)

- Library, Settings, JIT status, Switch to touch library, and Quit game when
  in a session.

**Top bar:** clock, battery, controller glyph and the JIT status dot (green
means ready).

**Controls:** D-pad/stick move · A select · B back · Y search · LB/RB switch
tabs (Home / Library / Settings) · Start opens the guide.

**Bonus:** if the iPhone is connected to a TV over USB-C to HDMI or AirPlay,
show Couch mode on the external screen (a later phase).

## 4. Code layout

New folder `app/Madeira/CouchMode/`:

```
CouchMode/
  CouchModel.swift        // builds shelves from LibraryModel + SteamGamesModel + SteamOwnedLibrary
  CouchGame.swift         // one item: id, title, art URLs, state, playtime, action
  CouchFocus.swift        // 2-D focus (shelf, index), driven by LibraryController.commands
  CouchHomeView.swift     // hero + shelves
  CouchShelf.swift        // one horizontal row (ScrollViewReader keeps focus visible)
  CouchCover.swift        // cover card with focus scale/glow, badges, progress ring
  CouchGamePage.swift     // details + Play/Install
  CouchGuide.swift        // overlay menu
  CouchPreviewData.swift  // mock games for Simulator/Previews
```

Key design rule: **views take a `CouchGame` value and closures, never the
singletons directly.** Only `CouchModel` talks to Madeira's models. That's
what makes Simulator previews possible without the engine.

```swift
struct CouchGame: Identifiable, Hashable {
    enum Source: Hashable { case steam(appID: Int), added(UUID) }
    enum State: Hashable { case installed, notInstalled, downloading(Double) }
    let id: String
    let source: Source
    let title: String
    let cover: URL?      // library_600x900
    let hero: URL?       // library_hero
    let state: State
    let lastPlayed: Date?
    let playtime: String?
}
```

**Changes to upstream files, as built in phase 2 (three small edits plus the project file):**

1. `ContentView.swift`: `LibraryView(…)` is wrapped in
   `CouchModeSwitch(play: launchLibraryEntry, enableJIT: enableJIT) { LibraryView(…) }`.
   It shows Couch mode while the `madeiraCouchMode` setting is on, and the
   library otherwise.
2. `Library.swift`, Settings › Appearance: one line adds
   `CouchModeSettingsSection()`, the Couch mode toggle.
3. `MadeiraApp.swift`: one `@UIApplicationDelegateAdaptor(MadeiraAppDelegate.self)`
   line. The delegate's `supportedInterfaceOrientationsFor` holds landscape
   while Couch mode shows (`CouchMode/Live/CouchOrientation.swift`) and
   otherwise returns Info.plist's orientations, so nothing else changes.
4. `Madeira.xcodeproj`: a `CouchMode` group (with `Live`) in the app target.

This replaced the `FrontendChoice` idea. That choice applies at the next
start, whereas the switch applies at once, and the guide's **Madeira library**
item flips straight back to the standard library and all of its settings.

`CouchMode/Live/CouchModeHost.swift` is the only file that knows Madeira's
models. It does the following:

- builds `CouchGame`s from `SteamGamesRules.items` (installed plus owned),
  `SteamOwnedLibrary.downloads` and `.playtime`, and `LibraryModel.entries`;
- starts games through ContentView's `launchLibraryEntry`, which handles both
  Steam games (through Dock) and added ones;
- installs through `SteamOwnedLibrary.install`;
- opens `LibraryDetail` for Properties;
- shows `LibraryModel.error`, `jitNotice` and `restartNotice`, plus Steam
  errors, as a banner;
- maps a hardware keyboard to commands as well as the pad.

## 5. Phases

**Phase 1 status (2026-10-23): built and checked in the iOS Simulator
(iPhone 18 Pro, iOS 27).** `app/Madeira/CouchMode/` holds the shared views:
`CouchGame`, `CouchFocus`, `CouchImage`, `CouchParts`, `CouchHomeView`,
`CouchGamePage` and `CouchGuide`. `app/CouchPreview/` is the mock-data host;
its README says how to run it.

Checked in the Simulator:
- Hero cross-fade and logo per game.
- Shelf focus by tap and arrow keys, with each shelf remembering its column.
- Game page with Install, live download progress, and Back.
- Guide open and select.
- Focus following a game to Installed when its download finishes.

Not checked yet: a real controller (only keyboard, touch and the launch
script were used), and an actual device.

**Phase 2 status (2026-10-23): wired into Madeira and checked in the
Simulator through `app/MadeiraUIShell`.** That's Madeira's real app with the
engine stubbed (see its README), seeded with the same 18 games.

Checked:
- Couch mode shows the library's real entries (Continue playing, Other games).
- A game's page opens.
- Properties opens Madeira's own Game details.
- Guide › Madeira library switches back to the standard library at once.

Not checked:
- Steam shelves with a real signed-in account.
- Play and Install end to end, which need the engine, a device and JIT.
- A real controller.

Madeira's library tracks playtime only for Steam games, so added games show
"—".

| Phase | Result | Needs a device build? |
|---|---|---|
| 0 | Fork on GitHub, CI producing an IPA from unmodified upstream, sideloaded and launching a game | Yes (CI) |
| 1 ✅ | `CouchGame`, mock data, Home with hero + shelves + focus, game page, guide, running in the Simulator | No |
| 2 ✅ (Simulator) | `CouchModeHost` wired to the real models, Play/Install/Properties through Madeira's own paths, the Couch mode switch | Yes, still to verify on a device |
| 3 | Game page, install/download progress, guide overlay, search | Yes |
| 4 | Polish: transitions, sounds, haptics, external display, Reduce Motion | Yes |

## 6. Risks

- **Upstream churn.** Rebase often; the two-hook design keeps conflicts small.
- **The CI workflow is a stranger's.** Read all 1,240 lines before running it,
  check exactly which URLs it downloads from, and pin the action versions.
- **Memory.** Couch mode runs while no game is running and is torn down during
  a session, like `LibraryView`. Keep image caches bounded so it doesn't
  compete with the JIT pool.
- **Licensing.** Madeira is GPL-3.0-or-later. A fork for your own phone is fine.
  If you ever share builds, ship the source too.
