#!/usr/bin/env bash
# Local dev install: generate commands/ then register the preset.
# Usage: install.sh [--model MODEL] [--core-dir DIR]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/generate.sh" "$@"
specify preset add --dev "$SCRIPT_DIR"
