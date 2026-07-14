# Hooks

Hook configuration for the Hoop toolbelt lands here as `hooks.json`.

Planned wiring (see the Linear project for status):

- **Fence** (`PreToolUse` on `Bash`) — evaluate every shell command before execution and deny catastrophic ones with a reason (ATR-110). Fence already ships hook scripts via `fence init`; the plugin reuses them so rules stay in one place.
- **Julius** (`PreToolUse` on `Bash`) — rewrite supported commands to route through Julius and cut token consumption (ATR-111).
- **Binary check** (`SessionStart`) — detect missing tool binaries and offer install (ATR-109).

No `hooks.json` yet: the scaffold intentionally ships hook-free so the empty shell loads without side effects.
