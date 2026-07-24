# Hermes With Nebius Token Factory On A VPS

This guide configures a VPS so Hermes can use Nebius Token Factory through the
NemoClaw-managed Hermes path.

Use this when you want Hermes available on the same VPS as Pi Coding Agent, but
you do not want to spend Pi tokens asking Pi to configure it.

The known-good path is:

```text
nemohermes -> Hermes Agent gateway -> Nebius Token Factory -> model response
```

Do not use Hermes for file edits until it passes the tool-calling gate in
Step 8. A healthy dashboard and a working chat endpoint are not enough.

## Model Stack

| Role | Model | Why |
| --- | --- | --- |
| Validated installer default | `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B` | Prior NemoClaw/Hermes validation used this model successfully through Token Factory. |
| Daily-driver experiment | `Qwen/Qwen3-235B-A22B-Instruct-2507` | Same strong default as the Pi setup; large context and reasonable cost. |
| Hermes ecosystem experiment | `NousResearch/Hermes-4-70B` | Useful for content around Hermes/NemoClaw alignment. |
| Expensive escalation | `deepseek-ai/DeepSeek-V4-Pro` | Large-context fallback for hard agent tasks, if cost is acceptable. |

Current Token Factory catalog prices observed on 2026-07-24:

| Model | Context | Price $/M in/out |
| --- | --- | --- |
| `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B` | 262K | `0.06 / 0.24` |
| `Qwen/Qwen3-235B-A22B-Instruct-2507` | 262K | `0.20 / 0.60` |
| `NousResearch/Hermes-4-70B` | 131K | `0.13 / 0.40` |
| `deepseek-ai/DeepSeek-V4-Pro` | 1M | `1.75 / 3.50` |

Verify live prices before budget planning.

## Prerequisites

- Ubuntu VPS with shell access.
- Docker available to the user that will run Hermes.
- Node.js `22.19` or newer and npm `10` or newer.
- `curl`, `jq`, `git`, `binutils`, and `zstd`.
- Nebius Token Factory API key stored outside the repo.
- The Pi runbook completed, or at least `~/.config/pi-nebius/env` available.

NemoClaw's current docs list `4 vCPU`, `8 GB RAM`, and `20 GB` free disk as the
minimum, with `16 GB RAM` and `40 GB` free disk recommended. On small VPSs, add
swap before building the sandbox.

## 1. Inspect The Existing Hermes State

Run this first. The goal is to learn what is already running before installing
or replacing anything.

```bash
set +x

ps aux | grep -Ei 'hermes|nemo|openshell' | grep -v grep || true

command -v nemohermes || true
command -v nemoclaw || true
command -v openshell || true
command -v hermes || true

ls -la "$HOME/.hermes" "$HOME/.local/bin" 2>/dev/null || true
systemctl --user status hermes 2>/dev/null || true
```

If you see a process like this, Hermes is already running:

```text
~/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace
```

Do not kill it yet. Continue through the read-only checks and create backups
before changing anything.

## 2. Load The Nebius Token Factory Key

If you completed the Pi runbook, reuse the same private env file:

```bash
set +x

source "$HOME/.config/pi-nebius/env"

if [ -z "${NEBIUS_API_KEY:-}" ]; then
  echo "FAIL: NEBIUS_API_KEY is not loaded"
  return 1 2>/dev/null || exit 1
fi

echo "OK: Token Factory key is loaded"
```

Do not print the key. Do not paste it into chat. Do not commit it.

## 3. Check System Readiness

Install the small packages NemoClaw expects:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git jq binutils zstd
```

Check versions and Docker access:

```bash
node -v
npm -v
docker info --format 'Server={{.ServerVersion}} CPUs={{.NCPU}} MemBytes={{.MemTotal}}'
```

If `docker info` fails because of permissions, finish Docker group setup before
continuing:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
docker info --format 'Server={{.ServerVersion}} CPUs={{.NCPU}} MemBytes={{.MemTotal}}'
```

Members of the `docker` group effectively control root-level container access on
the host. Only do this for trusted VPS users.

## 4. Confirm Token Factory Access

