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

if [ "${1:-}" = "session-start" ]; then
  # Two audiences: the user gets a one-line hint; the agent gets context so
  # it can proactively offer the one-script setup (ATR-109 decision).
  dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
  printf '{"systemMessage":"🚧 Hoop: Fence not found — agent guardrails are off. Say yes when Claude offers to set it up, or run /hoop:doctor.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"The Hoop plugin is installed but the fence binary is missing, so Fence guardrails are inactive. Early in the session, offer to set it up for the user: run '\''%s/install-tool.sh fence'\'' with Bash — one script, no sudo; it picks Homebrew, npm, or a checksum-verified GitHub release download into ~/.local/bin. On success, guardrails apply to new tool calls immediately. If the user declines, do not raise it again this session."}}\n' "$dir"
fi
exit 0
