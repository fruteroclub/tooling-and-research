# MEMORY - Pi Coding Agent daily driver

- 2026-07-24: Workstream started after Mel decided Pi Coding Agent should be
  the main driver inside a VPS using Nebius Token Factory credits.
- 2026-07-24: Mel chose a flexible nested child project named
  `tooling-and-research` for reusable tooling and research. Migrated this
  workstream from the devrel container root into
  `devrel/tooling-and-research/workstreams/pi-coding-agent-daily-driver`.
- 2026-07-24: Prior source repo is
  `devrel/nebius/code/nebius-fde-trainer-webinar-series`; its canonical VPS Pi
  setup lives in `01-nebius-cloud-builder-environment/written-guide.md`, Steps
  12-13, with Pi installed via
  `sudo npm install -g --ignore-scripts @earendil-works/pi-coding-agent`.
- 2026-07-24: Live Token Factory catalog was checked with the existing local
  Nebius credential, without printing the key. Relevant current models included
  Qwen3 235B, Qwen3 30B, DeepSeek V4 Pro, Kimi K2.7 Code, Kimi K2.6, MiniMax
  M2.5, and several Nemotron variants.
- 2026-07-24: Recommendation for the VPS Pi default is
  `Qwen/Qwen3-235B-A22B-Instruct-2507`; escalation model is
  `deepseek-ai/DeepSeek-V4-Pro`; cheap fallback is
  `Qwen/Qwen3-30B-A3B-Instruct-2507`.
- 2026-07-24: Kimi K2.7 Code was not chosen as the default because Token Factory
  reports only `8000` context and high output cost, despite its code-focused
  description. Kimi K2.6 is multimodal (`text+image->text`) and better suited to
  image-aware workflows than normal Pi terminal coding.
- 2026-07-24: Prior Pi/Nebius validation found Pi can throw provider errors when
  Nebius models are marked reasoning-capable. Use `reasoning: false` and
  `compat.supportsReasoningEffort: false` in Pi model entries until revalidated.
- 2026-07-24: Drafted public-safe VPS setup guide at
  `tooling-and-research/docs/runbooks/pi-coding-agent-nebius-vps.md`. The guide
  uses Qwen3 235B as the default, Qwen3 30B as fallback, DeepSeek V4 Pro as
  escalation, and stores the Token Factory key in a private env file on the VPS.
- 2026-07-24: Published the child project as
  `https://github.com/fruteroclub/tooling-and-research`; removed
  `.tick/session.json` from tracking and ignored it as local tick runtime state.
- 2026-07-24: Mel completed the published VPS guide end-to-end. Pi launches on
  the VPS with the configured Nebius Token Factory models.
- 2026-07-24: Added a public runbook section, "Add More Models Safely", with a
  prompt for Pi to back up configs, fetch the live Token Factory catalog, add a
  diverse model menu, validate JSON, preserve defaults, and smoke test changes.
- 2026-07-24: Corrected the runbook baseline model stack so it no longer uses
  Qwen twice. Baseline is Qwen3 235B default, Nemotron 3 Nano Omni cheap
  fallback, and DeepSeek V4 Pro escalation. Added an 8-column model comparison
  table grounded in live Token Factory catalog metadata.
