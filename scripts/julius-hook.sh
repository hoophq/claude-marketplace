#!/bin/sh
# Fail-open Julius wrapper for Claude Code hooks.
#
# Usage: julius-hook.sh pre|post
#   pre   PreToolUse — rewrites supported Bash commands through julius
#   post  PostToolUse — compresses native tool outputs
#
# Resolves the julius binary from HOOP_JULIUS_BIN, then PATH, then common
# install locations. Missing binary = no rewrite and no noise (the agent
# runs the original command; /hoop:doctor reports the gap).
# HOOP_JULIUS_DISABLE=1 turns the integration off without uninstalling.

if [ -n "${HOOP_JULIUS_DISABLE:-}" ]; then
  exit 0
fi

JULIUS="${HOOP_JULIUS_BIN:-}"
if [ -z "$JULIUS" ]; then
  JULIUS="$(command -v julius 2>/dev/null)"
fi
if [ -z "$JULIUS" ]; then
  for c in /opt/homebrew/bin/julius /usr/local/bin/julius "$HOME/.local/bin/julius" "$HOME/go/bin/julius"; do
    if [ -x "$c" ]; then
      JULIUS="$c"
      break
    fi
  done
fi

if [ -n "$JULIUS" ] && [ -x "$JULIUS" ]; then
  case "${1:-pre}" in
    post) exec "$JULIUS" hook claude-post ;;
    *) exec "$JULIUS" hook claude-pre ;;
  esac
fi

exit 0
