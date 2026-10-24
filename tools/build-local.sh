#!/bin/bash
# Builds the app on this Mac with your own Xcode, signs it with your own Apple
# development team and (unless --no-install) installs it on your iPhone.
#
# The slow part, the native engine (Wine, FEX, DXMT with LLVM, FFmpeg, ...), is
# compiled by the "Build IPA" workflow on GitHub and published as an artifact
# (madeira-engine-libs-N). This script downloads the newest one for your
# checkout, puts the libraries where the Xcode project links them, and builds
# only the app. No unsigned IPA and no re-signing: Xcode signs it directly.
#
# Usage:
#   tools/build-local.sh                  build, sign and install on the connected iPhone
#   tools/build-local.sh --no-install     build and sign only (no iPhone needed)
# Options:
#   --run <id>          use the engine from a given workflow run
#   --engine <file>     use an engine-libs.tgz you already have
#   --device <udid>     which iPhone (default: the one connected and paired)
#   --no-launch         install without opening the app
#   --force-engine      go ahead although engine sources changed since the engine was built
#   --configuration X   Xcode configuration (default Debug: Madeira's docs say Release crashes games)
#
# Settings, in tools/install-on-phone.env (git-ignored) or the environment:
#   MADEIRA_TEAM, MADEIRA_BUNDLE_ID, MADEIRA_DEVICE, MADEIRA_REPO as for install-on-phone.sh
#   MADEIRA_PAID_TEAM=1   keep the project's own entitlements (Increased Memory Limit);
#                         a free Personal Team cannot have it, so by default they are left out.
#
# Needs: Xcode with its iOS SDK and Metal toolchain, git, gh (to download the engine),
#        sevenzip (brew install sevenzip) for tools/fetch-vcruntime.sh, Madeira's VC++ runtime fetcher.
# Disk: about 1-2 GB for the build, plus the engine (a few hundred MB, cached).
set -euo pipefail

TOOLS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TOOLS/.." && pwd)"
CACHE="$HOME/Library/Caches/madeira-build"

SETTINGS="MADEIRA_TEAM MADEIRA_BUNDLE_ID MADEIRA_DEVICE MADEIRA_REPO MADEIRA_PAID_TEAM"
for v in $SETTINGS; do [ -n "${!v+x}" ] && eval "_given_$v=\${$v}"; done
[ -f "$TOOLS/install-on-phone.env" ] && . "$TOOLS/install-on-phone.env"
for v in $SETTINGS; do g="_given_$v"; [ -n "${!g+x}" ] && eval "$v=\${$g}"; done

RUN_ID="" ENGINE="" DEVICE="${MADEIRA_DEVICE:-}" INSTALL=1 LAUNCH=1 FORCE=0 CONFIG=Debug
while [ $# -gt 0 ]; do
    case "$1" in
        --run) RUN_ID="$2"; shift ;;
        --engine) ENGINE="$2"; shift ;;
        --device) DEVICE="$2"; shift ;;
        --no-install) INSTALL=0 ;;
        --no-launch) LAUNCH=0 ;;
        --force-engine) FORCE=1 ;;
        --configuration) CONFIG="$2"; shift ;;
        -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done

die() { echo "error: $*" >&2; exit 1; }
step() { echo "==> $*"; }

TEAM="${MADEIRA_TEAM:-}"; APP_ID="${MADEIRA_BUNDLE_ID:-}"
[ -n "$TEAM" ] || die "set MADEIRA_TEAM in tools/install-on-phone.env (your team ID)"
[ -n "$APP_ID" ] || die "set MADEIRA_BUNDLE_ID in tools/install-on-phone.env (e.g. dev.yourname.madeira)"
for tool in xcodebuild xcrun git tar; do command -v $tool >/dev/null || die "$tool not found"; done

cd "$ROOT"
WORK="$(mktemp -d /private/tmp/madeira-build-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# ------------------------------------------------------------ prerequisites
if ! xcrun -sdk macosx metal --version >/dev/null 2>&1; then
    die "Xcode's Metal toolchain is missing (the app has Metal shaders). Install it once:
       xcodebuild -downloadComponent MetalToolchain"
fi
step "Xcode: $(xcodebuild -version | head -1), iOS SDK $(xcrun --sdk iphoneos --show-sdk-version)"

