# Pi Coding Agent On A Nebius Token Factory VPS

This guide sets up Pi Coding Agent as the main terminal coding agent on an
Ubuntu VPS, using Nebius Token Factory as the model provider.

The default model is `Qwen/Qwen3-235B-A22B-Instruct-2507`. It is a strong
daily-driver choice because it has a large context window, tool support, and a
much lower Token Factory price than the most expensive long-context models.

## Model Stack

| Role | Model | Use |
| --- | --- | --- |
| Default | `Qwen/Qwen3-235B-A22B-Instruct-2507` | Main Pi Coding Agent driver. |
| Cheap fallback | `nvidia/Nemotron-3-Nano-Omni` | Low-cost Nebius/NVIDIA option for routine edits and checks. |
| Escalation | `deepseek-ai/DeepSeek-V4-Pro` | Hard tasks or very large-context repo work. |

Pricing in the Pi config is per million tokens. Verify live prices in Token
Factory before using this for budget planning.

## Model Comparison For Pi Coding Agent

This table uses the live Nebius Token Factory catalog as the reference for
prices, context, feature support, and model positioning.

| Status | Model | Price $/M in/out | Context | Features | Suggested use | Catalog signal | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Installed default | `Qwen/Qwen3-235B-A22B-Instruct-2507` | `0.20 / 0.60` | 262K | tools, JSON, structured outputs | Main daily driver | Flagship Qwen tuned for reasoning, chat, and tool use. | Strong balance of capability, context, and cost. |
| Installed fallback | `nvidia/Nemotron-3-Nano-Omni` | `0.06 / 0.24` | 262K | tools, JSON, structured outputs, reasoning | Cheap routine edits and checks | NVIDIA model positioned for efficient agentic AI. | Good Nebius/NVIDIA content angle. |
| Installed escalation | `deepseek-ai/DeepSeek-V4-Pro` | `1.75 / 3.50` | 1M | tools, JSON, structured outputs, reasoning | Hard long-horizon repo work | Designed for advanced coding and long-horizon agent workflows. | Expensive; use deliberately. |
| Suggested addition | `openai/gpt-oss-120b` | `0.15 / 0.60` | 131K | tools, JSON, structured outputs, reasoning | Open agentic model comparison | Open-weight agentic model with strong tool use. | Good benchmark/content contrast. |
| Suggested addition | `NousResearch/Hermes-4-70B` | `0.13 / 0.40` | 131K | tools, JSON, structured outputs, reasoning | Hermes ecosystem experiments | Compact Hermes model for reasoning and coding. | Fits Hermes/NemoClaw research. |
| Suggested addition | `moonshotai/Kimi-K2.7-Code` | `0.95 / 4.00` | 8K | tools, JSON, structured outputs, reasoning | Code-specialist experiments | Code-focused reasoning model for software engineering and tool use. | Context is small and output is pricey. |
| Suggested addition | `meta-llama/Llama-3.3-70B-Instruct` | `0.13 / 0.40` | 131K | tools | General baseline | Refined Llama instruct model with broad benchmark performance. | Useful familiar open-model baseline. |
| Suggested addition | `nvidia/nemotron-3-super-120b-a12b` | `0.30 / 0.90` | 262K | tools, JSON, structured outputs, reasoning | Stronger NVIDIA escalation | Nemotron Super is positioned for multi-agent and complex reasoning. | More expensive than Nano Omni, cheaper than DeepSeek. |

## Prerequisites

- Ubuntu VPS with shell access.
- Bash shell for the copy-paste command blocks.
- Node.js and npm, or permission to install them.
- Nebius Token Factory API key.
- `sudo` access for system packages and global CLI install.

Do not commit API keys. Do not paste the API key inline into a command that will
land in shell history.

## 1. Install Baseline Packages

Run on the VPS:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git jq
```

Check Node.js:

```bash
node -v
npm -v
```

Pi should run on current Node.js. If Node is missing or too old, install Node.js
22 using your preferred method. One common Ubuntu path is:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

node -v
npm -v
```

## 2. Install Pi Coding Agent

Run:

```bash
sudo npm install -g --ignore-scripts @earendil-works/pi-coding-agent
hash -r
pi --version
```

Do not run `sudo apt install pi`. Ubuntu's `pi` package is unrelated to Pi
Coding Agent.

