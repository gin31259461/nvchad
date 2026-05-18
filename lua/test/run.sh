#!/usr/bin/env bash
# ── test/run.sh ───────────────────────────────────────────────────────────────
# Run individual spec files via plenary.busted in headless Neovim.
# For running the full suite, prefer: make test
#
# Usage:
#   bash lua/test/run.sh                                  # run all *_spec.lua
#   bash lua/test/run.sh lua/test/spec/str_spec.lua       # run a single file

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MINIMAL_VIM="$REPO_ROOT/scripts/tests/minimal.vim"

PASS=0
FAIL=0
FILES=()

if [ "$#" -gt 0 ]; then
    FILES=("$@")
else
    while IFS= read -r -d '' f; do
        FILES+=("$f")
    done < <(find "$SCRIPT_DIR/spec" -name "*_spec.lua" -print0 | sort -z)
fi

for f in "${FILES[@]}"; do
    echo ""
    echo "══ $(basename "$f") ══"
    if NVIM_SPEC_FILE="$f" nvim --headless --noplugin -u "$MINIMAL_VIM" \
        -c "lua require('plenary.busted').run(os.getenv('NVIM_SPEC_FILE'))"; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "══ Totals: $PASS spec file(s) passed, $FAIL failed ══"
[ "$FAIL" -eq 0 ]