# FEX's headers: the app's FEXBridge.mm includes them. Only these are needed, not
# FEX's test binaries and the rest of its submodules.
if [ ! -f FEX/FEXCore/include/FEXCore/Config/Config.h ]; then
    step "fetching FEX's headers (shallow, at the commit this checkout pins)"
    git submodule update --init --depth 1 FEX
    git -C FEX submodule update --init --depth 1 External/fmt External/range-v3 External/unordered_dense
fi
[ -f FEX/External/fmt/include/fmt/core.h ] || git -C FEX submodule update --init --depth 1 External/fmt External/range-v3 External/unordered_dense

# ------------------------------------------------------------------- engine
if [ -z "$ENGINE" ]; then
    command -v gh >/dev/null || die "the GitHub CLI (gh) is needed to download the engine; or pass --engine <file>"
    REPO="${MADEIRA_REPO:-$(git remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')}"
    if [ -z "$RUN_ID" ]; then
        # The newest successful run whose commit is part of this checkout's history.
        for id in $(gh run list --repo "$REPO" --workflow build-ipa.yml --branch main --status success --limit 15 --json databaseId --jq '.[].databaseId'); do
            sha=$(gh run view "$id" --repo "$REPO" --json headSha --jq .headSha)
            if git cat-file -e "$sha^{commit}" 2>/dev/null && git merge-base --is-ancestor "$sha" HEAD; then RUN_ID=$id; break; fi
        done
        [ -n "$RUN_ID" ] || die "no successful Build IPA run found in this checkout's history (push your commits and run the workflow, or pass --run / --engine)"
    fi
    ENGINE_DIR="$CACHE/engine-$RUN_ID"
    if [ ! -f "$ENGINE_DIR/engine-libs.tgz" ]; then
        step "downloading the engine from $REPO run $RUN_ID (cached afterwards)"
        mkdir -p "$ENGINE_DIR"
        gh run download "$RUN_ID" --repo "$REPO" --pattern 'madeira-engine-libs-*' -D "$ENGINE_DIR/dl" \
            || die "run $RUN_ID has no engine artifact (older runs, or it expired after 14 days): run the workflow again"
        mv "$(find "$ENGINE_DIR/dl" -name engine-libs.tgz | head -1)" "$ENGINE_DIR/engine-libs.tgz"
        rm -rf "$ENGINE_DIR/dl"
    else
        step "engine from run $RUN_ID (cached)"
    fi
    ENGINE="$ENGINE_DIR/engine-libs.tgz"
fi
[ -f "$ENGINE" ] || die "no such engine archive: $ENGINE"
tar xzf "$ENGINE" -C "$WORK" ENGINE_INFO.txt
ENGINE_COMMIT=$(sed -n 's/^commit=//p' "$WORK/ENGINE_INFO.txt")
ENGINE_RUN=$(sed -n 's/^run=//p' "$WORK/ENGINE_INFO.txt")
step "engine: workflow build $ENGINE_RUN, commit ${ENGINE_COMMIT:0:7}, iOS SDK $(sed -n 's/^ios_sdk=//p' "$WORK/ENGINE_INFO.txt")"

# The libraries must match the engine-facing code being built. Changes to the
# engine's sources since the engine was built mean it is out of date.
if git cat-file -e "$ENGINE_COMMIT^{commit}" 2>/dev/null; then
    CHANGED=$(git diff --name-only "$ENGINE_COMMIT" HEAD -- build wine FEX dxmt madeira-dock madeira-d3d12 \
        'app/Madeira/*.m' 'app/Madeira/*.mm' 'app/Madeira/*.c' 'app/Madeira/*.h' 'app/Madeira/Winios' 'app/Madeira/SwiftSteam/*.c' || true)
    if [ -n "$CHANGED" ]; then
        echo "engine sources changed since the engine was built:" >&2
        echo "$CHANGED" | sed 's/^/    /' | head -12 >&2
        [ "$FORCE" = 1 ] || die "run the Build IPA workflow again for a matching engine, or pass --force-engine"
    fi
else
    echo "note: engine commit ${ENGINE_COMMIT:0:7} is not in this checkout; not checking that the sources match" >&2
fi
step "placing the engine libraries"
tar xzf "$ENGINE" -C "$ROOT" --exclude ENGINE_INFO.txt

