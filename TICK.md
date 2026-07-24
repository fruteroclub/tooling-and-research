---
project: tooling-and-research
schema_version: "1.0"
created: Fri Jul 24 2026 02:23:40 GMT-0600 (Central Standard Time)
updated: 2026-07-24T08:31:42.396Z
default_workflow: [backlog, todo, in_progress, review, done]
id_prefix: TASK
next_id: 2
---

## Agents

| Agent | Type | Role | Status | Working On | Last Active | Trust Level |
|-------|------|------|--------|------------|-------------|-------------|
| @codex | bot | engineer | idle | - | 2026-07-24T08:31:42.396Z | trusted |

---

## Tasks

### TASK-001 · Define Pi Coding Agent daily-driver VPS setup

```yaml
id: TASK-001
status: todo
priority: high
assigned_to: null
claimed_by: null
created_by: "@troopdegen"
created_at: 2026-07-24T08:24:25.455Z
updated_at: 2026-07-24T08:31:42.396Z
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
```

> Create and maintain the daily-driver Pi Coding Agent setup for a Nebius-backed VPS, including Token Factory model selection, config files, validation commands, and handoff docs.
