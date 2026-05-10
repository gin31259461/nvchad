#!/usr/bin/env bash
# ── spec/run.sh ───────────────────────────────────────────────────────────────
# Run NvChad config spec files via Neovim headless mode.
#
# Usage:
#   bash spec/run.sh              # run all *_spec.lua files under spec/
#   bash spec/run.sh spec/utils/str_spec.lua   # run a single file

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NVIM_SPEC_DIR="$SCRIPT_DIR"

PASS=0
FAIL=0
FILES=()

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  while IFS= read -r -d '' f; do
    FILES+=("$f")
  done < <(find "$SCRIPT_DIR" -name "*_spec.lua" -print0 | sort -z)
fi

for f in "${FILES[@]}"; do
  echo ""
  echo "══ $(basename "$f") ══"
  if nvim --headless -l "$f"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "══ Totals: $PASS spec file(s) passed, $FAIL failed ══"
[ "$FAIL" -eq 0 ]
