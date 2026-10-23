#!/bin/bash
# Installs a cloud build of this fork on your own iPhone: downloads the
# unsigned IPA from the "Build IPA" workflow (.github/workflows/build-ipa.yml),
# re-signs it with your Apple development team and installs it over the cable
# or local network, with Xcode's own tools. No Apple ID password is asked for:
# Xcode must already be signed in to the team (Xcode › Settings › Accounts).
#
# Usage:
#   tools/install-on-phone.sh                 latest successful build of main
#   tools/install-on-phone.sh --run <id>      a given workflow run
#   tools/install-on-phone.sh --ipa <file>    an IPA already downloaded
# Options:
#   --device <udid>       which iPhone (default: the one connected and paired)
#   --refresh-profiles    have Xcode create or renew the provisioning profiles
#   --no-launch           install without opening the app
#
# Settings, in tools/install-on-phone.env (git-ignored) or the environment:
#   MADEIRA_TEAM          your team ID, e.g. 2QLDFNF25N (required)
#   MADEIRA_BUNDLE_ID     the app's bundle ID under your team, e.g.
#                         dev.yourname.madeira; the JIT helper gets .JITHelper
#   MADEIRA_DEVICE        an iPhone's UDID (optional)
#   MADEIRA_REPO          owner/repo of the workflow (default: git remote origin)
#
# Notes:
# - A free Personal Team cannot have the Increased Memory Limit capability,
#   so Madeira's Memory+ check stays red with one; everything else works.
# - Missing profiles are made by building a throwaway app and extension with
#   your team ID and bundle IDs (xcodegen and Xcode); Xcode registers the IDs.
set -euo pipefail

TOOLS="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TOOLS/.." && pwd)"
# The settings file fills in what the environment leaves unset; a variable
# given on the command line, even an empty one, wins.
SETTINGS="MADEIRA_TEAM MADEIRA_BUNDLE_ID MADEIRA_DEVICE MADEIRA_REPO"
for v in $SETTINGS; do [ -n "${!v+x}" ] && eval "_given_$v=\${$v}"; done
[ -f "$TOOLS/install-on-phone.env" ] && . "$TOOLS/install-on-phone.env"
for v in $SETTINGS; do g="_given_$v"; [ -n "${!g+x}" ] && eval "$v=\${$g}"; done

RUN_ID="" IPA="" DEVICE="${MADEIRA_DEVICE:-}" REFRESH=0 LAUNCH=1
while [ $# -gt 0 ]; do
    case "$1" in
        --run) RUN_ID="$2"; shift ;;
        --ipa) IPA="$2"; shift ;;
        --device) DEVICE="$2"; shift ;;
        --refresh-profiles) REFRESH=1 ;;
        --no-launch) LAUNCH=0 ;;
        -h|--help) sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done

die() { echo "error: $*" >&2; exit 1; }
step() { echo "==> $*"; }

TEAM="${MADEIRA_TEAM:-}"
APP_ID="${MADEIRA_BUNDLE_ID:-}"
[ -n "$TEAM" ] || die "set MADEIRA_TEAM in tools/install-on-phone.env (your team ID, Xcode › Settings › Accounts)"
[ -n "$APP_ID" ] || die "set MADEIRA_BUNDLE_ID in tools/install-on-phone.env (e.g. dev.yourname.madeira)"
EXT_ID="$APP_ID.JITHelper"
for tool in xcrun codesign security; do command -v $tool >/dev/null || die "$tool not found (install Xcode)"; done

WORK="$(mktemp -d /private/tmp/madeira-install-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# ------------------------------------------------------------------ device
if [ -z "$DEVICE" ]; then
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
for d in found:
    print(d["hardwareProperties"]["udid"], file=sys.stderr, end=" ")
    print(d["deviceProperties"].get("name", ""), d["hardwareProperties"].get("marketingName", ""), file=sys.stderr)
print(found[0]["hardwareProperties"]["udid"] if len(found) == 1 else "")
PYEOF
    )
    [ -n "$DEVICE" ] || die "connect and unlock exactly one paired iPhone, or pass --device <udid>"
fi
step "iPhone: $DEVICE"