Set a model variable for the first Hermes setup. Start with the prior validated
Nemotron model:

```bash
export NEBIUS_TF_MODEL="${NEBIUS_TF_MODEL:-nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B}"
```

Confirm the selected model exists in the live Token Factory catalog:

```bash
curl -fsS "https://api.tokenfactory.nebius.com/v1/models?verbose=true" \
  -H "Authorization: Bearer $NEBIUS_API_KEY" \
  -H "Accept: application/json" \
| jq -r --arg model "$NEBIUS_TF_MODEL" '
    .data[]
    | select(.id == $model)
    | "\(.id) | context=\(.context_length) | prompt=\(.pricing.prompt) | completion=\(.pricing.completion)"
  '
```

Expected: one line for the selected model.

Smoke-test Token Factory directly:

```bash
HTTP_CODE=$(curl -sS -o /tmp/tokenfactory-direct.json -w '%{http_code}' \
  -H "Authorization: Bearer $NEBIUS_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "{
    \"model\": \"$NEBIUS_TF_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Reply exactly: token-factory-ready\"}
    ],
    \"max_tokens\": 512,
    \"temperature\": 0
  }" \
  "https://api.tokenfactory.nebius.com/v1/chat/completions")

printf 'http=%s\n' "$HTTP_CODE"
jq -r '.choices[0].message.content' /tmp/tokenfactory-direct.json
```

Expected:

```text
token-factory-ready
```

If the content is `null`, inspect the saved response before assuming the
provider is broken. Some reasoning models can spend the output budget on hidden
reasoning:

```bash
jq '{finish_reason: .choices[0].finish_reason, content: .choices[0].message.content, reasoning: .choices[0].message.reasoning}' \
  /tmp/tokenfactory-direct.json 2>/dev/null || true
```

## 5. Back Up Existing Hermes State

Create a lightweight backup before installing or re-onboarding:

```bash
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config/hermes-nebius/backups/$TS"
install -d -m 700 "$BACKUP_DIR"

[ -d "$HOME/.hermes" ] && tar -C "$HOME" -czf "$BACKUP_DIR/hermes-home.tgz" .hermes
[ -d "$HOME/.config/nemoclaw" ] && tar -C "$HOME" -czf "$BACKUP_DIR/nemoclaw-config.tgz" .config/nemoclaw
[ -d "$HOME/.openshell" ] && tar -C "$HOME" -czf "$BACKUP_DIR/openshell-home.tgz" .openshell

printf 'backup_dir=%s\n' "$BACKUP_DIR"
```

This backup does not include Docker images or volumes. It is enough to preserve
user-level config before trying the Token Factory path.

## 6. Install Or Re-Onboard NemoClaw Hermes

Use a separate sandbox name so the Token Factory experiment does not overwrite a
different Hermes environment:

```bash
export HERMES_SANDBOX="${HERMES_SANDBOX:-fde-hermes-nebius}"
export NEBIUS_TF_MODEL="${NEBIUS_TF_MODEL:-nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B}"
export PATH="$HOME/.local/bin:$PATH"
```

If `nemohermes` is already installed, check whether this sandbox exists:

```bash
if command -v nemohermes >/dev/null 2>&1; then
  nemohermes "$HERMES_SANDBOX" status || true
fi
```

If the sandbox does not exist, or you intentionally want to recreate this
Token Factory Hermes sandbox, download the installer first, then run it with
the OpenAI-compatible provider settings. This keeps credentials out of the
download step.

