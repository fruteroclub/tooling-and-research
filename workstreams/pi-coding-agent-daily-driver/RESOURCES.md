# RESOURCES - Pi Coding Agent daily driver

- Task: `TASK-001` in `../../TICK.md`.
- Directory:
  `devrel/tooling-and-research/workstreams/pi-coding-agent-daily-driver/`.
- Thread binding:
  `claude-code:projects/devrel/tooling-and-research/workstreams/pi-coding-agent-daily-driver`.
- Child project: `../../PROJECT.md`.
- Container project: `../../../PROJECT.md`.
- Related Nebius webinar guide:
  `../../../nebius/code/nebius-fde-trainer-webinar-series/01-nebius-cloud-builder-environment/written-guide.md`.
- Public-safe setup runbook:
  `../../docs/runbooks/pi-coding-agent-nebius-vps.md`.
- Pi docs: https://pi.dev/docs/latest
- Pi custom models docs: https://pi.dev/docs/latest/models
- Nebius Token Factory docs: https://docs.tokenfactory.nebius.com/quickstart
- Nebius Token Factory model list docs:
  https://docs.tokenfactory.nebius.com/api-reference/models/list-models.md
- Live model catalog endpoint:
  `GET https://api.tokenfactory.nebius.com/v1/models?verbose=true`

## Model Shortlist

| Role | Model | Notes |
| --- | --- | --- |
| Default | `Qwen/Qwen3-235B-A22B-Instruct-2507` | Best balance for daily Pi use: strong tools/general reasoning, `262144` context, low cost. |
| Escalation | `deepseek-ai/DeepSeek-V4-Pro` | Huge `1048576` context and strong smoke-test behavior; higher cost. |
| Cheap fallback | `Qwen/Qwen3-30B-A3B-Instruct-2507` | Fast, inexpensive, long context; weaker than the flagship for judgment-heavy work. |
| Experiment | `moonshotai/Kimi-K2.7-Code` | Code-focused, but only `8000` context and expensive output. |
