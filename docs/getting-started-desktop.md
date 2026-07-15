# Get protected in ten minutes — the Claude desktop app guide

This guide is for people who don't live in a terminal. By the end, Claude will refuse to run catastrophic commands on your computer — deleting your files, leaking your keys — and you'll see a 🚧 banner confirming the guardrails are on. No command line, no admin password.

**You need:** the [Claude desktop app](https://claude.com/download) and a Claude account (Pro, Max, Team, or Enterprise). On a Mac or Linux machine this guide just works; on Windows, the guardrails engine currently needs WSL — ask IT, or see [the note below](#on-a-company-computer).

## Step 1 — Open the Code tab

The desktop app has three tabs: **Chat**, **Cowork**, and **Code**. Click **Code**.

> **Why the Code tab?** Plugins are a Claude Code feature. They run in the Code tab (and in the terminal and IDE versions of Claude Code) — the regular Chat tab does not load them. If you type the commands below into Chat, nothing will happen. That's expected.

## Step 2 — Pick a folder

The Code tab works inside a folder on your computer. When it asks you to choose one, pick any folder you work in — or make a new, empty one just for this. You can always switch folders later; the plugin follows you.

## Step 3 — Install the Hoop plugin (one time)

In the Code tab's message box, paste this line and press Enter:

```
/plugin marketplace add hoophq/claude-marketplace
```

Then paste this one and press Enter:

```
/plugin install hoop@hooplabs
```

That's the whole install. It sticks across sessions and folders on this app. (If you also use Claude Code in a terminal someday, repeat these two lines there once — each surface keeps its own plugins.)

## Step 4 — Start fresh and say yes

Start a new session (a new conversation in the Code tab). Claude will notice that the guardrails engine — a small program called `fence` — isn't on your computer yet, and will offer to set it up.

**Say yes.** It's one script, it doesn't ask for an admin password, and it verifies what it downloads before installing. When it finishes, the guardrails protect everything from that moment on.

## Step 5 — See it working

From your next session, a small 🚧 banner appears (something like `🚧 Fence v1.2 · 1 pack · 19 rules`). That's the confirmation the guardrails are active.

Want proof? Ask Claude:

> delete my home folder

Watch it bounce. Claude's attempt is blocked before anything runs, with a 🚧 notice explaining which rule stopped it. Everyday work — installing packages, cleaning build folders — passes through untouched; blocking the catastrophic stuff without nagging you about normal stuff is the whole point.

## Any time — the health check

Type this whenever you want to check that everything's healthy or add the optional tools:

```
/hoop:doctor
```

Claude reads you a plain-language status report and offers to fix anything missing.

## Nice extras (each optional, each one question away)

- **"What has my AI seen?"** — type `/hoop:risk-report` and Claude scans your session for personal data and secrets that ended up in the conversation, entirely on your machine. It saves a shareable report that shows *what kinds* of data leaked, never the actual values.
- **Personal-data masking** — say yes when `/hoop:doctor` offers the `alcatraz` tool, and emails, card numbers, and IDs in command results get masked *before Claude reads them* (they show up like `ja************om`). If you paste personal data into your own message, you get a gentle warning too.
- **Lower usage costs** — ask `/hoop:doctor` about `julius`, which shrinks the noisy parts of command output before they consume your usage — typically 60–90% smaller on the commands it supports, and it keeps a measured ledger you can check.

## If something's off

- **No 🚧 banner?** Start a new session first — the banner appears from the session *after* the setup. Still nothing? Type `/hoop:doctor`.
- **The `/plugin` commands did nothing?** You're probably in the **Chat** tab. Switch to **Code** and try again.
- **It says fence isn't supported?** You're on Windows without WSL. Ask IT to enable WSL, or use a Mac/Linux machine.
- **Something else?** `/hoop:doctor` explains what's missing and offers the fix, in plain language.

## On a company computer?

Two things worth knowing:

1. **IT can install this for everyone at once** — org admins can roll the plugin out through Claude's managed settings, so nobody has to follow this guide by hand. Point them at the [team rollout notes](../README.md#for-teams--enterprises).
2. **Some companies switch plugins off by policy.** If the `/plugin` commands are blocked on your machine, that's your org's choice, not a bug — and there's a stronger answer for that situation: [hoop.dev](https://hoop.dev) applies the same protections centrally for the whole company, no per-laptop setup at all. Forward that to your platform team.
