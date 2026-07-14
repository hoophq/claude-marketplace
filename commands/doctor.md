---
description: Check Hoop plugin health — tool binaries, versions, and hook wiring
allowed-tools: Bash(command -v:*), Bash(fence --version), Bash(cloak --version)
---

# Hoop doctor

Report the installation status of the Hoop toolbelt on this machine.

For each tool below, check whether the binary is on PATH with `command -v <binary>`, and if present get its version:

| Tool | Binary | Purpose |
| --- | --- | --- |
| Fence | `fence` | Guardrails for AI agents — blocks catastrophic tool calls |
| Cloak | `cloak` | Credential cloaking — real secrets never reach the model |

Present the results as a short table (tool, installed yes/no, version), followed by install hints for anything missing:

- Fence: `brew install hoophq/tap/fence` (macOS) or see https://github.com/hoophq/fence
- Cloak: see https://github.com/hoophq/cloak

> Note: this is the scaffolding stub. The full install/diagnostic flow — including Julius, Risk Analyzer, and Alcatraz, plus hook wiring and proxy health checks — lands with ATR-109.
