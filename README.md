# Hoop plugin for Claude Code

Hoop's toolbelt for Claude Code and Claude-based agents, in a single install: agent guardrails, credential cloaking, session risk analysis, token savings, and PII detection.

> **Status: early.** Fence guardrails, Julius token savings, Risk Analyzer session scans, and Alcatraz PII scanning are live; Cloak lands next (see [What's in the box](#whats-in-the-box)).

## Install

In any Claude Code session (terminal, desktop app's Code mode, or IDE):

```
/plugin marketplace add hoophq/claude-marketplace
/plugin install hoop@hooplabs
```

The install is user-level: it follows you across sessions and projects.

Then start a new session — that's it. If the `fence` binary is missing, Claude offers to set it up; say yes and one script (no sudo) installs it via Homebrew, npm, or a checksum-verified download from GitHub releases into `~/.local/bin` — the plugin finds it there, no PATH changes needed. Guardrails apply immediately; the 🚧 banner confirms from the next session. `/hoop:doctor` re-checks everything on demand.

Once guarded: catastrophic tool calls are blocked with a reason, ambiguous ones ask first. Try asking the agent to delete your home directory — watch it bounce.

Want token savings too? Install julius (`brew install hoophq/tap/julius`, or ask the agent via `/hoop:doctor`) and supported command outputs compress automatically — typically 60–90% on supported commands, measured honestly (`julius savings`). No julius, no change: commands run exactly as before.

Wondering what your agent has already seen? `/hoop:risk-report` scans the current session for leaked PII and secrets — or every local AI session with `/hoop:risk-report all` — entirely on your machine, and saves a shareable, value-free HTML report (entity types and counts, never the matched values). If the [hooprs](https://github.com/hoophq/rs) binary is missing, the command offers the same one-script install.

About to commit? `/hoop:pii-scan` checks your diff for PII before it lands — emails, credit cards, national IDs and more (45 known-pattern entity types across 12 countries), checksum-validated where formats allow, detected fully in-process with values always masked. Pass file paths to scan files instead, keep false positives quiet with a `.pii-allowlist`, and pair it with [alcatraz-action](https://github.com/hoophq/alcatraz-action) to enforce the same scan in CI.

And it works while you chat: with alcatraz installed, PII in command and search outputs is **masked live before it reaches the model** (`ja************om`), with a note telling the agent what was hidden — and if your own prompt contains PII, you get a warning the moment you send it. File reads stay untouched by default so edits keep working (`HOOP_PII_MASK_READ=1` extends masking there); `HOOP_PII_MASK_DISABLE=1` switches masking off, `HOOP_PROMPT_GUARD=block|off` tunes the prompt guard.

> Already ran `fence init` before installing the plugin? Run `fence uninstall` — the plugin ships the same hooks, so the settings-level copy just duplicates evaluation. `/hoop:doctor` detects this and offers the fix.

## What's in the box

| Tool | What it does | Status |
| --- | --- | --- |
| [Fence](https://github.com/hoophq/fence) | Guardrails that block catastrophic agent tool calls (`rm -rf ~`, secret exfil, `curl \| sh`, force-push) before they run — semantic shell analysis, near-zero false positives | ✅ live |
| [Cloak](https://github.com/hoophq/cloak) | Local proxy that hands the agent a fake localhost DSN so real credentials never reach the model | ATR-113 |
| [Risk Analyzer](https://github.com/hoophq/rs) | Scans local AI sessions for leaked PII and secrets (`/hoop:risk-report`) — known-pattern detection with checksum validation, value-free shareable reports, nothing leaves your machine | ✅ live |
| [Julius](https://github.com/hoophq/julius) | Token savings on supported commands via transparent command routing — measured, never lossy where it matters | ✅ live |
| [Alcatraz](https://github.com/hoophq/alcatraz) | In-process, known-pattern PII detection — live masking of tool outputs before they reach the model, a prompt guard, and on-demand scans (`/hoop:pii-scan`); no service, network, or model download | ✅ live |

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

Repo layout: `.claude-plugin/` (plugin + marketplace manifests), `commands/` (slash commands), `hooks/` (hook config), `skills/` (agent skills).

## License

[MIT](LICENSE)
