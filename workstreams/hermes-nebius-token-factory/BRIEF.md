# BRIEF - Hermes Nebius Token Factory

thread_id: claude-code:projects/devrel/tooling-and-research/workstreams/hermes-nebius-token-factory
owner: Mel
created: 2026-07-24
project: tooling-and-research (devrel / frutero)
workstream: hermes-nebius-token-factory
status: active
task: TASK-004
last_updated: 2026-07-24

## Identity

Define and maintain the reusable VPS setup path for adding Nebius Token Factory
as an OpenAI-compatible provider in an existing Hermes install.

The setup should let Mel run Hermes experiments without spending Pi Coding
Agent tokens, while preserving the existing Pi daily-driver setup and any
existing Hermes process on the VPS.

## Trigger

Mel finished the Pi Coding Agent Nebius setup and wants to move to Hermes
configuration. The VPS already appears to have a Hermes process, so the work
must inspect and back up before changing anything.

## Who Needs It

Mel, Frutero DevRel, and future tooling experiments that need Hermes or
agent-human conversation infrastructure backed by Nebius Token Factory credits.

## Done Means

- A public-safe runbook exists for extending Hermes config with a named Nebius
  Token Factory provider.
- The runbook covers existing-install inspection, secret handling, config
  backups, YAML merge guidance, direct provider validation, and Hermes chat
  validation.
- The guide avoids unrelated runtime installation paths and keeps the change
  scoped to Hermes config.
- The runbook is linked from the docs index.

## Scope

In scope: Hermes config extension, Token Factory custom provider mapping,
validated model defaults, VPS checks, and operational troubleshooting.

Out of scope: Pi Coding Agent config changes, public webinar curriculum,
messaging channel setup, and runtime installation or replacement work.
