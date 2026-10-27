#!/usr/bin/env bash
# Build the Community Registry ZIP: angel_zapret2-<version>.zip with a top-level angel_zapret2/ folder.
# Only runtime files go in; the personal profiles/strategies and the dev workspace stay out.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${ZAPRET2_RELEASE_DIR:-/tmp/zapret2-release}"
BUILD="$DIST/build"
VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT/manifest.json")"
NAME="angel_zapret2-$VERSION.zip"

rm -rf "$BUILD"
mkdir -p "$BUILD/angel_zapret2/scripts" "$BUILD/angel_zapret2/src"

cp "$ROOT/manifest.json" "$ROOT/README.md" "$ROOT/LICENSE" \
   "$ROOT/CHANGELOG.md" "$ROOT/preview.png" \
   "$BUILD/angel_zapret2/"
cp "$ROOT"/src/*.qml "$ROOT"/src/Voices.js "$ROOT"/src/qmldir "$BUILD/angel_zapret2/src/"
cp "$ROOT/scripts/setup-polkit.sh" "$BUILD/angel_zapret2/scripts/"

# Never ship the dev workspace, design notes, personal data or old archives.
find "$BUILD/angel_zapret2" -name '*.bak' -delete
find "$BUILD/angel_zapret2" -name '_*.qml' -delete
find "$BUILD/angel_zapret2" -name '.superpowers' -prune -exec rm -rf {} +
find "$BUILD/angel_zapret2" -name 'docs' -prune -exec rm -rf {} +

python3 - "$BUILD" "$DIST/$NAME" <<'PY'
import json, os, sys, zipfile

build, out = sys.argv[1], sys.argv[2]
root = os.path.join(build, "angel_zapret2")
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for dirpath, _dirs, files in os.walk(root):
        for name in sorted(files):
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, build)
            z.write(full, rel)

with zipfile.ZipFile(out) as z:
    names = z.namelist()
    manifests = [n for n in names if n.endswith("manifest.json")]
    if len(manifests) != 1:
        raise SystemExit(f"expected exactly one manifest.json, found {len(manifests)}")
    manifest = json.loads(z.read(manifests[0]))
    if manifest.get("id") != "zapret2":
        raise SystemExit("wrong manifest id: %r" % manifest.get("id"))
    if any(n.startswith("/") or ".." in n.split("/") for n in names):
        raise SystemExit("unsafe path in archive")
    print("manifest:", manifests[0], "id:", manifest["id"], "version:", manifest["version"])
    print("files:", len(names))
PY

sha256sum "$DIST/$NAME"
ls -lh "$DIST/$NAME"
rm -rf "$BUILD"
echo "ZIP: $DIST/$NAME"