## 3. Store The Nebius Token Factory Key

For a daily-driver VPS, store the key in a private shell env file:

```bash
set +x
install -d -m 700 "$HOME/.config/pi-nebius"

read -r -s -p "Paste Nebius Token Factory API key, then press Enter: " NEBIUS_API_KEY
printf "\n"

if [ -z "$NEBIUS_API_KEY" ]; then
  echo "FAIL: NEBIUS_API_KEY is empty"
  return 1 2>/dev/null || exit 1
fi

printf 'export NEBIUS_API_KEY=%q\n' "$NEBIUS_API_KEY" > "$HOME/.config/pi-nebius/env"
chmod 600 "$HOME/.config/pi-nebius/env"

grep -qxF '[ -f "$HOME/.config/pi-nebius/env" ] && source "$HOME/.config/pi-nebius/env"' "$HOME/.bashrc" \
  || printf '\n[ -f "$HOME/.config/pi-nebius/env" ] && source "$HOME/.config/pi-nebius/env"\n' >> "$HOME/.bashrc"

source "$HOME/.config/pi-nebius/env"
echo "OK: Nebius Token Factory key is available to this shell"
```

This writes the key only to `~/.config/pi-nebius/env`, with user-only file
permissions. The command does not print the key.

## 4. Confirm Token Factory Access

Run:

```bash
curl -fsS "https://api.tokenfactory.nebius.com/v1/models?verbose=true" \
  -H "Authorization: Bearer $NEBIUS_API_KEY" \
  -H "Accept: application/json" \
| jq -r '.data[]
  | select(.id == "Qwen/Qwen3-235B-A22B-Instruct-2507"
        or .id == "nvidia/Nemotron-3-Nano-Omni"
        or .id == "deepseek-ai/DeepSeek-V4-Pro")
  | "\(.id) | context=\(.context_length) | prompt=\(.pricing.prompt) | completion=\(.pricing.completion)"'
```

Expected: three lines, one for each configured model.

## 5. Configure Pi Models

Run:

```bash
install -d -m 700 "$HOME/.pi/agent"

cat > "$HOME/.pi/agent/models.json" <<'EOF'
{
  "providers": {
    "nebius-token-factory": {
      "baseUrl": "https://api.tokenfactory.nebius.com/v1/",
      "api": "openai-completions",
      "apiKey": "$NEBIUS_API_KEY",
      "models": [
        {
          "id": "Qwen/Qwen3-235B-A22B-Instruct-2507",
          "name": "Qwen3 235B A22B Instruct via Nebius Token Factory",
          "input": ["text"],
          "reasoning": false,
          "contextWindow": 262144,
          "maxTokens": 8192,
          "cost": {
            "input": 0.2,
            "output": 0.6,
            "cacheRead": 0,
            "cacheWrite": 0
          },
          "compat": {
            "supportsReasoningEffort": false
          }
        },
        {
          "id": "nvidia/Nemotron-3-Nano-Omni",
          "name": "Nemotron 3 Nano Omni via Nebius Token Factory",
          "input": ["text"],
          "reasoning": false,
          "contextWindow": 262144,
          "maxTokens": 8192,
          "cost": {
            "input": 0.06,
            "output": 0.24,
            "cacheRead": 0,
            "cacheWrite": 0
          },
          "compat": {
            "supportsReasoningEffort": false
          }
        },
        {
          "id": "deepseek-ai/DeepSeek-V4-Pro",
          "name": "DeepSeek V4 Pro via Nebius Token Factory",
          "input": ["text"],
          "reasoning": false,
          "contextWindow": 1048576,
          "maxTokens": 8192,
          "cost": {
            "input": 1.75,
            "output": 3.5,
            "cacheRead": 0,
            "cacheWrite": 0
          },
          "compat": {
            "supportsReasoningEffort": false
          }
        }
      ]
    }
  }
}
EOF

chmod 600 "$HOME/.pi/agent/models.json"
```

This uses `apiKey: "$NEBIUS_API_KEY"` deliberately. Pi resolves the environment
variable at request time.

## 6. Configure Pi Defaults

Run:

