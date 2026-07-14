# Hooks

`hooks.json` wires the Hoop toolbelt into Claude Code's hook events.

## Fence — shipped

- **`PreToolUse`** on `Bash|Write|Edit|MultiEdit|NotebookEdit|WebFetch` → `scripts/fence-hook.sh` → `fence hook claude-code`. Every guarded tool call is evaluated before it runs: unambiguous catastrophes (recursive delete of home/root, secret exfil, `curl | sh`, force-push) are denied with a reason the agent sees; ambiguous cases ask for confirmation.
- **`SessionStart`** (`startup|resume|clear`) shows the Fence banner with the active rulepack/rule counts.
- **Fail-open**: if the `fence` binary is missing or errors, tool calls proceed and session start prints a one-line install hint instead. `/hoop:doctor` reports the binary status. Set `HOOP_FENCE_BIN` to point at a non-standard install location.
- **Quiet mode**: `HOOP_FENCE_QUIET=1` (in your environment or settings `env`) suppresses the per-call "allowed" notices, same as `fence init --quiet`; denials and asks always show.
- **Rules are configurable without touching this plugin**: Fence layers its embedded recommended pack, packs installed via `fence add`, a project-local `.fence.yaml`, and `--rules` files. See [hoophq/fence](https://github.com/hoophq/fence).
- Already ran `fence init`? Those settings-level hooks and this plugin's are the same thing — run `fence uninstall` to drop the settings copy and avoid double evaluation.

## Planned

- **Julius** (`PreToolUse` on `Bash`) — token-saving command rewrites (ATR-111)
- **Binary install flow** (`SessionStart`) — detect missing tool binaries and offer install (ATR-109)
