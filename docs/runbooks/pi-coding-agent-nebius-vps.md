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
| Cheap fallback | `Qwen/Qwen3-30B-A3B-Instruct-2507` | Fast inexpensive edits and checks. |
| Escalation | `deepseek-ai/DeepSeek-V4-Pro` | Hard tasks or very large-context repo work. |

Pricing in the Pi config is per million tokens. Verify live prices in Token
Factory before using this for budget planning.

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
        or .id == "Qwen/Qwen3-30B-A3B-Instruct-2507"
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
          "id": "Qwen/Qwen3-30B-A3B-Instruct-2507",
          "name": "Qwen3 30B A3B Instruct via Nebius Token Factory",
          "input": ["text"],
          "reasoning": false,
          "contextWindow": 262144,
          "maxTokens": 8192,
          "cost": {
            "input": 0.1,
            "output": 0.3,
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
    "nebius-token-factory/Qwen/Qwen3-30B-A3B-Instruct-2507",
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
