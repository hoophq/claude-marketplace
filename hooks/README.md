# Hooks

`hooks.json` wires the Hoop toolbelt into Claude Code's hook events.

## Fence — shipped

- **`PreToolUse`** on `Bash|Write|Edit|MultiEdit|NotebookEdit|WebFetch` → `scripts/fence-hook.sh` → `fence hook claude-code`. Every guarded tool call is evaluated before it runs: unambiguous catastrophes (recursive delete of home/root, secret exfil, `curl | sh`, force-push) are denied with a reason the agent sees; ambiguous cases ask for confirmation.
- **`SessionStart`** (`startup|resume|clear`) shows the Fence banner with the active rulepack/rule counts.
- **Fail-open**: if the `fence` binary is missing or errors, tool calls proceed and session start prints a one-line install hint instead. `/hoop:doctor` reports the binary status. Set `HOOP_FENCE_BIN` to point at a non-standard install location.
- **Quiet mode**: `HOOP_FENCE_QUIET=1` (in your environment or settings `env`) suppresses the per-call "allowed" notices, same as `fence init --quiet`; denials and asks always show.
- **Rules are configurable without touching this plugin**: Fence layers its embedded recommended pack, packs installed via `fence add`, a project-local `.fence.yaml`, and `--rules` files. See [hoophq/fence](https://github.com/hoophq/fence).
- Already ran `fence init`? Those settings-level hooks and this plugin's are the same thing — run `fence uninstall` to drop the settings copy and avoid double evaluation.

## Missing-binary flow — shipped

When fence is absent, the `SessionStart` hook emits two things: a one-line hint to the user, and `additionalContext` telling the agent to proactively offer the one-script setup (`scripts/install-tool.sh fence` — brew, npm, or checksum-verified release download to `~/.local/bin`, never sudo). `/hoop:doctor` drives the same flow on demand via `scripts/doctor.sh`; the same installer covers hooprs (`install-tool.sh hooprs`).

## Alcatraz live masking — shipped

- **`PostToolUse`** on `Bash|Grep|Glob|Read|WebFetch` → `scripts/post-tool.sh`. One hook composes both output rewriters — julius compresses, then `alcatraz hook claude-post` masks PII in the result via `updatedToolOutput` — because two rewriters registered side by side race (last to finish wins). The chain lives inside the alcatraz binary (`-chain`), so the composition is tested Go code, not shell JSON surgery.
- **Read outputs are not masked by default**: fresh file content feeds the agent's exact-match edits (julius has the same rule for the same reason). `HOOP_PII_MASK_READ=1` opts in. Path-carrying fields (Grep filenames etc.) are never masked — a masked path breaks every follow-up tool call on it.
- **`UserPromptSubmit`** → `scripts/prompt-guard.sh` → `alcatraz hook claude-prompt`: warns by default when the user's own prompt carries PII (the model is told not to repeat the values); `HOOP_PROMPT_GUARD=block` rejects the prompt with a masked view, `off` disables.
- **Knobs**: `HOOP_PII_MASK_DISABLE=1` (masking off, julius still compresses), `HOOP_PII_MASK_THRESHOLD` (0.5), `HOOP_PII_MASK_IGNORE` (`DATE_TIME,URL,IP_ADDRESS`). Fail-open everywhere: no alcatraz → julius alone; no julius → masking alone; internal errors → output passes through untouched.
- The masking summary reaches the model as `additionalContext` — what was masked, and that reconstruction must not be attempted. Unmasking is deliberate: view the data outside the session, or disable masking.

`/hoop:pii-scan` (→ `scripts/pii-scan.sh` → `alcatraz`) remains the on-demand scan.

## Risk Analyzer — command-only, deliberately no hook

`/hoop:risk-report` (→ `scripts/risk-report.sh` → `hooprs`) runs on demand. There is intentionally no automatic variant: `Stop` fires after every reply, so a scan per turn is pure noise, and `SessionEnd` output is never shown to anyone — the session is over. If an automatic report proves worth it, the shape would be an opt-in `SessionEnd` hook that silently writes the report file for later review.

## Julius — shipped

- **`PreToolUse`** on `Bash` → `scripts/julius-hook.sh pre` → `julius hook claude-pre`. Supported commands are rewritten to run through the julius wrapper (`git status` → `julius git status`), which executes the real command and filters the output — typically 60–90% token savings on supported commands. Unsupported commands pass through untouched; permission rules are respected.
- **`PostToolUse`** compression now runs through `scripts/post-tool.sh`, which chains `julius hook claude-post` ahead of alcatraz masking (see the Alcatraz section) — same compression semantics (errors/warnings always kept; fresh file content never rewritten), no rewriter race.
- **Fail-open and silent**: no julius binary means no rewrite and no noise — `/hoop:doctor` reports it. `HOOP_JULIUS_BIN` overrides discovery; `HOOP_JULIUS_DISABLE=1` switches the integration off.
- **Savings are measured**: `julius savings` shows the per-command ledger.
- Ran `julius init` before installing the plugin (or use rtk)? Two rewriters race — `/hoop:doctor` detects it and helps you keep exactly one.
