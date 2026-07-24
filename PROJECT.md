# Project: tooling-and-research

## Identity

name: tooling-and-research
owner: Mel
created: 2026-07-24
workspace: frutero
parent: devrel

## Purpose

objective: Coordinate reusable AI tooling, agent runtime experiments, VPS
setups, provider/model research, and builder-environment patterns for Frutero
DevRel.

This child project owns technical enablement that can support more than one
program: Pi Coding Agent, Claude Code workflows, Hermes runtimes, Nebius Token
Factory setup, model/provider evaluation, and agent-human conversation
experiments.

## Scope

includes:
- Reusable coding-agent and AI-tooling setup for local machines, VPSs, and
  disposable workshop environments.
- Provider/model research and configuration notes for Nebius Token Factory and
  related inference surfaces.
- Agent runtime experiments that are not yet tied to a single public program.
- Scripts, docs, and runbooks that help DevRel builders reproduce the tooling.

excludes:
- Sponsor-specific public content, which belongs in the matching child project
  such as `../nebius/`.
- Event/workshop-specific artifacts, which belong in the matching program child
  such as `../ai-x-blockchain-day/`.
- Production product code unless it is explicitly part of a reusable tooling
  artifact.

## Current state

status: active - Pi setup validated; Hermes provider-config runbook corrected.
current_phase: reusable Nebius Token Factory agent setup for Pi and Hermes.
next_milestone: apply the Hermes provider-config runbook on the target VPS and
record whether Hermes works with the Nebius Token Factory provider.
blockers: Hermes VPS-side validation is still pending.

## Operational links

code_dir: code/
docs_dir: docs/
workstreams_dir: workstreams/
parent_project: ../PROJECT.md
first_workstream: workstreams/pi-coding-agent-daily-driver

## Notes

Keep reusable tooling and research here. When an experiment turns into a
sponsor-specific deliverable, summarize the reusable decision here and move the
program artifact into the relevant child project.
