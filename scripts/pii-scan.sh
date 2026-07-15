#!/bin/sh
# Alcatraz wrapper for the /hoop:pii-scan command.
#
# Usage: pii-scan.sh [path ... | -]
#   (default)  scan the git diff vs HEAD (added lines only)
#   path ...   scan these files line by line
#   -          read text on stdin (pasted content)
#
# Resolves the alcatraz binary from HOOP_ALCATRAZ_BIN, then PATH, then common
# install locations. The confidence threshold defaults to 0.4 — emails score
# 0.50, so the CI-style 0.8 would miss them (HOOP_PII_THRESHOLD overrides);
# a .pii-allowlist file in the cwd is applied automatically. Detected values
# are always masked. Always exits 0 — this is a report, not a gate.
set -u

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
  dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
  echo "MISSING  alcatraz — the PII scanner is not installed; offer to run '$dir/install-tool.sh alcatraz' (one script, no sudo)"
  exit 0
fi

threshold="${HOOP_PII_THRESHOLD:-0.4}"

# A .pii-allowlist in the cwd applies automatically (same convention as
# alcatraz-action). ${allowlist:+...} splices the flag pair in only when set.
allowlist=""
if [ -f .pii-allowlist ]; then
  echo "NOTE     applying the allowlist in .pii-allowlist"
  allowlist=".pii-allowlist"
fi

# run_alcatraz reports only real failures: alcatraz exits 1 when it finds
# PII, which is a successful scan, not an error.
run_alcatraz() {
  "$@"
  rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "ERROR    alcatraz exited with an error (code $rc) — results may be incomplete"
  fi
}

if [ $# -eq 0 ]; then
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR    not in a git repository and no paths given — pass file paths to scan, or '-' for stdin"
    exit 0
  fi
  # `git diff HEAD` covers staged + unstaged; on an unborn HEAD (no commits
  # yet) it fails, so fall back to the unstaged diff.
  diff=$(git diff HEAD 2>/dev/null) || diff=$(git diff)
  if [ -z "$diff" ]; then
    echo "OK       nothing to scan: the working tree matches HEAD (untracked files are not in the diff — pass their paths to scan them)"
    exit 0
  fi
  printf '%s\n' "$diff" | run_alcatraz "$ALCATRAZ" diff -threshold "$threshold" ${allowlist:+-allowlist-file "$allowlist"}
elif [ "$1" = "-" ]; then
  run_alcatraz "$ALCATRAZ" scan -threshold "$threshold" ${allowlist:+-allowlist-file "$allowlist"}
else
  run_alcatraz "$ALCATRAZ" scan -threshold "$threshold" ${allowlist:+-allowlist-file "$allowlist"} "$@"
fi
exit 0
