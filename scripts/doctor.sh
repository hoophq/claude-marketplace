#!/bin/sh
# Hoop toolbelt status report. Read-only. One line per finding, prefixed
# OK / MISSING / INFO / NOTE, so both humans and the doctor command can
# read it at a glance. Always exits 0 — this is a report, not a gate.
set -u

# Resolve a binary the way the hook wrapper does: PATH, then common
# install dirs (GUI-launched apps often miss /opt/homebrew/bin).
find_bin() {
  command -v "$1" 2>/dev/null && return 0
  for c in "/opt/homebrew/bin/$1" "/usr/local/bin/$1" "$HOME/.local/bin/$1" "$HOME/go/bin/$1"; do
    if [ -x "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

echo "Hoop toolbelt status — $(uname -s) $(uname -m)"

if fence_bin=$(find_bin fence); then
  echo "OK       fence $("$fence_bin" version 2>/dev/null || echo '(version unknown)') at $fence_bin — guardrails active"
else
  case "$(uname -s)" in
    Darwin | Linux)
      echo "MISSING  fence — guardrails are OFF; this plugin's 'install-tool.sh fence' script fixes it (no sudo)"
      ;;
    *)
      echo "MISSING  fence — no native support on this OS yet; use WSL (hoophq/fence#26)"
      ;;
  esac
fi

if julius_bin=$(find_bin julius); then
  echo "OK       julius $("$julius_bin" --version 2>/dev/null | awk '{print $NF; exit}' || echo '(version unknown)') at $julius_bin — token savings active on supported commands ('julius savings' shows the ledger)"
else
  echo "MISSING  julius (optional) — token savings off; install: brew install hoophq/tap/julius, or ask the agent to"
fi

if hooprs_bin=$(find_bin hooprs); then
  echo "OK       hooprs $("$hooprs_bin" -version 2>/dev/null || echo '(version unknown)') at $hooprs_bin — session risk analysis ready (/hoop:risk-report)"
else
  echo "MISSING  hooprs (optional) — session risk analysis off; /hoop:risk-report offers the install, or: brew install hoophq/tap/hooprs"
fi

if alcatraz_bin=$(find_bin alcatraz); then
  echo "OK       alcatraz $("$alcatraz_bin" version 2>/dev/null || echo '(version unknown)') at $alcatraz_bin — PII scanning (/hoop:pii-scan) and live output masking active"
  if [ -n "${HOOP_PII_MASK_DISABLE:-}" ]; then
    echo "NOTE     live PII masking is disabled via HOOP_PII_MASK_DISABLE — tool outputs enter context unmasked"
  fi
  if [ "${HOOP_PROMPT_GUARD:-warn}" = "off" ]; then
    echo "NOTE     the prompt PII guard is off via HOOP_PROMPT_GUARD"
  fi
else
  echo "MISSING  alcatraz (optional) — PII scanning and live output masking off; /hoop:pii-scan offers the install, or: brew install hoophq/tap/alcatraz"
fi

if cloak_bin=$(find_bin cloak); then
  # `cloak --version` prints "cloak X.Y.Z (commit …)"; keep just the version.
  echo "OK       cloak $("$cloak_bin" --version 2>/dev/null | awk '{print $2; exit}' || echo '(version unknown)') at $cloak_bin"
else
  echo "INFO     cloak not installed — optional; credential cloaking for engineers pointing agents at real infra (github.com/hoophq/cloak)"
fi

# fence init / julius init / rtk write settings-level hooks that duplicate
# (or fight with) this plugin's.
for f in "$HOME/.claude/settings.json" ".claude/settings.json" ".claude/settings.local.json"; do
  [ -f "$f" ] || continue
  if grep -q "fence hook claude-code" "$f" 2>/dev/null; then
    echo "NOTE     duplicate fence hooks in $f (from 'fence init') — the plugin already provides them; 'fence uninstall' removes the copy, the binary stays"
  fi
  # Only a real race when the julius binary exists — without it the
  # plugin's rewrite hook is a silent no-op.
  if [ -n "${julius_bin:-}" ] && grep -qE "(julius|rtk) hook claude" "$f" 2>/dev/null; then
    echo "NOTE     settings-level command-rewrite hooks in $f (julius init or rtk) — the plugin also rewrites; two rewriters race, so keep one: either remove the settings entry ('julius uninstall' / edit for rtk) or set HOOP_JULIUS_DISABLE=1 to silence the plugin's"
  fi
done

exit 0
