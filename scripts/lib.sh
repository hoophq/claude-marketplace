#!/bin/sh
# Shared helpers for Hoop plugin scripts. POSIX sh; source it, don't run it:
#
#   dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
#   . "$dir/lib.sh"

# hoop_find_tool BINARY [OVERRIDE] — resolve a tool binary the way every
# wrapper does: explicit override first, then PATH, then the common install
# dirs GUI-launched apps miss. Prints an executable path, or nothing when
# the tool is absent (a non-executable override also resolves to nothing —
# fail open, never fail loud).
hoop_find_tool() {
  if [ -n "${2:-}" ]; then
    if [ -x "$2" ]; then
      echo "$2"
    fi
    return 0
  fi
  if p=$(command -v "$1" 2>/dev/null); then
    echo "$p"
    return 0
  fi
  for c in "/opt/homebrew/bin/$1" "/usr/local/bin/$1" "${HOME:-/nonexistent}/.local/bin/$1" "${HOME:-/nonexistent}/go/bin/$1"; do
    if [ -x "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 0
}
