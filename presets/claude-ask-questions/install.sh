#!/usr/bin/env bash
# Generate the merged commands then install the preset.
# Usage: install.sh [--core-dir DIR] [--model MODEL]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/generate.sh" "$@"
specify preset add --dev "$SCRIPT_DIR"
