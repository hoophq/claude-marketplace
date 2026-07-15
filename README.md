# Hoop plugin for Claude Code

Hoop's toolbelt for Claude Code and Claude-based agents, in a single install: agent guardrails, session risk analysis, token savings, and PII detection — with credential cloaking landing next.

> **New to terminals?** There's a [step-by-step guide for the Claude desktop app](docs/getting-started-desktop.md) — no command line needed.

## Install

In any Claude Code session (terminal, the desktop app's **Code** tab, or IDE):

```
/plugin marketplace add hoophq/claude-marketplace
/plugin install hoop@hooplabs
```

The install is user-level: it follows you across projects and sessions. Desktop and CLI each keep their own plugin installs, so run the two commands once per surface you use.

Start a new session and the plugin is live. Binaries install themselves on demand: when `fence` is missing, Claude offers a one-script setup — no sudo; it picks Homebrew, npm, or a checksum-verified download from GitHub releases into `~/.local/bin`, where the plugin finds it without PATH changes. `/hoop:doctor` re-checks everything and fixes gaps whenever you ask.

## Quick starts

### 🚧 Fence — block catastrophic tool calls before they run

Every risky tool call is evaluated before execution: unambiguous catastrophes (recursive home deletion, secret exfiltration, `curl | sh`, force-pushes) are denied with a reason the agent sees; ambiguous cases ask you first. Fence parses what a command actually *does* — `rm -rf ~`, `rm -fr ~`, and `sudo rm -rf $HOME` are one intent, all caught — while everyday commands (`rm -rf node_modules`, `git push --force-with-lease`) pass untouched. Because agent hooks run before the permission system, Fence holds even in auto-accept sessions.

**Try it:** ask the agent to delete your home directory. Watch it bounce, with a 🚧 notice naming the rule.

- The 🚧 status line confirms guardrails are active for the whole session
- Rules are yours to layer, without touching the plugin: `fence add <pack>`, a project-local `.fence.yaml`, or `--rules` files — see [hoophq/fence](https://github.com/hoophq/fence)
- `HOOP_FENCE_QUIET=1` hides the per-call "allowed" notices; denials and asks always show
- Ran `fence init` before installing the plugin? `fence uninstall` drops the duplicate settings-level hooks — `/hoop:doctor` detects this and offers the fix

### 💸 Julius — token savings on supported commands

Supported command outputs compress before they enter the model's context — typically 60–90% on supported commands, and the savings are measured, not estimated: `julius savings` shows the per-command ledger. Unsupported commands run exactly as before; errors and warnings are always kept; fresh file content is never rewritten. No julius installed, no change.

**Try it:** `brew install hoophq/tap/julius` (or ask the agent via `/hoop:doctor`), run a few git commands, then check `julius savings`.

- `HOOP_JULIUS_DISABLE=1` switches the integration off without uninstalling — see [hoophq/julius](https://github.com/hoophq/julius)
- Ran `julius init` (or use rtk)? Two rewriters would race — `/hoop:doctor` helps you keep exactly one

### 🔍 Risk Analyzer — what has your agent already seen?

`/hoop:risk-report` scans the current session's transcript for PII and secrets, entirely on your machine — no service, no API calls, nothing leaves your disk. `/hoop:risk-report all` covers every local AI session (Claude Code, Cursor, OpenCode), ranked by exposure so you triage the sessions that matter. The saved HTML report is value-free — entity types and counts, never the matched values — so sharing it with your team never re-leaks a leak.

**Try it:** run `/hoop:risk-report` after a real working session and open the report it saves.

- Detection is known-pattern with checksum validation where formats allow; secrets common in coding sessions are covered by [hooprs](https://github.com/hoophq/rs)'s own pack

### 🪨 Alcatraz — PII masked before the model sees it

Known-pattern PII detection (45 entity types across 12 countries, checksum-validated where formats allow — Luhn for cards, mod-97 for IBANs), fully in-process: no service, no network, no model download. It is deliberately not a secrets scanner — Fence guards exfiltration paths and the Risk Analyzer covers session leaks.

Two surfaces, both on automatically once the binary is installed:

- **Live masking** — PII in command and search outputs is masked *before it reaches the model* (`ja************om`), with a context note telling the agent what was hidden. Your own prompts are checked too: paste PII and you're warned the moment you send it. File reads stay untouched by default so the agent's edits keep working.
- **On-demand scans** — `/hoop:pii-scan` checks your git diff before you commit; pass file paths to scan files, or pipe pasted content. A `.pii-allowlist` keeps known-safe values quiet, and the same file drives [alcatraz-action](https://github.com/hoophq/alcatraz-action) in CI.

**Try it:** put an email address in a file you're changing, then `/hoop:pii-scan`.

- Knobs: `HOOP_PII_MASK_DISABLE=1` (masking off), `HOOP_PII_MASK_READ=1` (mask file reads too), `HOOP_PII_MASK_THRESHOLD` / `HOOP_PII_MASK_IGNORE` (tuning), `HOOP_PROMPT_GUARD=block|off` (prompt guard) — see [hoophq/alcatraz](https://github.com/hoophq/alcatraz)

## What's in the box

| Tool | What it does | Status |
| --- | --- | --- |
| [Fence](https://github.com/hoophq/fence) | Guardrails that block catastrophic agent tool calls (`rm -rf ~`, secret exfil, `curl \| sh`, force-push) before they run — semantic shell analysis, near-zero false positives | ✅ live |
| [Cloak](https://github.com/hoophq/cloak) | Local proxy that hands the agent a fake localhost DSN so real credentials never reach the model | ATR-113 |
| [Risk Analyzer](https://github.com/hoophq/rs) | Scans local AI sessions for leaked PII and secrets (`/hoop:risk-report`) — known-pattern detection with checksum validation, value-free shareable reports, nothing leaves your machine | ✅ live |
| [Julius](https://github.com/hoophq/julius) | Token savings on supported commands — typically 60–90%, measured per command, never lossy where it matters | ✅ live |
| [Alcatraz](https://github.com/hoophq/alcatraz) | In-process, known-pattern PII detection — live masking of tool outputs before they reach the model, a prompt guard, and on-demand scans (`/hoop:pii-scan`) | ✅ live |

## For teams & enterprises

**Rolling it out to a team.** Commit the plugin to a shared repo — `.claude/settings.json` with `extraKnownMarketplaces` and `enabledPlugins` — and everyone working in that repo gets it with their next session. On managed fleets, org admins can deploy it organization-wide through managed settings instead; the [desktop guide](docs/getting-started-desktop.md#on-a-company-computer) has the note to forward to IT.

**If your org disables plugins or hooks by policy** (managed settings like `strictKnownMarketplaces` or `allowManagedHooksOnly`): these local tools won't load, and that's usually deliberate. The same protections — guardrails, PII masking, session risk — exist as central, wire-level enforcement in the [hoop.dev](https://hoop.dev) gateway, where policy applies before data ever reaches an agent, for every user at once. That's the conversation to have with your platform team.

## Requirements

- Claude Code ≥ 2.0
- macOS or Linux (fence has no native Windows support yet — WSL works)
- No package manager needed: binaries install on demand via `/hoop:doctor` or the session-start offer

## Development

```bash
# validate manifests locally
claude plugin validate .

# try the plugin from a local checkout
claude plugin marketplace add /path/to/claude-marketplace
claude plugin install hoop@hooplabs
```

Repo layout: `.claude-plugin/` (plugin + marketplace manifests), `commands/` (slash commands), `hooks/` (hook config), `scripts/` (fail-open wrappers + installer), `skills/` (agent skills), `docs/` (guides).

## License

[MIT](LICENSE)