# ---------------------------------------------------------------- the IPA
if [ -z "$IPA" ]; then
    command -v gh >/dev/null || die "the GitHub CLI (gh) is needed to download builds; or pass --ipa"
    REPO="${MADEIRA_REPO:-$(git -C "$REPO_ROOT" remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')}"
    if [ -z "$RUN_ID" ]; then
        RUN_ID=$(gh run list --repo "$REPO" --workflow build-ipa.yml --branch main --status success --limit 1 \
            --json databaseId --jq '.[0].databaseId')
        [ -n "$RUN_ID" ] || die "no successful Build IPA run on $REPO main yet"
    fi
    step "downloading the IPA from $REPO run $RUN_ID"
    gh run download "$RUN_ID" --repo "$REPO" --pattern '*-unsigned-ipa' -D "$WORK/dl"
    IPA=$(find "$WORK/dl" -name '*.ipa' | head -1)
    [ -n "$IPA" ] || die "run $RUN_ID has no IPA (its artifacts expire after 14 days)"
fi
[ -f "$IPA" ] || die "no such IPA: $IPA"
step "unpacking $(basename "$IPA")"
ditto -x -k "$IPA" "$WORK/x"
APP=$(find "$WORK/x/Payload" -maxdepth 1 -name '*.app' | head -1)
EXT="$APP/PlugIns/MadeiraJITHelper.appex"
[ -d "$APP" ] && [ -d "$EXT" ] || die "the IPA does not contain Madeira.app with its JIT helper"

# ---------------------------------------------------------------- profiles
PROFILE_DIRS=("$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" "$HOME/Library/MobileDevice/Provisioning Profiles")

