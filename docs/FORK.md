# This fork

[SoSerious194/Madeira](https://github.com/SoSerious194/Madeira) is an
independent fork of [willfaust/Madeira](https://github.com/willfaust/Madeira).
It takes in Madeira's changes, merges selected community fixes early, and adds
its own features. It doesn't send pull requests back to Madeira.

## Synced to

| Upstream | Commit | Date |
|---|---|---|
| willfaust/Madeira `main` | [`e3a88fd`](https://github.com/willfaust/Madeira/commit/e3a88fd) "Record wave 3's pull requests as merged" | 2026-10-23 |

The previous sync point was `279fd0f` (2026-10-15).

Update this table after each upstream merge.

## This fork's own changes

| Change | Where | Since |
|---|---|---|
| **Couch mode**: a full-screen, controller-first library | `app/Madeira/CouchMode/`; design in [`COUCH_MODE_PLAN.md`](COUCH_MODE_PLAN.md) | 2026-10-23 |
| Couch mode holds the app in landscape while it shows | `app/Madeira/CouchMode/Live/CouchOrientation.swift` | 2026-10-23 |
| Simulator builds for interface work | `app/CouchPreview/`, `app/MadeiraUIShell/` | 2026-10-23 |
| README and this file describe the fork | `README.md`, `docs/FORK.md` | 2026-10-23 |

### Where the fork touches Madeira's own files

Upstream merges can only conflict with the fork in these places. Keep the
list current when you add more.

| File | Change |
|---|---|
| `app/Madeira/ContentView.swift` | `LibraryView(…)` is wrapped in `CouchModeSwitch(play:enableJIT:) { … }`; the two `LibraryView` lines stay byte-identical to upstream, as `tests/host/check-onboarding.py` reads them |
| `app/Madeira/Library.swift` | Settings › Appearance: `CouchModeSettingsSection()`; `ExecutableBrowser` creates a missing `drive_c` (the **+** button before any prefix exists) |
| `app/Madeira/MadeiraApp.swift` | `@UIApplicationDelegateAdaptor(MadeiraAppDelegate.self)` |
| `app/Madeira/Onboarding.swift` | Setup offers Madeira Dock's client page once more when it was never shown and the client is missing (`offerDockClient`, `madeiraOnboardingDockClientOffered`); Couch mode's Play opens that page too |
| `app/Madeira.xcodeproj/project.pbxproj` | The `CouchMode` and `Live` groups and their files (IDs `C1…`, `C2…`, `C4…`) |
| `README.md` | Rewritten for the fork |
| `tests/host/check-lean-diag.py`, `check-frontend.py`, `check-pool-placement.py`, `check-pool-low-images.py` | Adapted for #219, #365 and #358 (see below) |
| `.gitignore` | The generated Xcode projects of `app/CouchPreview` and `app/MadeiraUIShell` |

## Community pull requests merged here

**Now in Madeira too** (waves 1-3, synced 2026-10-24): #214, #215, #216, #223,
#243, #349, #377, #382, #386, #389, #398, #399, #402, #403, #404, #413. They
came back in through the sync as Madeira merged them, which supersedes the
early copies. **Still only in this fork:** #219, #347, #356, #357, #358, #361, #365, #412.
#367 was merged here, then reverted at the sync (see Held back).

These are open pull requests to Madeira, merged into this fork before Madeira
merged them. Each keeps its author and commit message as written, except #386:
its commit named Claude as the author, so here it credits Tomba247, who
opened the pull request. When Madeira merges
the same change, the next upstream sync takes it in as well. A change that
Madeira reworked can conflict, so compare the two then.

| Madeira PR | Author | Change | Merged here | Checked |
|---|---|---|---|---|
| [#214](https://github.com/willfaust/Madeira/pull/214) | Kesavamoorthi G | Prefix extractor rejects `..` components and absolute paths in archive entries | 2026-10-23 | Simulator build |
| [#215](https://github.com/willfaust/Madeira/pull/215) | Kesavamoorthi G | Prefix extractor rejects malformed size fields | 2026-10-23 | Simulator build |
| [#216](https://github.com/willfaust/Madeira/pull/216) | Kesavamoorthi G | Steam Cloud save transfers always use https | 2026-10-23 | `check-steam-cloud.py` passes |
| [#223](https://github.com/willfaust/Madeira/pull/223) | domainus | Fixes a crash when the Steam connection drops while a request is being sent | 2026-10-23 | `check-steam-session-jobs.py` passes |
| [#389](https://github.com/willfaust/Madeira/pull/389) | meshoklv | Madeira Dock setup replaces stale Steam registry values and logs what blocked it | 2026-10-23 | Simulator build (its host check needs Linux) |
| [#413](https://github.com/willfaust/Madeira/pull/413) | NevesHenry | The mouse wheel scrolls vertically instead of sideways | 2026-10-23 | Wheel host checks pass; needs a device with a mouse |
| [#404](https://github.com/willfaust/Madeira/pull/404) | wamei | Steam Cloud: API saves are listed in the session client's `remotecache.vdf`, so a game no longer overwrites downloaded progress with an empty save | 2026-10-23 | `check-steam-cloud.py` passes |
| [#356](https://github.com/willfaust/Madeira/pull/356) | SirDank | crypt32: every guest process gets the root certificates, not only the first | 2026-10-23 | Cloud build |
| [#412](https://github.com/willfaust/Madeira/pull/412) | NevesHenry | A full Mach thread registry reuses an exited thread's entry (crash after 512 threads) | 2026-10-23 | `check-thread-registry-reuse.py` passes |
| [#357](https://github.com/willfaust/Madeira/pull/357) | SirDank | An orphaned thread of an exited process exits only itself | 2026-10-23 | Cloud build |
| [#403](https://github.com/willfaust/Madeira/pull/403) | wamei | Each guest process gets its own default keyed event (Slay the Spire 2 startup crash) | 2026-10-23 | Cloud build |
| [#377](https://github.com/willfaust/Madeira/pull/377) | alantangok | wineserver's shared objects stay 8-byte aligned (SimCity 4 crash) | 2026-10-23 | `check-session-object-alignment.py` passes |
| [#402](https://github.com/willfaust/Madeira/pull/402) | wamei | KUSER-valued data registers are not rebased after an emulated access (Denuvo startup crash) | 2026-10-23 | Cloud build |
| [#398](https://github.com/willfaust/Madeira/pull/398) | NevesHenry | Dock's starting screen reveals a game's own message box instead of waiting forever | 2026-10-23 | `check-dock-start-screen.py` passes |
| [#243](https://github.com/willfaust/Madeira/pull/243) | 125hz | Dock keeps restoring windows first shown minimized after the starting screen | 2026-10-23 | `check-dock-start-screen.py` passes |
| [#361](https://github.com/willfaust/Madeira/pull/361) | SirDank | JIT's SIGTRAP net is installed even when Madeira starts already debugged | 2026-10-23 | Cloud build |
| [#367](https://github.com/willfaust/Madeira/pull/367) | James O'Hara (DeathKhan) | The session core is chosen from the executable's PE machine, not its file name | 2026-10-23 | Cloud build |
| [#349](https://github.com/willfaust/Madeira/pull/349) | 125hz | Audio: a whole RemoteIO slice is covered for clients that queue one engine period (choppy audio); supersedes #228 | 2026-10-23 | Cloud build; needs a device listen |
| [#365](https://github.com/willfaust/Madeira/pull/365) | James O'Hara (DeathKhan) | Launch arguments follow Windows quoting rules, fail closed, and lose iOS smart punctuation | 2026-10-23 | Cloud build |
| [#382](https://github.com/willfaust/Madeira/pull/382) | wamei | Steam's download sheet shows each game's download size and size on disk | 2026-10-23 | `check-steam-library.py`: all but its two Linux-only compile checks pass |
| [#386](https://github.com/willfaust/Madeira/pull/386) | Tomba247 | Guest reservations stay out of FEX's shared arena (Red Dead Redemption 2 reaches gameplay) | 2026-10-23 | Cloud build; needs a device run |
| [#358](https://github.com/willfaust/Madeira/pull/358) | SirDank | JIT pool: a range left partly non-executable by an image copy goes back whole to the next copy of the same image (fingerprint of its layout), so restarted programs and shared DLLs don't take fresh pool each time | 2026-10-25 | Pool host checks, adapted (below); needs a device run |
| [#347](https://github.com/willfaust/Madeira/pull/347) | 125hz | Controllers: XInput battery, a stale `XInputEnable(FALSE)` ignored while the window is in front, host pads as Windows.Gaming.Input gamepads by default (`MADEIRA_WGI_HOST_PADS`), keyboard focus on click or tap. Five commits. Ships rebuilt `xinput1_1`-`1_4.dll`; the battery part also wants a Wine change not merged upstream yet | 2026-10-25 | Gamepad host checks; needs a device run with a controller |
| [#219](https://github.com/willfaust/Madeira/pull/219) | spitefulowl | Swap tier freezes on low-RAM devices (Ori and the Will of the Wisps): page-crossing stores into aliased and swap-backed pages complete per page, the swap file is punched off the virtual lock, dead ranges' dirty pages are discarded first, and a range whose punch failed is never reused. Five commits, cherry-picked; conflicts with later upstream code resolved by keeping both (`server_ios.c`'s sampler loop keeps upstream's `MADEIRA_LEAN_DIAG` guard around the PR's 100 ms stuck-store ticks) | 2026-10-24 | `check-swap-coverage.py` (Linux job in the workflow); needs a device run with the swap tier on |
| [#399](https://github.com/willfaust/Madeira/pull/399) | Jelly-RayTian | ntdll builds with iOS SDKs that lack `rusage_info_v6.ri_page_wait_time_mach` (diagnostic only; logs `pgw=-1.0` then). Needed for the GitHub Actions build, whose newest SDK is iOS 26.2 | 2026-10-23 | `check-rusage-sdk.py` passes |

### Held back

- **#368** needs a matching change in Madeira's Wine fork; it can't come in alone.
- **#426, #427, #411** need matching changes in Madeira's Wine fork (wine#56,
  wine#57, wine#52) to do anything, or are opt-in only.
- **#210** (x87 off means full precision) changes the default for every game;
  Madeira's maintainers should decide that.
- **#228** is superseded by #349.
- **#367** (session core from the PE machine) was reverted at the 2026-10-24
  sync. Madeira's `check-launch-routing.py` keeps the name heuristic for 64-bit
  targets on purpose, #367 was never reviewed upstream, and it matters only for
  programs started by a bare file name. A sync brings it back if Madeira merges it.

## Building and installing on an iPhone

The **Build IPA** workflow (`.github/workflows/build-ipa.yml`) builds an
unsigned IPA on GitHub's macOS runners. Start it from the Actions tab, or run:

```sh
gh workflow run build-ipa.yml --repo SoSerious194/Madeira --ref main
```

A cold run takes about 1.5 hours. With caches, a run takes about 25 minutes
plus queueing. The IPA is kept for 14 days.

`tools/install-on-phone.sh` downloads the latest successful build, re-signs it
with your Apple development team and installs it on the connected iPhone,
using Xcode's own tools. Before the first run:

1. Copy `tools/install-on-phone.env.example` to `tools/install-on-phone.env`
   (git-ignored) and set your team ID and a bundle ID of your own.
2. Sign in to that team in Xcode, and connect and unlock the iPhone.

The script makes the provisioning profiles with Xcode when they're missing.
`--refresh-profiles` renews them, and `--help` lists the other options. A free
Personal Team can't have the Increased Memory Limit capability, so with one,
Madeira's Memory+ check stays red.

### Building the app on your Mac instead

The slow part of the build is the native engine; GitHub compiles it, and the
workflow publishes it as the `madeira-engine-libs-N` artifact (14 days).
`tools/build-local.sh` downloads the newest one that matches your checkout,
builds only the app with your own Xcode, signs it with your team, and installs
it on the connected iPhone. There's no unsigned IPA and no re-signing.

```sh
tools/build-local.sh --no-install   # build and sign only
tools/build-local.sh                # and install on the iPhone
```

Needs, once: Xcode's Metal toolchain (`xcodebuild -downloadComponent
MetalToolchain`, about 840 MB) and Homebrew's `cabextract` and `msitools` (or
`sevenzip` for Madeira's own `tools/fetch-vcruntime.sh`, which the script tries
first). The script fetches Microsoft's VC++ runtime itself, because it can't be in
the public artifact. Microsoft's current installer hides its payload from 7zz,
which is why `tools/fetch-vcruntime-cabextract.sh` exists. It shallow-clones just FEX's headers, about 50 MB. Change app or Couch mode code and the
rebuild is incremental. Change the engine (anything under `build/`, the
submodules or the C and Objective-C in `app/Madeira`) and the script stops
until you run the workflow again, or pass `--force-engine`. The engine is built
with GitHub's iOS 26.2 SDK; the app is built with yours. A first build, with the
engine cached, takes under two minutes.

### CI patches

The workflow changes only its own checkout, never the repository:

- **Wine:** a placeholder for a file the wine fork never committed, and
  makedep's header-order check downgraded to a warning, so configure finishes.
- **StikJIT:** `StikJIT.framework`'s Swift 6.4 module interface is rewritten to
  the older spelling, because the runner's Xcode 26 can't read it.

### Madeira's host checks adapted to this fork's pull requests

These checks are Madeira's own. Where a pull request merged only here changes
the code a check reads, the check is adapted here, and marked "This fork" in
the test:

| Check | Why | Change |
|---|---|---|
| `check-lean-diag.py` | #219 makes the thread sampler wait in 200 × 100 ms ticks, running the stuck-store check, instead of `sleep(20)` | The harness stubs `ios_stuck_store_check`, counts 200 ticks as one 20 s period, and matches the "armed" line by its prefix |
| `check-frontend.py` | #365: `LibraryEntry.applyEnvironment` passes arguments through `LaunchArgumentText` | The check also compiles `enum LaunchArgumentText` |
| `check-pool-placement.py`, `check-pool-low-images.py` | #358 gives the pool's free-list and ledger entries a `tag` field and `ios_pool_alloc_range_ex` a tag argument | The harnesses' struct copies and calls get the field and a 0 (untagged) argument; `check-pool-low-images` also expects `ios_pool_alloc_range_tagged` in the image allocation and stubs `ios_pool_image_tag` |

Ten checks (`check-eco-native`, `check-power-probe`, `check-lean-diag`,
`check-quiet-log`, `check-srv-direct`, `check-srv-eco-follow`,
`check-srv-fd-reply`, `check-msc-unbounded-retry`, `check-x64-image-nocopy`,
`check-vcruntime-mfc`) were written for a fork CI file named `build-ipa.yml`, and
expect it to run them. This fork's workflow has that name, so it runs them in its
macOS job. `check-vcruntime-mfc` also wants MFC's two DLLs fetched with the
runtime: 14 in all.

## Syncing with Madeira

In this repository, `origin` is the fork and `upstream` is Madeira:

```sh
git remote add upstream https://github.com/willfaust/Madeira.git   # once
git fetch upstream
git switch couch-mode
git merge upstream/main
```

Merge rather than rebase, because the fork's history is published. After the
merge:

1. Resolve conflicts, if any, in the files listed above.
2. Update the submodules to upstream's pins:
   `git submodule update --init --recursive`.
3. Build `app/MadeiraUIShell` and check Couch mode, then a device build.
4. Update **Synced to** above, and drop any merged pull request that upstream
   has now merged too.

To merge an open Madeira pull request early, keeping its author:

```sh
gh pr diff <number> --repo willfaust/Madeira --patch > pr.patch
git am pr.patch
```

Then add it to the table above.
