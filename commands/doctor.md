---
description: Check Hoop tool health and set up anything missing
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/install-tool.sh:*), Bash(fence uninstall), Bash(brew install hoophq/tap/julius), Bash(julius savings)
---

# Hoop doctor

Check the health of the Hoop toolbelt on this machine and fix what's missing. The user may be non-technical — keep the language plain and the steps minimal.

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh` and relay the report conversationally (a short summary, not raw output). Line prefixes: `OK` healthy, `MISSING` needs action, `NOTE` worth surfacing, `INFO` optional context.

2. If fence is `MISSING`: offer to install it, and on a yes run `${CLAUDE_PLUGIN_ROOT}/scripts/install-tool.sh fence`. It is one script with no sudo — it picks Homebrew, npm, or a checksum-verified GitHub release download into `~/.local/bin` (the plugin finds it there; no PATH changes). On success, tell the user: guardrails protect new tool calls immediately, and the 🚧 banner appears from the next session.

3. If the report `NOTE`s duplicate fence hooks: explain that the plugin already provides the same hooks, and offer to run `fence uninstall` — it removes only the settings-level hook entries; the fence binary and its rules stay.

4. If julius is `MISSING` and the user is interested in token savings: offer `brew install hoophq/tap/julius` (macOS/Linux with brew) or julius's installer from https://github.com/hoophq/julius. Once installed, supported command outputs compress automatically and `julius savings` shows the measured ledger. If a `NOTE` reports racing rewriters, help the user pick one (settings-level entry vs the plugin's; `HOOP_JULIUS_DISABLE=1` silences the plugin side).

5. If hooprs is `MISSING` and the user is interested in knowing what sensitive data their AI sessions have seen: offer to install it via `${CLAUDE_PLUGIN_ROOT}/scripts/install-tool.sh hooprs` (same one-script flow as fence). Once installed, `/hoop:risk-report` scans the current session — or `all` sessions — for leaked PII and secrets, entirely on this machine.

6. Cloak is optional: mention it only if the user asks or clearly works with databases/credentials — it's for engineers pointing agents at real infrastructure.

7. If an install fails, show the exact error line and the manual fallbacks: `brew install hoophq/tap/fence` or `npm install -g @hoophq/fence` (for hooprs: `brew install hoophq/tap/hooprs` or `npm install -g @hoophq/rs`), or downloading from the tool's GitHub releases page. On native Windows, fence isn't supported yet — WSL works.

8. After any fix, re-run `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh` to confirm and show the final state.
