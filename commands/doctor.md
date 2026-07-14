---
description: Check Hoop tool health and set up anything missing
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/install-fence.sh), Bash(fence uninstall)
---

# Hoop doctor

Check the health of the Hoop toolbelt on this machine and fix what's missing. The user may be non-technical — keep the language plain and the steps minimal.

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh` and relay the report conversationally (a short summary, not raw output). Line prefixes: `OK` healthy, `MISSING` needs action, `NOTE` worth surfacing, `INFO` optional context.

2. If fence is `MISSING`: offer to install it, and on a yes run `${CLAUDE_PLUGIN_ROOT}/scripts/install-fence.sh`. It is one script with no sudo — it picks Homebrew, npm, or a checksum-verified GitHub release download into `~/.local/bin` (the plugin finds it there; no PATH changes). On success, tell the user: guardrails protect new tool calls immediately, and the 🚧 banner appears from the next session.

3. If the report `NOTE`s duplicate fence hooks: explain that the plugin already provides the same hooks, and offer to run `fence uninstall` — it removes only the settings-level hook entries; the fence binary and its rules stay.

4. Cloak is optional: mention it only if the user asks or clearly works with databases/credentials — it's for engineers pointing agents at real infrastructure.

5. If an install fails, show the exact error line and the manual fallbacks: `brew install hoophq/tap/fence` or `npm install -g @hoophq/fence`, or downloading from https://github.com/hoophq/fence/releases. On native Windows, fence isn't supported yet — WSL works.

6. After any fix, re-run `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh` to confirm and show the final state.
