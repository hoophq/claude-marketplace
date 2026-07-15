# Marketplace listing — maintainer notes

How to get the plugin discoverable wherever Claude Code plugins are browsed. This is a maintainer document, not user docs.

## Where plugins are discoverable

- **Anthropic's community marketplace** (`anthropics/claude-plugins-community`) — reviewed submissions, browsable at [claude.com/plugins](https://claude.com/plugins) alongside the curated official set. This is the one worth submitting to.
- **The curated official marketplace** (`claude-plugins-official`) — Anthropic-selected, not open for submissions.
- **Self-hosted marketplaces** (like this repo) — installable by anyone via `/plugin marketplace add hoophq/claude-marketplace`, but not centrally listed.

## How to submit (needs a maintainer's account)

Use either in-app form:

- claude.ai: `claude.ai/admin-settings/directory/submissions/plugins/new`
- Console: `platform.claude.com/plugins/submit`

Approved plugins get pinned into the community catalog (`anthropics/claude-plugins-community` → `.claude-plugin/marketplace.json`).

## Listing copy (honesty-notes compliant)

**Name:** Hoop — guardrails, PII masking & risk analysis for agents

**Short description (~140 chars):**
> Block catastrophic tool calls, mask PII before the model sees it, scan sessions for leaks, cut token spend — one install, all local.

**Long description:**
> Hoop's toolbelt for Claude Code in a single install:
>
> - **Fence** blocks catastrophic tool calls (`rm -rf ~`, secret exfiltration, `curl | sh`, force-pushes) before they run — semantic shell analysis with near-zero false positives, active even in auto-accept sessions.
> - **Alcatraz** masks PII in tool outputs *before they reach the model* and warns when your own prompt carries personal data — known-pattern detection (45 entity types, checksum-validated where formats allow), fully in-process. `/hoop:pii-scan` checks diffs and files on demand.
> - **Risk Analyzer** (`/hoop:risk-report`) scans your local session history for leaked PII and secrets, entirely on your machine, with shareable value-free reports.
> - **Julius** cuts token consumption on supported commands — typically 60–90%, measured per command.
>
> Binaries install themselves on demand (checksum-verified, no sudo); everything fails open, so a missing tool never breaks your session. `/hoop:doctor` keeps it all healthy.

**Keywords:** security, guardrails, PII, privacy, token-savings, risk

## Review-readiness checklist

- [x] `plugin.json`: name, version, description, author, homepage, repository, license, keywords — all present
- [x] `marketplace.json` valid (`claude plugin validate .` in CI on every push)
- [x] Hooks fail open — a missing binary never breaks a session (CI-tested on ubuntu + macos)
- [x] No network calls from the plugin itself; binaries download checksum-verified from GitHub releases
- [x] Honesty notes held throughout the copy: Julius savings scoped to *supported commands* and *measured*; Fence's semantic claim verified against its parse-based rule engine; Alcatraz framed as *known-pattern* detection, not a secrets scanner
- [ ] Submit via one of the forms above (maintainer account required)
- [ ] After approval: add the community-marketplace install line to the README install section
