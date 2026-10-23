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
| `app/Madeira/ContentView.swift` | `LibraryView(…)` is wrapped in `CouchModeSwitch(play:enableJIT:) { … }` |
| `app/Madeira/Library.swift` | Settings › Appearance: `CouchModeSettingsSection()` |
| `app/Madeira/MadeiraApp.swift` | `@UIApplicationDelegateAdaptor(MadeiraAppDelegate.self)` |
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

### Held back

These look useful, but they change the engine (Wine, FEX or prebuilt DLLs). They
wait until this fork can build and test on a device:

- **Engine fixes:** #357, #361, #367, #377, #402, #403, #412.
- **Controllers:** #347 (XInput battery, and host pads in Windows.Gaming.Input),
  which matters for Couch mode.

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
