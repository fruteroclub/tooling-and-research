# DECISIONS - Hermes Nebius Token Factory

- 2026-07-24 - Keep this runbook scoped to direct Hermes configuration:
  `~/.hermes/.env` for `NEBIUS_API_KEY` and `~/.hermes/config.yaml` for a named
  `custom:nebius-token-factory` provider.
- 2026-07-24 - Use `Qwen/Qwen3-235B-A22B-Instruct-2507` as the recommended
  default for Hermes because it matches the validated Pi daily-driver model
  choice.
- 2026-07-24 - Preserve existing Hermes config by backing up first and merging
  provider entries instead of overwriting unrelated settings.
