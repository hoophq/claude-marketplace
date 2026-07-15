#!/bin/sh
# PostToolUse pipeline for the Hoop plugin: julius compresses, alcatraz
# masks — composed in ONE hook because two updatedToolOutput writers on the
# same event race (last to finish wins, non-deterministically).
#
# Fail-open at every level: no alcatraz → julius runs alone (pre-masking
# behavior); no julius → alcatraz masks alone; neither → no-op.
#
# Env knobs:
#   HOOP_PII_MASK_DISABLE=1   skip masking (julius still compresses)
#   HOOP_JULIUS_DISABLE=1     skip compression (alcatraz still masks)
#   HOOP_PII_MASK_THRESHOLD   min confidence (default 0.5)
#   HOOP_PII_MASK_IGNORE      entity types to ignore (default DATE_TIME,URL,IP_ADDRESS)
#   HOOP_PII_MASK_READ=1      also mask Read outputs — off by default: fresh
#                             file content feeds the agent's exact-match edits
set -u

# find_tool BINARY OVERRIDE — env override, then PATH, then common dirs.
find_tool() {
  if [ -n "$2" ]; then
    echo "$2"
    return
  fi
  command -v "$1" 2>/dev/null && return
  for c in "/opt/homebrew/bin/$1" "/usr/local/bin/$1" "${HOME:-/nonexistent}/.local/bin/$1" "${HOME:-/nonexistent}/go/bin/$1"; do
    if [ -x "$c" ]; then
      echo "$c"
      return
    fi
  done
}

ALCATRAZ=$(find_tool alcatraz "${HOOP_ALCATRAZ_BIN:-}")
JULIUS=$(find_tool julius "${HOOP_JULIUS_BIN:-}")
[ -n "$ALCATRAZ" ] && [ -x "$ALCATRAZ" ] || ALCATRAZ=""
[ -n "$JULIUS" ] && [ -x "$JULIUS" ] || JULIUS=""
if [ -n "${HOOP_JULIUS_DISABLE:-}" ]; then
  JULIUS=""
fi

if [ -n "${HOOP_PII_MASK_DISABLE:-}" ] || [ -z "$ALCATRAZ" ]; then
  if [ -n "$JULIUS" ]; then
    exec "$JULIUS" hook claude-post
  fi
  exit 0
fi

skip="Read"
if [ -n "${HOOP_PII_MASK_READ:-}" ]; then
  skip=""
fi

if [ -n "$JULIUS" ]; then
  exec "$ALCATRAZ" hook claude-post \
    -threshold "${HOOP_PII_MASK_THRESHOLD:-0.5}" \
    -ignore "${HOOP_PII_MASK_IGNORE:-DATE_TIME,URL,IP_ADDRESS}" \
    -skip-tools "$skip" \
    -chain "$JULIUS hook claude-post"
fi
exec "$ALCATRAZ" hook claude-post \
  -threshold "${HOOP_PII_MASK_THRESHOLD:-0.5}" \
  -ignore "${HOOP_PII_MASK_IGNORE:-DATE_TIME,URL,IP_ADDRESS}" \
  -skip-tools "$skip"
