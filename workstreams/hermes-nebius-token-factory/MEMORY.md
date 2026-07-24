# MEMORY - Hermes Nebius Token Factory

- 2026-07-24: Mel parked the Pi Coding Agent setup and started a Hermes
  configuration lane to avoid spending Pi/Nebius tokens asking Pi to configure
  Hermes.
- 2026-07-24: Mel rejected the first draft because it overfit to a tutorial
  install path. The correct guide is a clean Hermes config extension: add
  `NEBIUS_API_KEY` to `~/.hermes/.env`, add a named
  `custom:nebius-token-factory` provider to `~/.hermes/config.yaml`, and keep
  existing Hermes state intact.
- 2026-07-24: Live Token Factory catalog still includes
  `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B`, `Qwen/Qwen3-235B-A22B-Instruct-2507`,
  `NousResearch/Hermes-4-70B`, and `deepseek-ai/DeepSeek-V4-Pro`.
- 2026-07-24: The corrected Hermes guide recommends Qwen as default, Nemotron
  Omni as a cheaper test path, and DeepSeek V4 Pro as an expensive escalation.
- 2026-07-24: After Pi config was repaired with a repo-hosted script, Mel asked
  for the same shape for Hermes. Added
  `code/scripts/configure-hermes-nebius-token-factory.sh`: it backs up
  `~/.hermes/config.yaml` and `~/.hermes/.env`, sources the Pi env only as a
  key source, writes only Hermes files, and idempotently merges the named
  Nebius custom provider plus aliases.
