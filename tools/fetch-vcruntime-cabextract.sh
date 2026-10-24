#!/bin/bash
# Fallback for tools/fetch-vcruntime.sh (Madeira's own, which unpacks Microsoft's
# vc_redist.x64.exe with 7zz). Microsoft's current installer keeps its payload as
# attached cabinets that 7zz does not unpack ("no cab files found"); cabextract
# scans the whole file for them. Same twelve DLLs plus MFC's two, for
# app/Madeira/x86_64-vcruntime, as tools/fetch-vcruntime.md describes. The DLLs are Microsoft's: they go
# into your own build only and are never committed (the folder is git-ignored).
#
# Usage: tools/fetch-vcruntime-cabextract.sh [dest]    (default app/Madeira/x86_64-vcruntime)
# Needs cabextract and msitools:  brew install cabextract msitools
#
# The same extraction runs in .github/workflows/build-ipa.yml, on the runner.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$ROOT/app/Madeira/x86_64-vcruntime}"
WANT="concrt140 msvcp140 msvcp140_1 msvcp140_2 msvcp140_atomic_wait msvcp140_codecvt_ids vcamp140 vccorlib140 vcomp140 vcruntime140 vcruntime140_1 vcruntime140_threads mfc140 mfc140u"
NWANT=$(echo $WANT | wc -w | tr -d ' ')

mkdir -p "$DEST"
have=$(ls "$DEST"/*.dll 2>/dev/null | wc -l | tr -d ' ' || true)
if [ "$have" -ge "$NWANT" ]; then echo "x86_64-vcruntime: $have of $NWANT DLLs already there"; exit 0; fi

for tool in cabextract msiextract; do
    command -v $tool >/dev/null || { echo "error: $tool not found (brew install cabextract msitools)" >&2; exit 1; }
done

WORK="$(mktemp -d /private/tmp/madeira-vcr-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
echo "downloading vc_redist.x64.exe from Microsoft (about 18 MB)"
curl -fL --retry 3 --max-time 600 -o "$WORK/vcr.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe

cat > "$WORK/is_x64.py" <<'EOF'
import struct, sys
d = open(sys.argv[1], 'rb').read()
pe = struct.unpack_from('<I', d, 0x3c)[0]
ok = d[pe:pe + 4] == b'PE\0\0' and struct.unpack_from('<H', d, pe + 4)[0] == 0x8664
sys.exit(0 if ok else 1)
EOF

mkdir -p "$WORK/x"
cabextract -q -d "$WORK/x" "$WORK/vcr.exe" || true
FOUND=0
collect() {
    FOUND=0
    for base in $WANT; do
        # The arm64 copies share the names: take the one whose PE header says x86-64.
        while read -r cand; do
            if python3 "$WORK/is_x64.py" "$cand" 2>/dev/null; then
                cp "$cand" "$DEST/$base.dll"; FOUND=$((FOUND + 1)); break
            fi
        done < <(find "$WORK/x" -type f \( -iname "$base.dll*" -o -iname "F_CENTRAL_${base}_*" \))
    done
}
# Unwrap nested cabinets and MSIs until every DLL turns up.
for pass in 1 2 3 4; do
    find "$WORK/x" -type f -size +20k ! -name '*.dll*' ! -name '*_amd64' ! -name '*_arm64' ! -name '*_x86' | while read -r f; do
        [ -d "$f.d" ] && continue
        mkdir -p "$f.d"
        cabextract -q -d "$f.d" "$f" >/dev/null 2>&1 || msiextract -C "$f.d" "$f" >/dev/null 2>&1 || rmdir "$f.d"
    done
    collect
    [ "$FOUND" -eq "$NWANT" ] && break
done
echo "x86_64-vcruntime: recovered $FOUND of $NWANT DLLs"
[ "$FOUND" -eq "$NWANT" ] || { echo "error: some DLLs were not found in the installer" >&2; exit 1; }