```bash
set +x
TOKEN="${NEBIUS_API_KEY:-}"
INSTALLER="$(mktemp)"

if [ -z "$TOKEN" ]; then
  echo "FAIL: NEBIUS_API_KEY is not loaded"
  rm -f "$INSTALLER"
  return 1 2>/dev/null || exit 1
fi

curl -fsSL https://www.nvidia.com/nemoclaw.sh -o "$INSTALLER"
chmod 700 "$INSTALLER"

env \
  NEMOCLAW_AGENT=hermes \
  NEMOCLAW_NON_INTERACTIVE=1 \
  NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
  NEMOCLAW_REASONING=true \
  NEMOCLAW_PROVIDER=custom \
  NEMOCLAW_ENDPOINT_URL=https://api.tokenfactory.nebius.com/v1/ \
  NEMOCLAW_MODEL="$NEBIUS_TF_MODEL" \
  NEMOCLAW_SANDBOX_NAME="$HERMES_SANDBOX" \
  NEMOCLAW_WEB_SEARCH_PROVIDER=none \
  COMPATIBLE_API_KEY="$TOKEN" \
  NEMOCLAW_YES=1 \
  bash "$INSTALLER"

unset TOKEN
rm -f "$INSTALLER"
export PATH="$HOME/.local/bin:$PATH"
```

Why these settings:

- `NEMOCLAW_AGENT=hermes` selects Hermes Agent.
- `NEMOCLAW_PROVIDER=custom` selects the OpenAI-compatible provider path.
- `NEMOCLAW_ENDPOINT_URL` points at the Token Factory API.
- `COMPATIBLE_API_KEY` is the credential variable NemoClaw expects for custom
  OpenAI-compatible providers.
- `NEMOCLAW_WEB_SEARCH_PROVIDER=none` keeps this setup focused on model access.
- `NEMOCLAW_SANDBOX_NAME` isolates this experiment from any existing Hermes
  process.

## 7. Verify Hermes Gateway Health

Check CLI availability:

```bash
export PATH="$HOME/.local/bin:$PATH"

nemohermes --version
nemoclaw --version
```

Check sandbox status:

```bash
nemohermes "$HERMES_SANDBOX" status
```

Expected markers:

```text
Phase: Ready
Harness: Hermes Agent
Hermes Agent: running
```

Check local endpoints:

```bash
curl -sS -o /tmp/nemoclaw-dashboard-check.txt -w '%{http_code}\n' \
  http://127.0.0.1:18789/

curl -sS -o /tmp/nemoclaw-api-health.txt -w '%{http_code}\n' \
  http://127.0.0.1:8642/health
```

Expected:

```text
200
200
```

Check the Hermes OpenAI-compatible gateway:

```bash
HERMES_TOKEN="$(nemohermes "$HERMES_SANDBOX" gateway-token --quiet)"

HTTP_CODE=$(curl -sS -o /tmp/nemoclaw-hermes-chat.json -w '%{http_code}' \
  -H "Authorization: Bearer $HERMES_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "{
    \"model\": \"$NEBIUS_TF_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Reply exactly: hermes-ready\"}
    ],
    \"max_tokens\": 512,
    \"temperature\": 0
  }" \
  http://127.0.0.1:8642/v1/chat/completions)

unset HERMES_TOKEN

printf 'http=%s\n' "$HTTP_CODE"
jq -r '.choices[0].message.content' /tmp/nemoclaw-hermes-chat.json
```

Expected:

```text
http=200
hermes-ready
```

This proves the gateway path works:

```text
Hermes gateway -> Nebius Token Factory -> selected model -> response
```

## 8. Tool-Calling Gate

Run this before letting Hermes inspect files, edit repos, or act as a coding
agent. The test must prove Hermes used a tool, not just that the model guessed
an answer.

Create a ground-truth file inside the sandbox:

```bash
nemohermes "$HERMES_SANDBOX" exec -- \
  sh -lc 'printf "real-%s\n" "$(date +%s)" > /tmp/hermes-ground-truth.txt && cat /tmp/hermes-ground-truth.txt'
```

Ask Hermes to read it through its terminal tool:

```bash
nemohermes "$HERMES_SANDBOX" exec --workdir /sandbox -- \
  hermes chat \
    --yolo \
    -t terminal,file \
    -Q \
    -q "Use the terminal tool to run: cat /tmp/hermes-ground-truth.txt. Return only the observed command output."
```

Expected result:

```text
real-<timestamp>
```

Verify the session actually used a tool:

```bash
nemohermes "$HERMES_SANDBOX" exec -- \
  hermes logs --since 2m | grep -E 'tool_turns|conversation turn' | tail -n 12
```

Pass marker:

```text
tool_turns=1
```

