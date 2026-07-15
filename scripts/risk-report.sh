#!/bin/sh
# Risk Analyzer wrapper for the /hoop:risk-report command.
#
# Usage: risk-report.sh [all]
#   (default)  scan only the current Claude Code session
#   all        scan every local AI session (Claude Code, Cursor, OpenCode), all time
#
# Resolves the hooprs binary from HOOP_HOOPRS_BIN, then PATH, then common
# install locations. Reports land under ~/.risk-analyzer/reports (hooprs
# already keeps its state in ~/.risk-analyzer) and never auto-open; they
# carry entity types and counts, never the matched values.
# Always exits 0 — this is a report, not a gate.
set -u

# Fail open even without HOME: binary discovery and the report dir both
# dereference it, and set -u would otherwise abort mid-script.
if [ -z "${HOME:-}" ]; then
  echo "ERROR    HOME is not set — cannot locate hooprs or write reports"
  exit 0
fi

HOOPRS="${HOOP_HOOPRS_BIN:-}"
if [ -z "$HOOPRS" ]; then
  HOOPRS="$(command -v hooprs 2>/dev/null)"
fi
if [ -z "$HOOPRS" ]; then
  for c in /opt/homebrew/bin/hooprs /usr/local/bin/hooprs "$HOME/.local/bin/hooprs" "$HOME/go/bin/hooprs"; do
    if [ -x "$c" ]; then
      HOOPRS="$c"
      break
    fi
  done
fi

if [ -z "$HOOPRS" ] || [ ! -x "$HOOPRS" ]; then
  dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
  echo "MISSING  hooprs — the Risk Analyzer is not installed; offer to run '$dir/install-tool.sh hooprs' (one script, no sudo)"
  exit 0
fi

reports="$HOME/.risk-analyzer/reports"
mkdir -p "$reports"
stamp=$(date +%Y%m%d-%H%M%S)

case "${1:-session}" in
  all)
    html="$reports/all-$stamp.html"
    json="$reports/all-$stamp.json"
    "$HOOPRS" -open=false -out "$html" -json "$json" ||
      { echo "ERROR    hooprs exited with an error — the report may be missing or incomplete"; exit 0; }
    ;;
  *)
    if [ -z "${CLAUDE_CODE_SESSION_ID:-}" ]; then
      echo "ERROR    cannot identify the current session (CLAUDE_CODE_SESSION_ID is not set) — run '$0 all' to scan every session instead"
      exit 0
    fi
    html="$reports/session-${CLAUDE_CODE_SESSION_ID%%-*}-$stamp.html"
    json="$reports/session-${CLAUDE_CODE_SESSION_ID%%-*}-$stamp.json"
    "$HOOPRS" -tools claude -session "^${CLAUDE_CODE_SESSION_ID}\$" -open=false -out "$html" -json "$json" ||
      { echo "ERROR    hooprs exited with an error — the report may be missing or incomplete"; exit 0; }
    ;;
esac

echo "REPORT   html: $html"
echo "REPORT   json: $json"
