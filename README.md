# Hoop plugin for Claude Code

Hoop's toolbelt for Claude Code and Claude-based agents, in a single install: agent guardrails, credential cloaking, session risk analysis, token savings, and PII detection.

> **Status: early.** Fence guardrails and Julius token savings are live; the other tool integrations are landing one by one (see [What's in the box](#whats-in-the-box)).

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

> Already ran `fence init` before installing the plugin? Run `fence uninstall` — the plugin ships the same hooks, so the settings-level copy just duplicates evaluation. `/hoop:doctor` detects this and offers the fix.

## What's in the box

| Tool | What it does | Status |
| --- | --- | --- |
| [Fence](https://github.com/hoophq/fence) | Guardrails that block catastrophic agent tool calls (`rm -rf ~`, secret exfil, `curl \| sh`, force-push) before they run — semantic shell analysis, near-zero false positives | ✅ live |
| [Cloak](https://github.com/hoophq/cloak) | Local proxy that hands the agent a fake localhost DSN so real credentials never reach the model | ATR-113 |
| Risk Analyzer | Post-session diagnostics surfacing the infrastructure risks an agent session introduced | ATR-112 |
| [Julius](https://github.com/hoophq/julius) | Token savings on supported commands via transparent command routing — measured, never lossy where it matters | ✅ live |
| Alcatraz | In-process, known-pattern PII detection — no service, network, or model download | ATR-114 |

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
