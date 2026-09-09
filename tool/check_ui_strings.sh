#!/usr/bin/env bash
# UI revamp audit — run after every revamp wave.
#
# Tracks mechanical design-debt counts (raw colors, glass, gradients) and copy
# migration progress. With --strict, fails when any count exceeds the cap
# recorded in tool/revamp_baseline.env. Lower the caps after each wave;
# a regression above the cap means new debt was reintroduced.
#
# Usage:
#   tool/check_ui_strings.sh            # report only
#   tool/check_ui_strings.sh --strict   # exit 1 if caps exceeded

set -euo pipefail
cd "$(dirname "$0")/.."

BASELINE="tool/revamp_baseline.env"
if [[ -f "$BASELINE" ]]; then
  # shellcheck disable=SC1090
  source "$BASELINE"
fi
: "${CAP_RAW_COLORS:=999999}"
: "${CAP_GLASS_FILES:=999999}"
: "${CAP_GRADIENT_FILES:=999999}"
: "${CAP_BACKDROP_SITES:=999999}"

count_files() { grep -rl "$1" $2 --include='*.dart' 2>/dev/null | wc -l; }
count_total() { grep -rEc "$1" $2 --include='*.dart' 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}'; }

RAW_COLORS=$(grep -rEc 'Color\(0x' lib/Screens lib/Components lib/Config --include='*.dart' 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')
GLASS_FILES=$(grep -rl 'GlassContainer' lib --include='*.dart' 2>/dev/null | wc -l)
GRADIENT_FILES=$(grep -rl 'LinearGradient\|RadialGradient' lib/Screens lib/Components --include='*.dart' 2>/dev/null | wc -l)
BACKDROP=$(grep -rc 'BackdropFilter' lib --include='*.dart' 2>/dev/null | grep -v ':0$' | awk -F: '{s+=$NF} END {print s+0}')
INTEG_LITERALS=$(grep -rhoE "find\.text\('[^']+'\)" integration_test 2>/dev/null | sort -u | wc -l)

echo "── UI Revamp Audit ──────────────────────────────"
printf 'Raw Color(0x…) literals : %5d   (cap %s)\n' "$RAW_COLORS"   "$CAP_RAW_COLORS"
printf 'GlassContainer files    : %5d   (cap %s)\n' "$GLASS_FILES"  "$CAP_GLASS_FILES"
printf 'Gradient files          : %5d   (cap %s)\n' "$GRADIENT_FILES" "$CAP_GRADIENT_FILES"
printf 'BackdropFilter sites    : %5d   (cap %s)\n' "$BACKDROP"     "$CAP_BACKDROP_SITES"
printf 'Integration text literals (unique, migration tracker): %d\n' "$INTEG_LITERALS"

rc=0
[[ $RAW_COLORS    -gt $CAP_RAW_COLORS    ]] && { echo "FAIL: raw color literals exceed cap"; rc=1; }
[[ $GLASS_FILES   -gt $CAP_GLASS_FILES   ]] && { echo "FAIL: GlassContainer usage exceeds cap"; rc=1; }
[[ $GRADIENT_FILES -gt $CAP_GRADIENT_FILES ]] && { echo "FAIL: gradient files exceed cap"; rc=1; }
[[ $BACKDROP      -gt $CAP_BACKDROP_SITES ]] && { echo "FAIL: BackdropFilter sites exceed cap"; rc=1; }
[[ $rc -eq 0 ]] && echo "OK: all caps respected."
exit $rc
