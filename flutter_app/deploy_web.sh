#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$SCRIPT_DIR/build/web"
CF_ZONE_ID="2b94ae65a6dd56a39d7933eab6a00709"

: "${CF_TOKEN:?CF_TOKEN is required to purge Cloudflare cache}"

cd "$SCRIPT_DIR"
flutter build web --release --base-href "/" --no-wasm-dry-run

python3 - "$WEB_DIR" <<'PY'
import base64
import hashlib
import json
import re
import struct
import sys
from pathlib import Path

web = Path(sys.argv[1])
assets = web / "assets"


def sha8(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:8]


def hashed_path(path: Path) -> Path:
    if re.search(r"\.[0-9a-f]{8}$", path.stem):
        return path
    target = path.with_name(f"{path.stem}.{sha8(path)}{path.suffix}")
    path.rename(target)
    return target


font_manifest_path = assets / "FontManifest.json"
font_manifest = json.loads(font_manifest_path.read_text(encoding="utf-8"))
asset_rewrites = {}
font_count = 0

for family in font_manifest:
    for font in family.get("fonts", []):
        asset = font["asset"]
        source = assets / asset
        if not source.is_file():
            raise SystemExit(f"Font manifest asset is missing: {asset}")
        target = hashed_path(source)
        updated_asset = target.relative_to(assets).as_posix()
        asset_rewrites[asset] = updated_asset
        font["asset"] = updated_asset
        font_count += 1

font_manifest_path.write_text(
    json.dumps(font_manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

png_rewrites = {}
for path in sorted(web.rglob("*")):
    if path.is_file() and path.suffix.lower() == ".png":
        target = hashed_path(path)
        png_rewrites[path.relative_to(web).as_posix()] = (
            target.relative_to(web).as_posix()
        )
        if target.parent == assets or assets in target.parents:
            asset_rewrites[path.relative_to(assets).as_posix()] = (
                target.relative_to(assets).as_posix()
            )


def codec_string(value: str) -> bytes:
    encoded = value.encode("utf-8")
    if len(encoded) < 254:
        size = bytes([len(encoded)])
    else:
        size = b"\xfe" + struct.pack("<I", len(encoded))
    return b"\x07" + size + encoded


asset_manifest_path = assets / "AssetManifest.bin"
asset_manifest_json_path = assets / "AssetManifest.bin.json"
if asset_manifest_path.is_file():
    original_manifest = asset_manifest_path.read_bytes()
    updated_manifest = original_manifest
    for source, target in asset_rewrites.items():
        updated_manifest = updated_manifest.replace(
            codec_string(source),
            codec_string(target),
        )
    asset_manifest_path.write_bytes(updated_manifest)

    if asset_manifest_json_path.is_file():
        encoded_manifest = json.loads(
            asset_manifest_json_path.read_text(encoding="utf-8")
        )
        decoded_manifest = base64.b64decode(encoded_manifest, validate=True)
        if decoded_manifest != original_manifest:
            raise SystemExit("AssetManifest.bin.json does not match AssetManifest.bin")
        asset_manifest_json_path.write_text(
            json.dumps(base64.b64encode(updated_manifest).decode("ascii")) + "\n",
            encoding="utf-8",
        )

text_suffixes = {".css", ".html", ".js", ".json", ".map", ".txt", ".webmanifest", ".xml"}
rewrites = {}
for source, target in asset_rewrites.items():
    rewrites[source] = target
    rewrites[f"assets/{source}"] = f"assets/{target}"
rewrites.update(png_rewrites)

for path in web.rglob("*"):
    if not path.is_file() or path.suffix.lower() not in text_suffixes:
        continue
    content = path.read_text(encoding="utf-8")
    updated = content
    for source, target in sorted(rewrites.items(), key=lambda item: len(item[0]), reverse=True):
        updated = updated.replace(source, target)
    if updated != content:
        path.write_text(updated, encoding="utf-8")

bootstrap_path = web / "flutter_bootstrap.js"
bootstrap = bootstrap_path.read_text(encoding="utf-8")
if "mainJsPath: `${build.mainJsPath}?v=${serviceWorkerVersion}`" not in bootstrap:
    raise SystemExit("flutter_bootstrap.js is missing the main.dart.js cache buster")
if re.search(r"<script\b[^>]*\bsrc=[\"'][^\"']*flutter\.js", (web / "index.html").read_text()):
    raise SystemExit("flutter.js is separately loaded and needs a cache-busted URL")

index_path = web / "index.html"
index = index_path.read_text(encoding="utf-8")
bootstrap_hash = sha8(bootstrap_path)
bootstrap_reference = re.compile(
    r"flutter_bootstrap\.js\?v=(?:\$\{Date\.now\(\)\}|[0-9a-f]{8})"
)
index, replacements = bootstrap_reference.subn(
    f"flutter_bootstrap.js?v={bootstrap_hash}",
    index,
)
if replacements != 1:
    raise SystemExit("Could not set the content-hashed bootstrap URL in index.html")
index_path.write_text(index, encoding="utf-8")

for family in json.loads(font_manifest_path.read_text(encoding="utf-8")):
    for font in family.get("fonts", []):
        path = assets / font["asset"]
        if not path.is_file() or not re.search(r"\.[0-9a-f]{8}\.[^.]+$", path.name):
            raise SystemExit(f"Font asset was not fingerprinted: {font['asset']}")

for source in asset_rewrites:
    encoded_source = codec_string(source)
    if encoded_source in asset_manifest_path.read_bytes():
        raise SystemExit(f"AssetManifest.bin still references {source}")

for path in web.rglob("*"):
    if not path.is_file() or path.suffix.lower() not in text_suffixes:
        continue
    content = path.read_text(encoding="utf-8")
    for source in asset_rewrites:
        if source in content:
            raise SystemExit(f"Stale font asset reference in {path.relative_to(web)}: {source}")

print(f"Fingerprinted {font_count} fonts and package assets")
print(f"Fingerprinted {len(png_rewrites)} PNG assets")
print(f"flutter_bootstrap.js?v={bootstrap_hash}")
PY

if [[ -n "${VPS_SSH_KEY:-}" ]]; then
  if ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
  printf '%s\n' "$VPS_SSH_KEY" | ssh-add - >/dev/null
fi

rsync -az --delete "$WEB_DIR/" root@94.249.179.195:/opt/koulu/web/dist/

purge_response="$(
  curl --fail --silent --show-error \
    --request POST \
    "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/purge_cache" \
    --header "Authorization: Bearer $CF_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{"files":["https://koulu.kreatix.dev/","https://koulu.kreatix.dev/index.html","https://koulu.kreatix.dev/flutter_bootstrap.js","https://koulu.kreatix.dev/assets/FontManifest.json"]}'
)"
printf '%s' "$purge_response" | python3 -c '
import json
import sys

response = json.load(sys.stdin)
if not response.get("success"):
    raise SystemExit("Cloudflare cache purge failed")
print("Cloudflare cache purge completed")
'
