# This fork

[SoSerious194/Madeira](https://github.com/SoSerious194/Madeira) is an
independent fork of [willfaust/Madeira](https://github.com/willfaust/Madeira).
It takes in Madeira's changes, merges selected community fixes early, and adds
its own features. It doesn't send pull requests back to Madeira.

## Synced to

| Upstream | Commit | Date |
|---|---|---|
| willfaust/Madeira `main` | [`279fd0f`](https://github.com/willfaust/Madeira/commit/279fd0f) "Record bahacan16's pull requests as merged" | 2026-10-15 |

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
| `.gitignore` | The generated Xcode projects of `app/CouchPreview` and `app/MadeiraUIShell` |

## Community pull requests merged here

These are open pull requests to Madeira, merged into this fork before Madeira
merged them. Each keeps its author and commit message. When Madeira merges
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
| [#399](https://github.com/willfaust/Madeira/pull/399) | Jelly-RayTian | ntdll builds with iOS SDKs that lack `rusage_info_v6.ri_page_wait_time_mach` (diagnostic only; logs `pgw=-1.0` then). Needed for the GitHub Actions build, whose newest SDK is iOS 26.2 | 2026-10-23 | `check-rusage-sdk.py` passes |

### Held back

These look useful, but they change the engine (Wine, FEX or prebuilt DLLs). They
wait until this fork can build and test on a device:

- **Engine fixes:** #357, #361, #367, #377, #402, #403, #412.
- **Controllers:** #347 (XInput battery, and host pads in Windows.Gaming.Input),
  which matters for Couch mode.

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

### CI patches

The workflow changes only its own checkout, never the repository:

- **Wine:** a placeholder for a file the wine fork never committed, and
  makedep's header-order check downgraded to a warning, so configure finishes.
- **StikJIT:** `StikJIT.framework`'s Swift 6.4 module interface is rewritten to
  the older spelling, because the runner's Xcode 26 can't read it.

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
