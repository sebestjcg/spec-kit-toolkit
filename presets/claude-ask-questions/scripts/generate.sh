#!/usr/bin/env bash
#
# generate.sh — re-apply the AskUserQuestion delta onto the CURRENT spec-kit core
# commands and write the merged result into ../commands/.
#
# This is what makes the preset core-update-safe: instead of freezing a full copy
# of speckit.clarify / speckit.checklist, we keep only the small semantic delta
# (../delta/*.delta.md) and surgically merge it into whatever core is installed,
# via `claude -p`. Run this after upgrading spec-kit core, then commit the result.
#
# Usage:
#   scripts/generate.sh [--core-dir DIR] [--model MODEL] [--check]
#
#   --core-dir DIR   Directory (searched recursively) holding the current core
#                    speckit.clarify.md / speckit.checklist.md. If omitted, a set
#                    of common locations is auto-detected (see find_core()).
#   --model MODEL    Model passed to `claude -p` (default: claude-sonnet-4-6).
#   --check          Generate to a temp file and diff against the committed
#                    command instead of overwriting (non-zero exit if they differ).
#
# Requires: bash, claude CLI on PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DELTA_DIR="$PRESET_DIR/delta"
OUT_DIR="$PRESET_DIR/commands"

CORE_DIR=""
MODEL="claude-sonnet-4-6"
CHECK=0

# Commands this preset overrides. Add a line here if the preset grows.
COMMANDS=(speckit.clarify speckit.checklist)

err()  { printf 'error: %s\n' "$*" >&2; }
info() { printf '• %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --core-dir) CORE_DIR="${2:?--core-dir needs a value}"; shift 2 ;;
    --model)    MODEL="${2:?--model needs a value}"; shift 2 ;;
    --check)    CHECK=1; shift ;;
    -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "unknown argument: $1"; exit 2 ;;
  esac
done

command -v claude >/dev/null 2>&1 || { err "the 'claude' CLI is not on PATH"; exit 1; }

# Resolve the current core file for a command name by searching likely locations.
# Echoes the resolved path on stdout, or exits non-zero if not found.
find_core() {
  local name="$1" base d hit
  base="$name.md"

  local roots=()
  [[ -n "$CORE_DIR" ]] && roots+=("$CORE_DIR")
  # Auto-detect: search from the project that contains this preset checkout, and CWD.
  roots+=(
    "$PWD"
    "$PWD/.specify/templates/commands"
    "$PWD/.claude/commands"
    "$PWD/templates/commands"
    "$PRESET_DIR/../../.specify/templates/commands"
  )

  for d in "${roots[@]}"; do
    [[ -d "$d" ]] || continue
    # Prefer an exact filename match closest to the root, but never pick a file
    # from inside this preset's own commands/ (that would merge against ourselves).
    hit="$(find "$d" -type f -name "$base" 2>/dev/null \
            | grep -v "$OUT_DIR/" \
            | grep -v "$DELTA_DIR/" \
            | sort | head -n1 || true)"
    [[ -n "$hit" ]] && { printf '%s\n' "$hit"; return 0; }
  done
  return 1
}

build_prompt() {
  local core_file="$1" delta_file="$2"
  cat <<EOF
You are applying a semantic patch to a spec-kit command file.

Below are two documents:
  1. CORE COMMAND — the current, authoritative command file.
  2. DELTA — a description of the ONLY edits to apply.

Apply the delta to the core command and output the resulting merged file.

Hard requirements:
- Output ONLY the merged command file content. No commentary, no explanation,
  and do NOT wrap it in a Markdown code fence.
- Apply ONLY the transforms described in the DELTA. Preserve every other
  character of the CORE COMMAND exactly — front matter, scripts, headings,
  ordering, and whitespace included.
- If a transform's target block is not present in the CORE COMMAND, skip it.

===== CORE COMMAND =====
$(cat "$core_file")
===== END CORE COMMAND =====

===== DELTA =====
$(cat "$delta_file")
===== END DELTA =====
EOF
}

# Strip a single leading/trailing Markdown code fence if the model added one.
strip_fence() {
  awk '
    NR==1 && /^```/ {skip_first=1; next}
    {lines[++n]=$0}
    END {
      end=n
      if (skip_first && lines[n] ~ /^```[a-zA-Z]*$/) end=n-1
      for (i=1;i<=end;i++) print lines[i]
    }'
}

status=0
for name in "${COMMANDS[@]}"; do
  delta_file="$DELTA_DIR/$name.delta.md"
  [[ -f "$delta_file" ]] || { err "missing delta: $delta_file"; status=1; continue; }

  if ! core_file="$(find_core "$name")"; then
    err "could not locate current core for '$name' (pass --core-dir)"
    status=1
    continue
  fi
  info "$name: merging delta into $core_file"

  tmp="$(mktemp)"
  build_prompt "$core_file" "$delta_file" \
    | claude -p --model "$MODEL" \
    | strip_fence > "$tmp"

  if [[ ! -s "$tmp" ]]; then
    err "$name: claude produced empty output"
    rm -f "$tmp"; status=1; continue
  fi

  out="$OUT_DIR/$name.md"
  if [[ "$CHECK" -eq 1 ]]; then
    if diff -u "$out" "$tmp" >&2; then
      info "$name: up to date"
    else
      err "$name: committed command differs from freshly generated output"
      status=1
    fi
    rm -f "$tmp"
  else
    mv "$tmp" "$out"
    info "$name: wrote $out"
  fi
done

exit "$status"
