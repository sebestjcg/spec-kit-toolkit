#!/usr/bin/env bash
#
# package.sh — build distributable zips for all presets and extensions in this repo,
# and optionally create a GitHub Release with those zips as assets.
#
# Each zip has its config file (preset.yml / extension.yml) at the root so that
# `specify preset add <id> --from <url>` / `specify extension add <id> --from <url>` work
# with GitHub Release assets.
#
# Usage:
#   scripts/package.sh [--out DIR] [--only <id>] [--no-release] [--tag TAG]
#
#   --out DIR       Output directory for zips (default: dist/)
#   --only ID       Package only the preset/extension with this id
#   --no-release    Build zips only, skip creating the GitHub Release
#   --tag TAG       Git tag to use for the release (default: auto-detected from HEAD)
#
# Zip filenames: <repo-name>-<type>-<version>.zip  (version comes from preset.yml / extension.yml)
# Requires: bash, python3 (stdlib only), gh.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_DIR/dist"
ONLY=""
RELEASE=1
TAG=""

err()  { printf 'error: %s\n' "$*" >&2; }
info() { printf '• %s\n' "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)     OUT_DIR="${2:?--out needs a value}"; shift 2 ;;
    --only)    ONLY="${2:?--only needs a value}";   shift 2 ;;
    --tag)     TAG="${2:?--tag needs a value}";     shift 2 ;;
    --no-release) RELEASE=0; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "unknown argument: $1"; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { err "'python3' is not on PATH"; exit 1; }
command -v specify >/dev/null 2>&1 || { err "'specify' is not on PATH"; exit 1; }
[[ "$RELEASE" -eq 1 ]] && { command -v gh >/dev/null 2>&1 || { err "'gh' is not on PATH (required for release — pass --no-release to skip)"; exit 1; }; }

# Stamp every preset.yml / extension.yml with the current spec-kit version.
speckit_version="$(specify --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
if [[ -n "$speckit_version" ]]; then
  info "spec-kit version: $speckit_version"
  for config in "$REPO_DIR"/presets/*/preset.yml "$REPO_DIR"/extensions/*/extension.yml; do
    [[ -f "$config" ]] || continue
    sed -i "s/^  version: \".*\"/  version: \"$speckit_version\"/" "$config"
  done
else
  err "could not detect spec-kit version — version fields left unchanged"
fi

# Auto-detect tag from HEAD if not provided.
if [[ "$RELEASE" -eq 1 && -z "$TAG" ]]; then
  TAG="$(git -C "$REPO_DIR" tag --points-at HEAD 2>/dev/null | tail -n1 || true)"
  [[ -n "$TAG" ]] || { err "no git tag on HEAD — create a tag first or pass --tag"; exit 1; }
  info "detected tag: $TAG"
fi

mkdir -p "$OUT_DIR"
ZIPS=()
INSTALL_LINES=()
GITHUB_SLUG="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//' || true)"

package_component() {
  local src_dir="$1" config_file="$2"
  local config="$src_dir/$config_file"
  [[ -f "$config" ]] || return 0

  local id version
  id="$(grep -E '^\s+id:' "$config" | head -n1 | sed 's/.*id:[[:space:]]*//' | tr -d '"')"
  version="$(grep -E '^\s+version:' "$config" | head -n1 | sed 's/.*version:[[:space:]]*//' | tr -d '"')"

  [[ -z "$id" || -z "$version" ]] && { err "could not read id/version from $config"; return 1; }
  [[ -n "$ONLY" && "$id" != "$ONLY" ]] && return 0

  local repo_name type zip_name
  repo_name="$(basename "$REPO_DIR")"
  type="${config_file%.yml}"
  zip_name="${repo_name}-${type}-${version}.zip"
  local zip_path="$OUT_DIR/$zip_name"

  info "packaging $id v$version → dist/$zip_name"

  python3 - "$src_dir" "$zip_path" <<'PYEOF'
import sys, zipfile, pathlib

src = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2])

EXCLUDE = {
  "scripts/generate.sh",
  "install.sh",
  ".git",
  ".DS_Store",
  "__pycache__",
}

def should_exclude(rel):
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

  ZIPS+=("$zip_path")
  if [[ -n "$TAG" && -n "$GITHUB_SLUG" ]]; then
    local from_url="https://github.com/$GITHUB_SLUG/releases/download/$TAG/$zip_name"
    printf '  specify %s add %s --from %s\n' "$type" "$id" "$from_url"
    INSTALL_LINES+=("specify $type add $id --from $from_url")
  fi
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

if [[ "$RELEASE" -eq 1 ]]; then
  [[ ${#ZIPS[@]} -gt 0 ]] || { err "no zips built — nothing to release"; exit 1; }
  info "creating GitHub Release $TAG..."
  install_notes="## Install"$'\n\n''```bash'$'\n'"$(printf '%s\n' "${INSTALL_LINES[@]}")"$'\n''```'
  gh release create "$TAG" "${ZIPS[@]}" \
    --repo "$GITHUB_SLUG" \
    --title "$TAG" \
    --notes "$install_notes" \
    --generate-notes
  info "release $TAG created with ${#ZIPS[@]} asset(s)"
fi
