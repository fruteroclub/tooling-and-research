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

Define and maintain the reusable VPS setup path for Hermes/NemoClaw with Nebius
Token Factory as the inference provider.

The setup should let Mel run Hermes experiments without spending Pi Coding
Agent tokens, while preserving the existing Pi daily-driver setup and any
existing Hermes process on the VPS.

## Trigger

Mel finished the Pi Coding Agent Nebius setup and wants to move to Hermes
configuration. The VPS already appears to have a Hermes process, so the work
must inspect and back up before changing anything.

## Who Needs It

Mel, Frutero DevRel, and future tooling experiments that need Hermes,
NemoClaw/OpenShell, or agent-human conversation infrastructure backed by Nebius
Token Factory credits.

## Done Means

- A public-safe runbook exists for configuring NemoClaw-managed Hermes with
  Nebius Token Factory.
- The runbook covers existing-install inspection, secret handling, install or
  re-onboarding, gateway validation, and the tool-calling gate.
- The guide makes clear that Hermes should not edit files until tool use is
  proven by logs.
- The runbook is linked from the docs index.

## Scope

In scope: Hermes/NemoClaw setup, Token Factory custom provider mapping,
validated model defaults, VPS checks, dashboard/API access, and operational
troubleshooting.

Out of scope: Pi Coding Agent config changes, public webinar curriculum,
messaging channel setup, and direct unsupported edits to unknown Hermes config
files.
