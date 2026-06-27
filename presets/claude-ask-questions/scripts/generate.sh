#!/usr/bin/env bash
#
# generate.sh — re-apply the AskUserQuestion delta onto the CURRENT spec-kit core
# commands and write the merged result into ../commands/.
#
# Runs `specify init` in a temp directory to obtain the current core commands
# (matching the installed spec-kit version), then merges the delta via `claude -p`.
# Run this after upgrading spec-kit, then commit commands/ and tag a new release.
#
# Usage:
#   scripts/generate.sh [--core-dir DIR] [--model MODEL] [--check]
#
#   --core-dir DIR   Skip `specify init` and point directly at the .claude/skills/
#                    directory of an existing spec-kit project.
#   --model MODEL    Model passed to `claude -p` (default: claude-sonnet-4-6).
#   --check          Generate to a temp file and diff against the committed
#                    command instead of overwriting (non-zero exit if they differ).
#
# Requires: bash, specify CLI, claude CLI on PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DELTA_DIR="$PRESET_DIR/delta"
OUT_DIR="$PRESET_DIR/commands"

CORE_DIR=""
MODEL="claude-sonnet-4-6"
CHECK=0

# Maps output command name → skill directory name inside .claude/skills/
declare -A SKILL_DIR=(
  [speckit.clarify]=speckit-clarify
  [speckit.checklist]=speckit-checklist
)
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

command -v claude  >/dev/null 2>&1 || { err "'claude' CLI is not on PATH"; exit 1; }
command -v specify >/dev/null 2>&1 || { err "'specify' CLI is not on PATH"; exit 1; }

SCRATCH=""
cleanup() { [[ -n "$SCRATCH" ]] && rm -rf "$SCRATCH"; }
trap cleanup EXIT

# If no --core-dir given, bootstrap a scratch spec-kit project to get current core.
if [[ -z "$CORE_DIR" ]]; then
  SCRATCH="$(mktemp -d)"
  info "bootstrapping scratch spec-kit project to extract core commands..."
  specify init "$SCRATCH/core" --integration claude --script sh --no-git --ignore-agent-tools \
    >/dev/null 2>&1
  CORE_DIR="$SCRATCH/core/.claude/skills"
  info "core skills at $CORE_DIR"
fi

mkdir -p "$OUT_DIR"

# Locate the SKILL.md for a given command name under CORE_DIR.
find_core() {
  local name="$1" skill_dir hit
  skill_dir="${SKILL_DIR[$name]:-}"
  if [[ -n "$skill_dir" ]]; then
    hit="$CORE_DIR/$skill_dir/SKILL.md"
    [[ -f "$hit" ]] && { printf '%s\n' "$hit"; return 0; }
  fi
  # Fallback: search recursively (handles --core-dir pointing at commands/ directly)
  hit="$(find "$CORE_DIR" -type f \( -name "SKILL.md" -o -name "$name.md" \) 2>/dev/null \
          | grep -v "$OUT_DIR/" \
          | grep -v "$DELTA_DIR/" \
          | grep -i "${skill_dir:-$name}" \
          | sort | head -n1 || true)"
  [[ -n "$hit" ]] && { printf '%s\n' "$hit"; return 0; }
  return 1
}

build_prompt() {
  local core_file="$1" delta_file="$2"
  cat <<EOF
Apply the DELTA edits to the CORE COMMAND file and emit the result.

CRITICAL OUTPUT RULE: Your entire response must be the modified file content
and nothing else. Do not write any introduction, explanation, summary, or
commentary — not even a single sentence. The very first character of your
response must be the first character of the file (the opening "---" of the
YAML front matter). If you write anything before that, the output is broken.

Editing rules:
- Apply ONLY the transforms described in the DELTA.
- Preserve every other character of the CORE COMMAND exactly — front matter,
  scripts, headings, ordering, and whitespace included.
- Do NOT wrap the output in a Markdown code fence.
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
    err "could not locate core skill for '$name' under $CORE_DIR"
    status=1; continue
  fi
  info "$name: merging delta into $core_file"

  tmp="$(mktemp)"
  claude -p "$(build_prompt "$core_file" "$delta_file")" --model "$MODEL" \
    | strip_fence > "$tmp"

  if [[ ! -s "$tmp" ]]; then
    err "$name: claude produced empty output"
    rm -f "$tmp"; status=1; continue
  fi

  # Validate output looks like a command file, not a commentary summary.
  if ! head -n1 "$tmp" | grep -q '^---'; then
    err "$name: output does not start with YAML front matter ('---') — claude wrote commentary instead of the file"
    err "  first line: $(head -n1 "$tmp")"
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
