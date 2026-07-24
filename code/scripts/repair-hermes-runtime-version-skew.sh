#!/usr/bin/env bash
set -euo pipefail
set +x

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
HERMES_AGENT_DIR="${HERMES_AGENT_DIR:-$HERMES_HOME/hermes-agent}"
PYTHON_BIN="${HERMES_PYTHON:-$HERMES_AGENT_DIR/venv/bin/python}"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config/hermes-nebius/backups/$TS"

install -d -m 700 "$BACKUP_DIR"

if [ ! -d "$HERMES_AGENT_DIR" ]; then
  printf 'FAIL: Hermes agent directory not found: %s\n' "$HERMES_AGENT_DIR"
  exit 1
fi

if [ ! -x "$PYTHON_BIN" ]; then
  printf 'FAIL: Hermes Python not found or not executable: %s\n' "$PYTHON_BIN"
  exit 1
fi

cd "$HERMES_AGENT_DIR"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git rev-parse HEAD > "$BACKUP_DIR/hermes-agent-before.txt"
  git status --short --branch > "$BACKUP_DIR/hermes-agent-status-before.txt"
else
  printf 'FAIL: %s is not a git checkout; refusing to modify it automatically.\n' "$HERMES_AGENT_DIR"
  printf 'backup_dir=%s\n' "$BACKUP_DIR"
  exit 1
fi

if PYTHONPATH="$HERMES_AGENT_DIR" "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
from tools.environments.local import _is_hermes_internal_secret
assert _is_hermes_internal_secret("GATEWAY_RELAY_SECRET")
PY
then
  printf '%s\n' "OK: Hermes runtime already has _is_hermes_internal_secret"
  printf 'hermes_agent_dir=%s\n' "$HERMES_AGENT_DIR"
  printf 'backup_dir=%s\n' "$BACKUP_DIR"
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  printf '%s\n' "FAIL: Hermes agent checkout has local changes; not pulling automatically."
  printf '%s\n' "Inspect with:"
  printf '  cd %q && git status --short\n' "$HERMES_AGENT_DIR"
  printf 'backup_dir=%s\n' "$BACKUP_DIR"
  exit 1
fi

git fetch origin
git pull --ff-only
git rev-parse HEAD > "$BACKUP_DIR/hermes-agent-after.txt"

if ! PYTHONPATH="$HERMES_AGENT_DIR" "$PYTHON_BIN" - <<'PY'
from tools.environments.local import _is_hermes_internal_secret
assert _is_hermes_internal_secret("GATEWAY_RELAY_SECRET")
print("OK: Hermes import works")
PY
then
  printf '%s\n' "FAIL: Hermes checkout updated, but the import still fails."
  printf 'backup_dir=%s\n' "$BACKUP_DIR"
  exit 1
fi

printf '%s\n' "OK: repaired Hermes runtime version skew"
printf 'hermes_agent_dir=%s\n' "$HERMES_AGENT_DIR"
printf 'backup_dir=%s\n' "$BACKUP_DIR"
printf '%s\n' "Restart the existing Hermes gateway process so Telegram DMs load the updated code."
