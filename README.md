# Hoop plugin for Claude Code

Hoop's toolbelt for Claude Code and Claude-based agents, in a single install: agent guardrails, credential cloaking, session risk analysis, token savings, and PII detection.

> **Status: scaffolding.** The plugin shell installs and loads; tool integrations are landing one by one (tracked in Linear — see [What's in the box](#whats-in-the-box)).

## Install

In any Claude Code session (terminal, desktop app's Code mode, or IDE):

```
/plugin marketplace add hoophq/hoop-plugin-for-claude
/plugin install hoop@hoop
```

The install is user-level: it follows you across sessions and projects. Run `/hoop:doctor` afterwards to check which tool binaries are present.

## What's in the box

| Tool | What it does | Status |
| --- | --- | --- |
| [Fence](https://github.com/hoophq/fence) | Rules-based guardrails that block catastrophic agent tool calls (`rm -rf ~`, secret exfil, `curl \| sh`, force-push) before they run | ATR-110 |
| [Cloak](https://github.com/hoophq/cloak) | Local proxy that hands the agent a fake localhost DSN so real credentials never reach the model | ATR-113 |
| Risk Analyzer | Post-session diagnostics surfacing the infrastructure risks an agent session introduced | ATR-112 |
| Julius | Token savings on supported commands via transparent command routing | ATR-111 |
| Alcatraz | In-process, known-pattern PII detection — no service, network, or model download | ATR-114 |

## Requirements

- Claude Code ≥ 2.0
- Tool binaries install on demand (`/hoop:doctor` reports what's missing and how to get it)

## Development

```bash
# validate manifests locally
claude plugin validate .

# try the plugin from a local checkout
claude plugin marketplace add /path/to/hoop-plugin-for-claude
claude plugin install hoop@hoop
```

Repo layout: `.claude-plugin/` (plugin + marketplace manifests), `commands/` (slash commands), `hooks/` (hook config), `skills/` (agent skills).

## License

[MIT](LICENSE)