# The newest unexpired profile for a bundle ID that lists the device.
find_profile() {
    local want="$TEAM.$1" best="" best_date=""
    for dir in "${PROFILE_DIRS[@]}"; do
        [ -d "$dir" ] || continue
        for p in "$dir"/*.mobileprovision; do
            [ -f "$p" ] || continue
            security cms -D -i "$p" > "$WORK/p.plist" 2>/dev/null || continue
            local info
            info=$(python3 - "$WORK/p.plist" "$want" "$DEVICE" <<'PYEOF'
import plistlib, sys, datetime
p = plistlib.load(open(sys.argv[1], "rb"))
ok = (p.get("Entitlements", {}).get("application-identifier") == sys.argv[2]
      and sys.argv[3] in p.get("ProvisionedDevices", [])
      and p["ExpirationDate"] > datetime.datetime.now(p["ExpirationDate"].tzinfo))
print(p["CreationDate"].isoformat() if ok else "")
PYEOF
            )
            if [ -n "$info" ] && [[ "$info" > "$best_date" ]]; then best="$p"; best_date="$info"; fi
        done
    done
    echo "$best"
}

# Xcode makes profiles for a project it signs; build a throwaway one.
make_profiles() {
    command -v xcodegen >/dev/null || die "xcodegen is needed to create profiles (brew install xcodegen)"
    step "asking Xcode to create profiles for $APP_ID and $EXT_ID (team $TEAM)"
    local h="$WORK/profiles-helper"
    mkdir -p "$h/App" "$h/Ext"
    echo 'import SwiftUI
@main struct HelperApp: App { var body: some Scene { WindowGroup { Text("profiles") } } }' > "$h/App/App.swift"
    echo 'import Foundation' > "$h/Ext/Ext.swift"
    cat > "$h/project.yml" <<EOF
name: ProfilesHelper
options: { deploymentTarget: { iOS: "17.0" } }
settings: { base: { DEVELOPMENT_TEAM: $TEAM, CODE_SIGN_STYLE: Automatic, SWIFT_VERSION: "5.0" } }
targets:
  Helper:
    type: application
    platform: iOS
    sources: [App]
    info: { path: App/Info.plist, properties: { UILaunchScreen: {} } }
    settings: { base: { PRODUCT_BUNDLE_IDENTIFIER: $APP_ID } }
    dependencies: [{ target: HelperExt }]
  HelperExt:
    type: app-extension
    platform: iOS
    sources: [Ext]
    info: { path: Ext/Info.plist, properties: { NSExtension: { NSExtensionPointIdentifier: com.apple.ar.viewer, NSExtensionPrincipalClass: NSObject } } }
    settings: { base: { PRODUCT_BUNDLE_IDENTIFIER: $EXT_ID } }
EOF
    (cd "$h" && xcodegen -q && xcodebuild -project ProfilesHelper.xcodeproj -scheme Helper \
        -destination "id=$DEVICE" -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
        -derivedDataPath dd build > "$WORK/profiles.log" 2>&1) \
        || { grep -E "error:" "$WORK/profiles.log" | head -10; die "Xcode could not create the profiles"; }
}

APP_PROFILE="" EXT_PROFILE=""
[ "$REFRESH" = 1 ] || { APP_PROFILE=$(find_profile "$APP_ID"); EXT_PROFILE=$(find_profile "$EXT_ID"); }
if [ -z "$APP_PROFILE" ] || [ -z "$EXT_PROFILE" ]; then
    make_profiles
    APP_PROFILE=$(find_profile "$APP_ID"); EXT_PROFILE=$(find_profile "$EXT_ID")
    [ -n "$APP_PROFILE" ] && [ -n "$EXT_PROFILE" ] || die "Xcode built the helper but no matching profiles were found"
fi
step "profiles: $(basename "$APP_PROFILE"), $(basename "$EXT_PROFILE")"

# The signing identity: one in the keychain whose certificate the profile allows.
security cms -D -i "$APP_PROFILE" > "$WORK/app-profile.plist"
IDENTITY=$(python3 - "$WORK/app-profile.plist" <<'PYEOF'
import plistlib, sys, hashlib, subprocess
p = plistlib.load(open(sys.argv[1], "rb"))
allowed = {hashlib.sha1(c).hexdigest().upper() for c in p.get("DeveloperCertificates", [])}
out = subprocess.run(["security", "find-identity", "-v", "-p", "codesigning"], capture_output=True, text=True).stdout
for line in out.splitlines():
    parts = line.split()
    if len(parts) > 1 and parts[1] in allowed:
        print(parts[1]); break
PYEOF
)
[ -n "$IDENTITY" ] || die "no signing certificate in the keychain matches the profile; renew it in Xcode › Settings › Accounts"
step "signing identity: $(security find-identity -v -p codesigning | grep "$IDENTITY" | sed -E 's/.*"(.*)"/\1/')"

# ------------------------------------------------------------------ re-sign
step "re-signing as $APP_ID"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_ID" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $EXT_ID" "$EXT/Info.plist"
for fw in "$APP"/Frameworks/*.framework; do
    [ -d "$fw" ] && /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_ID.$(basename "$fw" .framework)" "$fw/Info.plist" 2>/dev/null || true
done
cp "$APP_PROFILE" "$APP/embedded.mobileprovision"
cp "$EXT_PROFILE" "$EXT/embedded.mobileprovision"

# What the profiles grant; the build's own entitlements ask for more (the
# increased memory limit, macOS's allow-jit) than a Personal Team gets.
entitlements() {
    cat > "$2" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>application-identifier</key><string>$TEAM.$1</string>
  <key>com.apple.developer.team-identifier</key><string>$TEAM</string>
  <key>get-task-allow</key><true/>
</dict></plist>
EOF
}
entitlements "$APP_ID" "$WORK/app.entitlements"
entitlements "$EXT_ID" "$WORK/ext.entitlements"
python3 - "$WORK/app-profile.plist" <<'PYEOF' && sed -i '' 's#<key>get-task-allow</key>#<key>com.apple.developer.kernel.increased-memory-limit</key><true/> <key>get-task-allow</key>#' "$WORK/app.entitlements"
import plistlib, sys
p = plistlib.load(open(sys.argv[1], "rb"))
sys.exit(0 if p["Entitlements"].get("com.apple.developer.kernel.increased-memory-limit") else 1)
PYEOF

find "$APP" -name _CodeSignature -type d -prune -exec rm -rf {} +
# Innermost first: loose libraries, frameworks, the extension, the app.
find "$APP" -name '*.dylib' -type f ! -path '*.framework/*' -print0 | while IFS= read -r -d '' lib; do
    codesign -f -s "$IDENTITY" --timestamp=none "$lib"
done
for fw in "$APP"/Frameworks/*.framework; do
    [ -d "$fw" ] && codesign -f -s "$IDENTITY" --timestamp=none "$fw"
done
codesign -f -s "$IDENTITY" --timestamp=none --entitlements "$WORK/ext.entitlements" "$EXT"
codesign -f -s "$IDENTITY" --timestamp=none --entitlements "$WORK/app.entitlements" "$APP"
codesign --verify --deep --strict "$APP" || die "the re-signed app does not verify"

# ------------------------------------------------------------------ install
step "installing on the iPhone (keep it unlocked)"
xcrun devicectl device install app --device "$DEVICE" "$APP" > "$WORK/install.log" 2>&1 \
    || { tail -15 "$WORK/install.log"; die "installation failed"; }
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Info.plist")
step "installed $APP_ID $VERSION"
if [ "$LAUNCH" = 1 ]; then
    xcrun devicectl device process launch --device "$DEVICE" "$APP_ID" > /dev/null 2>&1 \
        && step "launched" || echo "    (could not open it; unlock the iPhone and open Madeira yourself)"
fi
