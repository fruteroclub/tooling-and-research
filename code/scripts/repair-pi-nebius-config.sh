#!/usr/bin/env bash
set -euo pipefail
set +x

PI_AGENT_DIR="$HOME/.pi/agent"
PI_ENV_DIR="$HOME/.config/pi-nebius"
PI_ENV="$PI_ENV_DIR/env"
HERMES_ENV="$HOME/.hermes/.env"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$PI_AGENT_DIR/backups"

install -d -m 700 "$PI_AGENT_DIR" "$BACKUP_DIR" "$PI_ENV_DIR"

if ! command -v node >/dev/null 2>&1; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    nvm use --silent default >/dev/null 2>&1 || nvm use --silent node >/dev/null 2>&1 || true
  fi
fi

if ! command -v node >/dev/null 2>&1; then
  printf '%s\n' "FAIL: node is not available on PATH."
  printf '%s\n' "Open a fresh shell or run: source \"\$HOME/.nvm/nvm.sh\" && nvm use default"
  exit 1
fi

if [ -f "$PI_AGENT_DIR/models.json" ]; then
  cp "$PI_AGENT_DIR/models.json" "$BACKUP_DIR/models.before-repair-$TS.json"
fi

if [ -f "$PI_AGENT_DIR/settings.json" ]; then
  cp "$PI_AGENT_DIR/settings.json" "$BACKUP_DIR/settings.before-repair-$TS.json"
fi

if [ ! -f "$PI_ENV" ] && [ -f "$HERMES_ENV" ] && grep -q '^NEBIUS_API_KEY=' "$HERMES_ENV"; then
  {
    printf 'export '
    grep -m 1 '^NEBIUS_API_KEY=' "$HERMES_ENV"
  } > "$PI_ENV"
  chmod 600 "$PI_ENV"
fi

if [ -f "$PI_ENV" ]; then
  # shellcheck disable=SC1090
  source "$PI_ENV"
fi

if [ -z "${NEBIUS_API_KEY:-}" ]; then
  printf '%s\n' "FAIL: NEBIUS_API_KEY is not loaded."
  printf '%s\n' "Create $PI_ENV with: export NEBIUS_API_KEY=<your-token-factory-key>"
  exit 1
fi

BASHRC_LINE='[ -f "$HOME/.config/pi-nebius/env" ] && source "$HOME/.config/pi-nebius/env"'
if [ -f "$HOME/.bashrc" ]; then
  grep -qxF "$BASHRC_LINE" "$HOME/.bashrc" || printf '\n%s\n' "$BASHRC_LINE" >> "$HOME/.bashrc"
else
  printf '%s\n' "$BASHRC_LINE" > "$HOME/.bashrc"
fi

node <<'NODE'
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const dir = path.join(os.homedir(), ".pi", "agent");

const common = {
  input: ["text"],
  reasoning: false,
  maxTokens: 8192,
  compat: {
    supportsReasoningEffort: false
  }
};

const models = {
  providers: {
    "nebius-token-factory": {
      baseUrl: "https://api.tokenfactory.nebius.com/v1/",
      api: "openai-completions",
      apiKey: "$NEBIUS_API_KEY",
      models: [
        {
          ...common,
          id: "Qwen/Qwen3-235B-A22B-Instruct-2507",
          name: "Qwen3 235B A22B Instruct via Nebius Token Factory",
          contextWindow: 262144
        },
        {
          ...common,
          id: "nvidia/Nemotron-3-Nano-Omni",
          name: "Nemotron 3 Nano Omni via Nebius Token Factory",
          contextWindow: 262144
        },
        {
          ...common,
          id: "deepseek-ai/DeepSeek-V4-Pro",
          name: "DeepSeek V4 Pro via Nebius Token Factory",
          contextWindow: 1048576
        }
      ]
    }
  }
};

const settings = {
  defaultProvider: "nebius-token-factory",
  defaultModel: "Qwen/Qwen3-235B-A22B-Instruct-2507",
  defaultThinkingLevel: "off",
  enabledModels: [
    "nebius-token-factory/Qwen/Qwen3-235B-A22B-Instruct-2507",
    "nebius-token-factory/nvidia/Nemotron-3-Nano-Omni",
    "nebius-token-factory/deepseek-ai/DeepSeek-V4-Pro"
  ]
};

fs.writeFileSync(path.join(dir, "models.json"), `${JSON.stringify(models, null, 2)}\n`, { mode: 0o600 });
fs.writeFileSync(path.join(dir, "settings.json"), `${JSON.stringify(settings, null, 2)}\n`, { mode: 0o600 });
NODE

chmod 600 "$PI_AGENT_DIR/models.json" "$PI_AGENT_DIR/settings.json"

node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$PI_AGENT_DIR/models.json"
node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$PI_AGENT_DIR/settings.json"

printf '%s\n' "OK: repaired Pi Nebius config"
printf 'models=%s\n' "$PI_AGENT_DIR/models.json"
printf 'settings=%s\n' "$PI_AGENT_DIR/settings.json"
printf 'backups=%s\n' "$BACKUP_DIR"

if command -v pi >/dev/null 2>&1; then
  pi --list-models nebius-token-factory | sed -n '1,80p'
fi