Fail marker:

```text
tool_turns=0
```

If you get `tool_turns=0`, do not use Hermes for file-inspection or editing
tasks yet. Use shell commands as the source of truth and treat Hermes as a chat
or summarization endpoint only.

## 9. Try Alternate Models Safely

After the Nemotron baseline works, you can recreate a separate sandbox with a
different model. Do not replace the working sandbox until the new one passes
both the gateway smoke test and the tool-calling gate.

Example with Qwen:

```bash
export HERMES_SANDBOX=fde-hermes-nebius-qwen
export NEBIUS_TF_MODEL=Qwen/Qwen3-235B-A22B-Instruct-2507

# Repeat Steps 4, 6, 7, and 8.
```

Example with a Hermes-family model:

```bash
export HERMES_SANDBOX=fde-hermes-nebius-hermes4
export NEBIUS_TF_MODEL=NousResearch/Hermes-4-70B

# Repeat Steps 4, 6, 7, and 8.
```

Keep notes for each sandbox:

```text
sandbox=
model=
direct_token_factory_smoke=
hermes_gateway_smoke=
tool_calling_gate=
notes=
```

## 10. Connect From Your Laptop

For the dashboard and local API, keep an SSH tunnel open from your laptop:

```bash
ssh -L 18789:127.0.0.1:18789 -L 8642:127.0.0.1:8642 <user>@<vps-host>
```

Then open:

```text
http://127.0.0.1:18789/
```

Treat any dashboard auth URL, one-time helper URL, or gateway token as a secret.

Terminal chat from the VPS:

```bash
export PATH="$HOME/.local/bin:$PATH"
nemohermes "$HERMES_SANDBOX" connect
```

## Troubleshooting

### `COMPATIBLE_API_KEY` vs `NEBIUS_API_KEY`

Nebius docs use `NEBIUS_API_KEY`. NemoClaw's custom OpenAI-compatible provider
expects that same key to be passed as `COMPATIBLE_API_KEY` during onboarding.

Keep `NEBIUS_API_KEY` as your normal shell variable, then map it only at install
time:

```bash
COMPATIBLE_API_KEY="$NEBIUS_API_KEY"
```

### `nemohermes` is not found after install

Refresh `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
command -v nemohermes
```

If that works, add the PATH line to the shell profile used on the VPS.

### Token Factory returns `401`

The key is missing, invalid, or not loaded:

```bash
source "$HOME/.config/pi-nebius/env"
test -n "$NEBIUS_API_KEY" && echo "key loaded"
```

If the key is loaded and `401` continues, create a new key in the Token Factory
console.

### Hermes gateway returns `200` but tools do not run

This is the important failure mode. The dashboard and `/v1/chat/completions`
can work while Hermes still chooses plain text instead of tool calls.

Try a separate sandbox with another tool-capable model, such as:

```bash
Qwen/Qwen3-235B-A22B-Instruct-2507
NousResearch/Hermes-4-70B
nvidia/Nemotron-3-Nano-Omni
```

Only promote a model after Step 8 logs `tool_turns=1`.

### Existing direct Hermes process is already running

If the VPS has a direct Hermes process under `~/.hermes`, leave it running while
you test the NemoClaw sandbox unless ports conflict.

If ports `18789` or `8642` are already in use, inspect the owner:

```bash
ss -ltnp | grep -E ':18789|:8642' || true
```

Do not kill the process until you know whether it is the currently used Hermes
gateway. Prefer a separate sandbox name first.

## References

- NemoClaw prerequisites:
  https://docs.nvidia.com/nemoclaw/user-guide/hermes/get-started/prerequisites.md
- NemoClaw Hermes quickstart:
  https://docs.nvidia.com/nemoclaw/user-guide/hermes/get-started/quickstart.md
- Nebius Token Factory quickstart:
  https://docs.tokenfactory.nebius.com/quickstart
- Token Factory model list API:
  https://docs.tokenfactory.nebius.com/api-reference/models/list-models.md
- Related Pi setup:
  [Pi Coding Agent on a Nebius Token Factory VPS](pi-coding-agent-nebius-vps.md)
