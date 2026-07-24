# MEMORY - Hermes Nebius Token Factory

- 2026-07-24: Mel parked the Pi Coding Agent setup and started a Hermes
  configuration lane to avoid spending Pi/Nebius tokens asking Pi to configure
  Hermes.
- 2026-07-24: Prior source material is the Nebius webinar series. The validated
  VPS path installed Hermes through NemoClaw using
  `NEMOCLAW_PROVIDER=custom`,
  `NEMOCLAW_ENDPOINT_URL=https://api.tokenfactory.nebius.com/v1/`,
  `NEMOCLAW_MODEL=nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B`, and
  `COMPATIBLE_API_KEY` mapped from the Nebius Token Factory key.
- 2026-07-24: Current public NemoClaw docs still describe Hermes through
  `nemohermes`, require Node.js `22.19` or newer, Docker, and map
  OpenAI-compatible providers to `NEMOCLAW_PROVIDER=custom` plus
  `COMPATIBLE_API_KEY`.
- 2026-07-24: Live Token Factory catalog still includes
  `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B`, `Qwen/Qwen3-235B-A22B-Instruct-2507`,
  `NousResearch/Hermes-4-70B`, and `deepseek-ai/DeepSeek-V4-Pro`.
- 2026-07-24: Prior local validation found a critical distinction: Token
  Factory and Hermes gateway chat can work while Hermes tool use still fails
  with `tool_turns=0`. Keep the tool-calling gate explicit.
