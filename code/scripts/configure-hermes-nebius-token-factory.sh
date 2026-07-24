#!/usr/bin/env bash
set -euo pipefail
set +x

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
HERMES_CONFIG="$HERMES_HOME/config.yaml"
HERMES_ENV="$HERMES_HOME/.env"
PI_ENV="$HOME/.config/pi-nebius/env"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config/hermes-nebius/backups/$TS"

install -d -m 700 "$HERMES_HOME" "$BACKUP_DIR"

if [ -f "$HERMES_CONFIG" ]; then
  cp "$HERMES_CONFIG" "$BACKUP_DIR/config.yaml"
else
  : > "$BACKUP_DIR/config.yaml.absent"
fi

if [ -f "$HERMES_ENV" ]; then
  cp "$HERMES_ENV" "$BACKUP_DIR/env"
else
  : > "$BACKUP_DIR/env.absent"
fi

if [ -f "$PI_ENV" ]; then
  # shellcheck disable=SC1090
  source "$PI_ENV"
fi

if [ -f "$HERMES_ENV" ] && grep -q '^NEBIUS_API_KEY=' "$HERMES_ENV"; then
  :
else
  if [ -z "${NEBIUS_API_KEY:-}" ]; then
    printf '%s\n' "FAIL: NEBIUS_API_KEY is not loaded."
    printf '%s\n' "Set it in your shell or create $PI_ENV with: export NEBIUS_API_KEY=<your-token-factory-key>"
    printf 'backup_dir=%s\n' "$BACKUP_DIR"
    exit 1
  fi

  touch "$HERMES_ENV"
  chmod 600 "$HERMES_ENV"
  printf '\nNEBIUS_API_KEY=%s\n' "$NEBIUS_API_KEY" >> "$HERMES_ENV"
fi

chmod 600 "$HERMES_ENV"

PYTHON_BIN=""
for candidate in \
  "${HERMES_PYTHON:-}" \
  "$HERMES_HOME/hermes-agent/venv/bin/python" \
  "$HERMES_HOME/venv/bin/python" \
  "$(command -v python3 2>/dev/null || true)" \
  "$(command -v python 2>/dev/null || true)"
do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    if "$candidate" - <<'PY' >/dev/null 2>&1
import yaml
PY
    then
      PYTHON_BIN="$candidate"
      break
    fi
  fi
done

if [ -z "$PYTHON_BIN" ]; then
  printf '%s\n' "FAIL: no Python with PyYAML is available."
  printf '%s\n' "Hermes usually has one at $HERMES_HOME/hermes-agent/venv/bin/python."
  printf '%s\n' "Config backup was created; no config changes were written."
  printf 'backup_dir=%s\n' "$BACKUP_DIR"
  exit 1
fi

"$PYTHON_BIN" - "$HERMES_CONFIG" <<'PY'
import sys
from pathlib import Path

import yaml

config_path = Path(sys.argv[1])

provider_name = "nebius-token-factory"
default_model = "Qwen/Qwen3-235B-A22B-Instruct-2507"

provider = {
    "name": provider_name,
    "base_url": "https://api.tokenfactory.nebius.com/v1/",
    "key_env": "NEBIUS_API_KEY",
    "api_mode": "chat_completions",
    "models": {
        "Qwen/Qwen3-235B-A22B-Instruct-2507": {"context_length": 262144},
        "nvidia/Nemotron-3-Nano-Omni": {"context_length": 262144},
        "deepseek-ai/DeepSeek-V4-Pro": {"context_length": 1048576},
    },
}

aliases = {
    "nebius-qwen": {
        "provider": f"custom:{provider_name}",
        "model": "Qwen/Qwen3-235B-A22B-Instruct-2507",
    },
    "nebius-cheap": {
        "provider": f"custom:{provider_name}",
        "model": "nvidia/Nemotron-3-Nano-Omni",
    },
    "nebius-big": {
        "provider": f"custom:{provider_name}",
        "model": "deepseek-ai/DeepSeek-V4-Pro",
    },
}

if config_path.exists() and config_path.read_text(encoding="utf-8").strip():
    data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
else:
    data = {}

if data is None:
    data = {}

if not isinstance(data, dict):
    raise SystemExit("config.yaml must be a YAML mapping at the top level")

custom_providers = data.get("custom_providers")
if custom_providers is None:
    custom_providers = []
elif not isinstance(custom_providers, list):
    raise SystemExit("config.yaml custom_providers must be a list")

custom_providers = [
    item
    for item in custom_providers
    if not (isinstance(item, dict) and item.get("name") == provider_name)
]
custom_providers.append(provider)
data["custom_providers"] = custom_providers

model = data.get("model")
if model is None:
    model = {}
elif not isinstance(model, dict):
    raise SystemExit("config.yaml model must be a mapping")

model["provider"] = f"custom:{provider_name}"
model["default"] = default_model
data["model"] = model

model_aliases = data.get("model_aliases")
if model_aliases is None:
    model_aliases = {}
elif not isinstance(model_aliases, dict):
    raise SystemExit("config.yaml model_aliases must be a mapping")

model_aliases.update(aliases)
data["model_aliases"] = model_aliases

config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(
    yaml.safe_dump(data, sort_keys=False, allow_unicode=True),
    encoding="utf-8",
)
PY

chmod 600 "$HERMES_CONFIG"

printf '%s\n' "OK: configured Hermes Nebius Token Factory provider"
printf 'config=%s\n' "$HERMES_CONFIG"
printf 'env=%s\n' "$HERMES_ENV"
printf 'backup_dir=%s\n' "$BACKUP_DIR"

if command -v hermes >/dev/null 2>&1; then
  hermes config check || true
  hermes config get model || true
else
  printf '%s\n' "WARN: hermes command is not on PATH; config was written but not checked with Hermes CLI."
fi

printf '%s\n' "Next smoke test:"
printf '%s\n' "  hermes chat -Q -q 'Reply exactly: hermes-nebius-ok'"