# ------------------------------------------------------ Microsoft's runtime
# Madeira's own fetcher (unpacks Microsoft's vc_redist.x64.exe, verifies the files).
if [ "$(ls app/Madeira/x86_64-vcruntime/*.dll 2>/dev/null | wc -l | tr -d ' ')" -lt 14 ]; then
    command -v 7zz >/dev/null || command -v 7z >/dev/null || die "7zz is needed to unpack Microsoft's runtime:  brew install sevenzip"
    step "fetching Microsoft's VC++ runtime (tools/fetch-vcruntime.sh)"
    bash tools/fetch-vcruntime.sh > "$WORK/vcruntime.log" 2>&1 || { tail -8 "$WORK/vcruntime.log" >&2; die "could not fetch the VC++ runtime"; }
fi
bash build/stage-licenses.sh >/dev/null

# --------------------------------------------------------------- signing
# A free Personal Team cannot have Apple's Increased Memory Limit capability (Xcode
# would refuse the profile), nor macOS's allow-jit key: leave both out. JIT comes
# from the debugger, which get-task-allow lets attach.
ENT="$WORK/Madeira.entitlements"
if [ "${MADEIRA_PAID_TEAM:-0}" = 1 ]; then
    ENT="$ROOT/app/Madeira/Madeira.entitlements"
else
    cat > "$ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>get-task-allow</key><true/>
</dict></plist>
EOF
fi

# --------------------------------------------------------------- device
if [ "$INSTALL" = 1 ] && [ -z "$DEVICE" ]; then
    xcrun devicectl list devices --json-output "$WORK/devices.json" >/dev/null
    DEVICE=$(python3 - "$WORK/devices.json" <<'PYEOF'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
found = [d for d in devices
         if d["hardwareProperties"].get("reality") == "physical"
         and d["hardwareProperties"].get("platform") == "iOS"
         and d["connectionProperties"].get("pairingState") == "paired"
         and d["connectionProperties"].get("tunnelState") != "unavailable"
         and d["connectionProperties"].get("transportType")]
print(found[0]["hardwareProperties"]["udid"] if len(found) == 1 else "")
PYEOF
    )
    [ -n "$DEVICE" ] || die "connect and unlock exactly one paired iPhone, pass --device <udid>, or use --no-install"
fi
DESTINATION="generic/platform=iOS"
[ "$INSTALL" = 1 ] && DESTINATION="id=$DEVICE"

# ------------------------------------------------------------------ build
DD="$CACHE/derived-$CONFIG"
BUILD_NUMBER=$(git rev-list --count HEAD)
step "building Madeira ($CONFIG) for $DESTINATION, team $TEAM, bundle $APP_ID"
echo "    (first build takes several minutes; later ones are incremental)"
if ! xcodebuild -project app/Madeira.xcodeproj -scheme Madeira -configuration "$CONFIG" \
        -destination "$DESTINATION" -derivedDataPath "$DD" \
        -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
        DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic CODE_SIGN_ENTITLEMENTS="$ENT" \
        MADEIRA_BUNDLE_IDENTIFIER="$APP_ID" \
        MARKETING_VERSION="0.1.$ENGINE_RUN" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
        build > "$WORK/xcodebuild.log" 2>&1; then
    grep -E "error:|Undefined symbol|^ld: |symbol\(s\) not found" "$WORK/xcodebuild.log" | sort -u | head -25 >&2
    mkdir -p "$CACHE/logs"; cp "$WORK/xcodebuild.log" "$CACHE/logs/last-build.log"
    die "the build failed; full log: $CACHE/logs/last-build.log"
fi
APP="$DD/Build/Products/$CONFIG-iphoneos/Madeira.app"
[ -d "$APP" ] || die "built, but no app at $APP"
codesign --verify --deep --strict "$APP" || die "the built app's signature does not verify"
step "built and signed: $(codesign -dv "$APP" 2>&1 | sed -n 's/^Identifier=//p') $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist") ($BUILD_NUMBER), team $(codesign -dv "$APP" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
echo "    $APP"

# ---------------------------------------------------------------- install
if [ "$INSTALL" = 1 ]; then
    step "installing on the iPhone (keep it unlocked)"
    xcrun devicectl device install app --device "$DEVICE" "$APP" > "$WORK/install.log" 2>&1 \
        || { tail -15 "$WORK/install.log"; die "installation failed"; }
    step "installed $APP_ID"
    if [ "$LAUNCH" = 1 ]; then
        xcrun devicectl device process launch --device "$DEVICE" "$APP_ID" >/dev/null 2>&1 \
            && step "launched" || echo "    (could not open it; unlock the iPhone and open Madeira yourself)"
    fi
else
    step "not installed (--no-install). To install this build: tools/build-local.sh"
fi
