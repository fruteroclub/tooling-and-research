# BRIEF - Pi Coding Agent daily driver

thread_id: claude-code:projects/devrel/tooling-and-research/workstreams/pi-coding-agent-daily-driver
owner: Mel
created: 2026-07-24
project: tooling-and-research (devrel / frutero)
workstream: pi-coding-agent-daily-driver
status: active
task: TASK-001
last_updated: 2026-07-24

## Identity

Define and maintain Mel's daily-driver Pi Coding Agent setup for a VPS backed by
Nebius Token Factory.

The setup should make Pi usable as the main coding agent inside a server
environment, with model defaults, fallback models, secret handling, validation
commands, and handoff docs that can be reused across DevRel programs.

## Trigger

Mel wants to use Nebius Fellow credits for a capable coding-agent workflow
instead of relying on Claude or OpenAI subscriptions/API spend.

Prior Nebius webinar work proved Pi can be configured through
`~/.pi/agent/models.json` and `~/.pi/agent/settings.json`, but the default model
choice and VPS daily-driver shape need their own durable workstream.

## Who Needs It

Mel, Frutero DevRel, and future workshop or webinar environments that need a
repeatable Pi Coding Agent configuration on a disposable or long-lived VPS.

## Done Means

- A recommended Nebius Token Factory model stack is selected for Pi daily use.
- Pi install and configuration commands work on a clean VPS.
- Secret handling avoids exposing API keys in shell history, repos, or logs.
- Validation commands prove Pi sees the configured provider and can complete a
  minimal coding-agent smoke test.
- The setup is documented enough to reuse in Nebius, AI x Blockchain, and future
  DevRel builder environments.

## Scope

In scope: Nebius Token Factory model selection, Pi custom provider JSON, VPS
install commands, smoke tests, fallback/escalation model strategy, and reusable
operator notes.

Out of scope: unrelated local laptop Pi preferences, non-Nebius providers,
Hermes/NemoClaw runtime work, and public workshop curriculum unless explicitly
requested.

## Current Direction

Use `Qwen/Qwen3-235B-A22B-Instruct-2507` as the default daily-driver model for
Pi on the VPS. Keep `deepseek-ai/DeepSeek-V4-Pro` as the expensive escalation
model for hard or very large-context work, and `Qwen/Qwen3-30B-A3B-Instruct-2507`
as a cheaper fallback.
