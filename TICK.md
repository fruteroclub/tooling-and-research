---
project: tooling-and-research
schema_version: "1.0"
created: Fri Jul 24 2026 02:23:40 GMT-0600 (Central Standard Time)
updated: 2026-07-24T09:54:23.417Z
default_workflow: [backlog, todo, in_progress, review, done]
id_prefix: TASK
next_id: 4
---

## Agents

| Agent | Type | Role | Status | Working On | Last Active | Trust Level |
|-------|------|------|--------|------------|-------------|-------------|
| @codex | bot | engineer | working | TASK-003 | 2026-07-24T09:54:23.417Z | trusted |

---

## Tasks

### TASK-001 · Define Pi Coding Agent daily-driver VPS setup

```yaml
id: TASK-001
status: done
priority: high
assigned_to: null
claimed_by: null
created_by: "@troopdegen"
created_at: 2026-07-24T08:24:25.455Z
updated_at: 2026-07-24T09:35:57.815Z
tags:
  - pi-coding-agent-daily-driver
  - pi
  - nebius-token-factory
  - vps
history:
  - ts: 2026-07-24T08:24:25.455Z
    who: "@troopdegen"
    action: created
  - ts: 2026-07-24T08:28:51.681Z
    who: "@codex"
    action: claimed
    from: backlog
    to: in_progress
  - ts: 2026-07-24T08:31:42.217Z
    who: "@codex"
    action: commented
    note: "Drafted and published the public-safe Pi Coding Agent on Nebius Token
      Factory VPS guide at
      https://github.com/fruteroclub/tooling-and-research/blob/main/docs/runboo\
      ks/pi-coding-agent-nebius-vps.md. Remaining work: run the guide on the
      target VPS and adjust any drift."
  - ts: 2026-07-24T08:31:42.396Z
    who: "@codex"
    action: released
    from: in_progress
    to: todo
  - ts: 2026-07-24T09:35:57.815Z
    who: "@codex"
    action: completed
    from: todo
    to: done
```

> Create and maintain the daily-driver Pi Coding Agent setup for a Nebius-backed VPS, including Token Factory model selection, config files, validation commands, and handoff docs.

### TASK-002 · Add multi-model expansion prompt to Pi VPS runbook

```yaml
id: TASK-002
status: done
priority: medium
assigned_to: null
claimed_by: null
created_by: "@troopdegen"
created_at: 2026-07-24T09:41:18.816Z
updated_at: 2026-07-24T09:42:06.218Z
tags:
  - pi-coding-agent-daily-driver
  - docs
  - models
history:
  - ts: 2026-07-24T09:41:18.816Z
    who: "@troopdegen"
    action: created
  - ts: 2026-07-24T09:41:18.967Z
    who: "@codex"
    action: claimed
    from: backlog
    to: in_progress
  - ts: 2026-07-24T09:42:06.060Z
    who: "@codex"
    action: commented
    note: Added the optional 'Add More Models Safely' section to the Pi Nebius VPS
      runbook with a Pi-ready prompt, model candidates, backup rules,
      validation, and rollback guidance.
  - ts: 2026-07-24T09:42:06.218Z
    who: "@codex"
    action: completed
    from: in_progress
    to: done
```

> Document a safe prompt for asking Pi Coding Agent to expand the Nebius Token Factory model list without breaking the live default config.

### TASK-003 · Correct Pi model menu and add comparison table

```yaml
id: TASK-003
status: in_progress
priority: medium
assigned_to: null
claimed_by: "@codex"
created_by: "@troopdegen"
created_at: 2026-07-24T09:53:32.381Z
updated_at: 2026-07-24T09:54:23.417Z
tags:
  - pi-coding-agent-daily-driver
  - docs
  - models
history:
  - ts: 2026-07-24T09:53:32.381Z
    who: "@troopdegen"
    action: created
  - ts: 2026-07-24T09:53:32.531Z
    who: "@codex"
    action: claimed
    from: backlog
    to: in_progress
  - ts: 2026-07-24T09:54:23.417Z
    who: "@codex"
    action: commented
    note: Corrected the baseline model stack to Qwen default, Nemotron cheap
      fallback, and DeepSeek escalation; added an 8-column model comparison
      table and updated the expansion prompt to avoid re-adding the installed
      fallback.
```

> Remove the duplicate Qwen baseline model from the Pi VPS runbook and add a compact model comparison table for default and suggested Token Factory models.
