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

ALCATRAZ="${HOOP_ALCATRAZ_BIN:-}"
if [ -z "$ALCATRAZ" ]; then
  ALCATRAZ="$(command -v alcatraz 2>/dev/null)"
fi
if [ -z "$ALCATRAZ" ]; then
  for c in /opt/homebrew/bin/alcatraz /usr/local/bin/alcatraz "${HOME:-/nonexistent}/.local/bin/alcatraz" "${HOME:-/nonexistent}/go/bin/alcatraz"; do
    if [ -x "$c" ]; then
      ALCATRAZ="$c"
      break
    fi
  done
fi
if [ -z "$ALCATRAZ" ] || [ ! -x "$ALCATRAZ" ]; then
  exit 0
fi

exec "$ALCATRAZ" hook claude-prompt \
  -mode "$mode" \
  -threshold "${HOOP_PII_MASK_THRESHOLD:-0.5}" \
  -ignore "${HOOP_PII_MASK_IGNORE:-DATE_TIME,URL,IP_ADDRESS}"
