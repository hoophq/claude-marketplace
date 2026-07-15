#!/bin/sh
# UserPromptSubmit guard: warn (default) or block when the user's prompt
# itself carries PII. HOOP_PROMPT_GUARD=warn|block|off picks the mode; the
# threshold/ignore knobs are shared with the masking hook. Fail-open: no
# alcatraz binary means no guard, never a broken prompt.
set -u

mode="${HOOP_PROMPT_GUARD:-warn}"
case "$mode" in
  off) exit 0 ;;
  warn | block) ;;
  *) mode=warn ;;
esac

dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$dir/lib.sh"

ALCATRAZ=$(hoop_find_tool alcatraz "${HOOP_ALCATRAZ_BIN:-}")
if [ -z "$ALCATRAZ" ]; then
  exit 0
fi

exec "$ALCATRAZ" hook claude-prompt \
  -mode "$mode" \
  -threshold "${HOOP_PII_MASK_THRESHOLD:-0.5}" \
  -ignore "${HOOP_PII_MASK_IGNORE:-DATE_TIME,URL,IP_ADDRESS}"