```bash
cat > "$HOME/.pi/agent/settings.json" <<'EOF'
{
  "defaultProvider": "nebius-token-factory",
  "defaultModel": "Qwen/Qwen3-235B-A22B-Instruct-2507",
  "defaultThinkingLevel": "off",
  "enabledModels": [
    "nebius-token-factory/Qwen/Qwen3-235B-A22B-Instruct-2507",
    "nebius-token-factory/nvidia/Nemotron-3-Nano-Omni",
    "nebius-token-factory/deepseek-ai/DeepSeek-V4-Pro"
  ]
}
EOF

chmod 600 "$HOME/.pi/agent/settings.json"
```

## 7. Validate The Config

Run:

```bash
jq empty "$HOME/.pi/agent/models.json"
jq empty "$HOME/.pi/agent/settings.json"

jq -r '"defaultProvider=\(.defaultProvider)\ndefaultModel=\(.defaultModel)"' \
  "$HOME/.pi/agent/settings.json"

pi --list-models nebius-token-factory | sed -n '1,80p'
```

Expected:

```text
defaultProvider=nebius-token-factory
defaultModel=Qwen/Qwen3-235B-A22B-Instruct-2507
```

The model list should include the three configured Token Factory models.

## 8. Smoke Test Token Factory

Before starting a long Pi session, confirm the default model can answer:

```bash
curl -fsS "https://api.tokenfactory.nebius.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $NEBIUS_API_KEY" \
  --data-binary '{
    "model": "Qwen/Qwen3-235B-A22B-Instruct-2507",
    "max_tokens": 64,
    "messages": [
      {
        "role": "user",
        "content": "Reply exactly: pi token factory ok"
      }
    ]
  }' \
| jq -r '.choices[0].message.content'
```

Expected:

```text
pi token factory ok
```

Minor whitespace differences are fine.

## 9. Start Pi

Move into the repo or project directory you want Pi to edit, then run:

```bash
source "$HOME/.config/pi-nebius/env"
pi
```

The startup model should be:

```text
Qwen/Qwen3-235B-A22B-Instruct-2507
```

Inside Pi, use `/model` if you need to switch to the cheaper fallback or the
DeepSeek escalation model.

## 10. Add More Models Safely

After the baseline setup works, you can ask Pi to expand its own Nebius Token
Factory model list. Treat this as a config change to a live tool: back up first,
preserve the working default, validate JSON before replacing files, and smoke
test at least one newly added model.

Good content-oriented models to consider:

| Role | Model | Why |
| --- | --- | --- |
| Open agentic model | `openai/gpt-oss-120b` | Useful contrast against closed coding models; tools/json/structured outputs. |
| Hermes ecosystem model | `NousResearch/Hermes-4-70B` | Fits Hermes/NemoClaw content and agent-runtime experiments. |
| Code specialist | `moonshotai/Kimi-K2.7-Code` | Code-focused model; worth testing even though its context is smaller. |
| Familiar open baseline | `meta-llama/Llama-3.3-70B-Instruct` | Broadly recognized model family for comparison. |
| Stronger NVIDIA escalation | `nvidia/nemotron-3-super-120b-a12b` | Higher-capability NVIDIA/Nebius option than Nano Omni. |
| Expensive escalation | `deepseek-ai/DeepSeek-V4-Pro` | Keep for hard or very large-context tasks. |

Paste this prompt into Pi from the VPS directory where you want it to work:

