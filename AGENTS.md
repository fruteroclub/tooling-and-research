# AGENTS.md - tooling-and-research

Portable context for any coding agent working in this project. Keep this
tool-agnostic.

## What This Is

`tooling-and-research` is a nested internOS child project under the Frutero
`devrel` container. It tracks reusable AI tooling, agent runtime experiments,
provider/model research, and VPS builder-environment setup.

Read [`PROJECT.md`](PROJECT.md) for identity, scope, and current state. For the
container and sibling children, see [`../PROJECT.md`](../PROJECT.md) and
[`../REGISTRY.md`](../REGISTRY.md).

## Layout

```
tooling-and-research/
  PROJECT.md        # identity, scope, current state
  AGENTS.md         # this file
  TICK.md           # this project's tasks
  .tick/
  workstreams/      # tooling/research-specific workstreams
  code/             # scripts, config generators, reusable tooling artifacts
  docs/             # notes, runbooks, model/provider research, setup guides
```

## Hard Rules

- **Reusable tooling work goes in this child project.** Do not bury common setup
  or model/provider decisions inside a sponsor or event child unless the work is
  specific to that program.
- **Tasks go in this project's `TICK.md`.** Cross-child DevRel coordination
  escalates to `../TICK.md`.
- **Use exact `thread_id` values.** Do not infer workstreams from similar names.
- **Keep operational state small.** `STATUS.md` should stay under 10 lines;
  `MEMORY.md` should stay under 80 lines.
- **Store artifacts deliberately.** Reusable scripts/configs belong in `code/`;
  research notes and runbooks belong in `docs/` or the active workstream's
  `docs/`.
- **Do not expose secrets.** API keys, VPS credentials, tokens, and private
  endpoint values must stay out of repos, logs, screenshots, and summaries.

## Current Workstreams

- [`pi-coding-agent-daily-driver`](workstreams/pi-coding-agent-daily-driver/BRIEF.md)
  - Pi Coding Agent setup for a Nebius Token Factory-backed VPS.

## Conventions

Default-load a workstream's `BRIEF.md` + `STATUS.md`, then escalate to
`MEMORY.md`, `DECISIONS.md`, `STAKEHOLDERS.md`, `RESOURCES.md`, or `docs/` only
when the task requires it.
