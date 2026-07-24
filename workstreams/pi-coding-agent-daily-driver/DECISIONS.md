# DECISIONS - Pi Coding Agent daily driver

- 2026-07-24 - Superseded: this briefly started as a `devrel` container-level
  workstream. Mel chose to create `tooling-and-research` as a more flexible
  nested child project, so the workstream was migrated there.
- 2026-07-24 - Use `tooling-and-research` for reusable AI tooling, agent runtime
  experiments, VPS setup, model/provider research, and builder-environment
  patterns that can support multiple DevRel programs.
- 2026-07-24 - Recommend `Qwen/Qwen3-235B-A22B-Instruct-2507` as the default Pi
  model from Nebius Token Factory. Rationale: strong general/tool-use profile,
  `262144` context, clean smoke-test behavior, and much lower cost than Kimi
  K2.7 Code or DeepSeek V4 Pro.
- 2026-07-24 - Keep `deepseek-ai/DeepSeek-V4-Pro` as the high-end escalation
  model for difficult long-horizon or huge-context coding work, not the daily
  default, because it is materially more expensive.
- 2026-07-24 - Do not default to Kimi for Pi: `moonshotai/Kimi-K2.7-Code` is
  code-focused but only has `8000` context and high output cost; Kimi K2.6 is
  multimodal and less appropriate for a terminal coding-agent default.
- 2026-07-24 - Keep Pi-side `reasoning: false` and
  `compat.supportsReasoningEffort: false` for Nebius Token Factory entries
  unless later Pi/Token Factory validation proves reasoning parameters are safe.
