#!/usr/bin/env bash
#
# package.sh — build distributable zips for all presets and extensions in this repo.
#
# Each zip has its config file (preset.yml / extension.yml) at the root so that
# `specify preset add --from <url>` / `specify extension add --from <url>` work
# with GitHub Release assets.
#
# Usage:
#   scripts/package.sh [--out DIR] [--only <id>]
#
#   --out DIR    Output directory for zips (default: dist/)
#   --only ID    Package only the preset/extension with this id
#
# Output filenames: <id>-<version>.zip
# Requires: bash, python3 (stdlib only).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_DIR/dist"
ONLY=""

err()  { printf 'error: %s\n' "$*" >&2; }
info() { printf '• %s\n' "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)  OUT_DIR="${2:?--out needs a value}"; shift 2 ;;
    --only) ONLY="${2:?--only needs a value}";   shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "unknown argument: $1"; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { err "'python3' is not on PATH"; exit 1; }

mkdir -p "$OUT_DIR"

package_component() {
  local src_dir="$1" config_file="$2"
  local config="$src_dir/$config_file"
  [[ -f "$config" ]] || return 0

  local id version
  id="$(grep -E '^\s+id:' "$config" | head -n1 | sed 's/.*id:[[:space:]]*//' | tr -d '"')"
  version="$(grep -E '^\s+version:' "$config" | head -n1 | sed 's/.*version:[[:space:]]*//' | tr -d '"')"

  [[ -z "$id" || -z "$version" ]] && { err "could not read id/version from $config"; return 1; }
  [[ -n "$ONLY" && "$id" != "$ONLY" ]] && return 0

  local zip_name="${id}-${version}.zip"
  local zip_path="$OUT_DIR/$zip_name"

  info "packaging $id v$version → dist/$zip_name"

  python3 - "$src_dir" "$zip_path" <<'PYEOF'
import sys, os, zipfile, pathlib

src = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2])

# Files/dirs to exclude from the distributable
EXCLUDE = {
  "scripts/generate.sh",
  "install.sh",
  ".git",
  ".DS_Store",
  "__pycache__",
}

def should_exclude(rel: str) -> bool:
  parts = pathlib.PurePosixPath(rel).parts
  return any(p in EXCLUDE or rel in EXCLUDE for p in parts)

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
  for path in sorted(src.rglob("*")):
    if path.is_dir():
      continue
    rel = path.relative_to(src).as_posix()
    if should_exclude(rel):
      continue
    zf.write(path, rel)

print(f"  → {out} ({out.stat().st_size // 1024}KB, {len(zf.namelist())} files)")
PYEOF
}

if [[ -d "$REPO_DIR/presets" ]]; then
  for dir in "$REPO_DIR/presets"/*/; do
    package_component "$dir" "preset.yml"
  done
fi

if [[ -d "$REPO_DIR/extensions" ]]; then
  for dir in "$REPO_DIR/extensions"/*/; do
    package_component "$dir" "extension.yml"
  done
fi

info "done. zips in $OUT_DIR/"