```text
You are helping me update my Pi Coding Agent configuration on this VPS.

Goal:
Expand the Nebius Token Factory model menu without breaking the working default
Pi setup.

Current provider:
- Provider id: nebius-token-factory
- Config files:
  - ~/.pi/agent/models.json
  - ~/.pi/agent/settings.json
- Token Factory API key is available as NEBIUS_API_KEY.

Hard safety rules:
1. Do not print, echo, log, or commit NEBIUS_API_KEY or any secret.
2. Do not use sudo for ~/.pi/agent files.
3. Do not run `sudo apt install pi`; that is the wrong Ubuntu package.
4. Do not delete the existing working provider or default model.
5. Preserve defaultProvider and defaultModel unless I explicitly ask you to
   change them.
6. Back up both Pi config files before editing them.
7. Choose model ids from the live Token Factory catalog, not from memory.
8. Keep Nebius Token Factory model entries with:
   - "reasoning": false
   - "compat": { "supportsReasoningEffort": false }
   unless a smoke test proves Pi can safely send reasoning parameters.
9. Validate JSON before replacing any live config file.
10. After editing, run `pi --list-models nebius-token-factory` and one minimal
    smoke test.

Please add these models if they are available in the live catalog:
- openai/gpt-oss-120b
- NousResearch/Hermes-4-70B
- moonshotai/Kimi-K2.7-Code
- meta-llama/Llama-3.3-70B-Instruct
- nvidia/nemotron-3-super-120b-a12b

Keep these existing roles:
- Qwen/Qwen3-235B-A22B-Instruct-2507 as the default daily-driver model.
- nvidia/Nemotron-3-Nano-Omni as the cheap Nebius/NVIDIA fallback model.
- deepseek-ai/DeepSeek-V4-Pro as the expensive escalation model.

Implementation requirements:
- First inspect the current ~/.pi/agent/models.json and
  ~/.pi/agent/settings.json.
- Create timestamped backups under ~/.pi/agent/backups/.
- Fetch the live catalog with:
  curl -fsS "https://api.tokenfactory.nebius.com/v1/models?verbose=true" \
    -H "Authorization: Bearer $NEBIUS_API_KEY" \
    -H "Accept: application/json"
- For each added model, set:
  - id from the live catalog
  - name from the live catalog when available
  - input: ["text"]
  - contextWindow from context_length
  - maxTokens: 8192
  - cost using per-million-token pricing:
    - input = pricing.prompt * 1000000
    - output = pricing.completion * 1000000
    - cacheRead = 0
    - cacheWrite = 0
  - reasoning: false
  - compat.supportsReasoningEffort: false
- Add each enabled model to settings.json as:
  nebius-token-factory/<model-id>
- Preserve existing enabled models.
- Write to temporary files first, validate them with jq, then atomically move
  them into place.

Validation:
- Run:
  jq empty ~/.pi/agent/models.json
  jq empty ~/.pi/agent/settings.json
  jq -r '"defaultProvider=\(.defaultProvider)\ndefaultModel=\(.defaultModel)"' ~/.pi/agent/settings.json
  pi --list-models nebius-token-factory | sed -n '1,120p'
- Then smoke test one newly added model with a short prompt:
  "Reply exactly: nebius model ok"

Report back:
- Which models were added.
- Which requested models were unavailable, if any.
- The default model after the change.
- The backup file paths.
- The validation commands and results.
```

If the model list breaks, restore the latest backups:

```bash
ls -lt "$HOME/.pi/agent/backups"
cp "$HOME/.pi/agent/backups/<models-backup>.json" "$HOME/.pi/agent/models.json"
cp "$HOME/.pi/agent/backups/<settings-backup>.json" "$HOME/.pi/agent/settings.json"
jq empty "$HOME/.pi/agent/models.json"
jq empty "$HOME/.pi/agent/settings.json"
pi --list-models nebius-token-factory | sed -n '1,80p'
```

## Troubleshooting

### `pi --list-models` does not show the Nebius models

Check that the key is available:

```bash
source "$HOME/.config/pi-nebius/env"
test -n "$NEBIUS_API_KEY" && echo "key loaded"
```

Then check JSON validity:

```bash
jq empty "$HOME/.pi/agent/models.json"
jq empty "$HOME/.pi/agent/settings.json"
```

### Token Factory returns `401`

The API key is missing, invalid, or not loaded in the current shell. Load it
again:

```bash
source "$HOME/.config/pi-nebius/env"
```

If that still fails, create a new API key in the Token Factory console.

### Pi returns a provider `422`

Keep the Nebius model entries with:

```json
"reasoning": false,
"compat": {
  "supportsReasoningEffort": false
}
```

Some Token Factory models report reasoning support in the catalog, but Pi may
send reasoning parameters the provider route does not accept.

### The model spends too many tokens before answering

Use the default Qwen model first. Avoid defaulting to models that consume hidden
reasoning tokens heavily unless you have validated them in Pi with your actual
workflow.

## References

- Pi docs: https://pi.dev/docs/latest
- Pi custom models: https://pi.dev/docs/latest/models
- Nebius Token Factory quickstart: https://docs.tokenfactory.nebius.com/quickstart
- Token Factory model list API:
  https://docs.tokenfactory.nebius.com/api-reference/models/list-models.md
