#!/bin/sh
# Fail-open Fence wrapper for Claude Code hooks.
#
# Resolves the fence binary from HOOP_FENCE_BIN, then PATH, then common
# install locations (GUI-launched apps often miss /opt/homebrew/bin).
# If fence is missing the hook must not break the session: tool calls
# proceed unguarded, and session start prints a one-line hint instead
# of the Fence banner.

FENCE="${HOOP_FENCE_BIN:-}"
if [ -z "$FENCE" ]; then
  FENCE="$(command -v fence 2>/dev/null)"
fi
if [ -z "$FENCE" ]; then
  for c in /opt/homebrew/bin/fence /usr/local/bin/fence "$HOME/.local/bin/fence" "$HOME/go/bin/fence"; do
    if [ -x "$c" ]; then
      FENCE="$c"
      break
    fi
  done
fi

if [ -n "$FENCE" ] && [ -x "$FENCE" ]; then
  # HOOP_FENCE_QUIET=1 suppresses the per-call "Fence allowed this" notices
  # (same as `fence init --quiet`); denials and asks always show.
  if [ "${1:-}" != "session-start" ] && [ -n "${HOOP_FENCE_QUIET:-}" ]; then
    set -- "$@" --quiet
  fi
  exec "$FENCE" hook claude-code "$@"
fi

if [ "$1" = "session-start" ]; then
  printf '{"systemMessage":"🚧 Hoop: Fence not found — agent guardrails are off. Install it with: brew install hoophq/tap/fence (then verify with /hoop:doctor)"}\n'
fi
exit 0
