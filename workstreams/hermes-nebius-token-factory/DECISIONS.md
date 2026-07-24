# DECISIONS - Hermes Nebius Token Factory

- 2026-07-24 - Use NemoClaw-managed Hermes as the reproducible setup path for
  Token Factory. Direct `~/.hermes` processes should be inspected and preserved
  unless a port conflict or explicit migration requires intervention.
- 2026-07-24 - Keep `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B` as the first
  installer model because the prior NemoClaw/Hermes Nebius validation used it
  successfully and it remains available in the live Token Factory catalog.
- 2026-07-24 - Treat Hermes dashboard and gateway chat success as insufficient
  for coding-agent trust. Hermes must pass a tool-calling gate with
  `tool_turns=1` before it is allowed to inspect or edit files.
