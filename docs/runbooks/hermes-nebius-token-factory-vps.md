# Hermes With Nebius Token Factory On A VPS

This guide adds Nebius Token Factory as an OpenAI-compatible provider in an
existing Hermes install.

Use it when Hermes already runs on the VPS and you only want to extend its model
configuration. It does not install a separate runtime, create containers, or
replace a working Hermes setup.

## Target Config

```text
Hermes -> custom provider -> Nebius Token Factory -> selected model
```

Prerequisites:

- Hermes already installed on the VPS.
- Nebius Token Factory API key stored outside the repo.
- `curl` available for smoke tests.
- `jq` optional but useful for reading JSON responses.

Recommended default:

```text
Qwen/Qwen3-235B-A22B-Instruct-2507
```

Useful additions:

| Alias | Model | Use |
| --- | --- | --- |
| `nebius-qwen` | `Qwen/Qwen3-235B-A22B-Instruct-2507` | Main coding-agent default. |
| `nebius-cheap` | `nvidia/Nemotron-3-Nano-Omni` | Lower-cost routing tests and light tasks. |
| `nebius-big` | `deepseek-ai/DeepSeek-V4-Pro` | Expensive escalation for large-context work. |

After Step 2, verify live model names and pricing before publishing budget
claims:

```bash
curl -fsS "https://api.tokenfactory.nebius.com/v1/models?verbose=true" \
  -H "Authorization: Bearer $NEBIUS_API_KEY" \
  -H "Accept: application/json" \
| jq -r '.data[] | select(.id | test("Qwen3-235B|Nemotron-3-Nano-Omni|DeepSeek-V4-Pro")) | [.id, .context_length, .pricing.prompt, .pricing.completion] | @tsv'
```

## 1. Inspect Existing Hermes

Run these read-only checks first:

```bash
set +x

command -v hermes || true
hermes --version 2>/dev/null || true
hermes config get model 2>/dev/null || true

ls -la "$HOME/.hermes" 2>/dev/null || true
ps aux | grep -Ei 'hermes' | grep -v grep || true
```

If Hermes is currently running, leave it running while you inspect and back up
the config. The provider change below is file-level config; restart only if the
running process does not pick up the change.

## 2. Configure Hermes With The Script

Preferred path:

```bash
curl -fsSL https://raw.githubusercontent.com/fruteroclub/tooling-and-research/main/code/scripts/configure-hermes-nebius-token-factory.sh | bash
```

The script:

- backs up `~/.hermes/config.yaml` and `~/.hermes/.env`;
- reads `NEBIUS_API_KEY` from the shell or `~/.config/pi-nebius/env`;
- writes the key to `~/.hermes/.env` only if it is missing;
- merges a named `custom:nebius-token-factory` provider into
  `~/.hermes/config.yaml`;
- preserves unrelated Hermes settings and other custom providers;
- does not write to any Pi config files.

After it finishes, run the smoke tests in Steps 8 and 9.

## 3. Manual Fallback: Load The Token Factory Key

If you completed the Pi Coding Agent guide, reuse its private env file:

```bash
set +x

if [ -f "$HOME/.config/pi-nebius/env" ]; then
  source "$HOME/.config/pi-nebius/env"
fi

if [ -z "${NEBIUS_API_KEY:-}" ]; then
  echo "FAIL: NEBIUS_API_KEY is not loaded"
  return 1 2>/dev/null || exit 1
fi

echo "OK: NEBIUS_API_KEY is loaded"
```

Do not print the key. Do not paste it into chat. Do not commit it.

## 4. Manual Fallback: Back Up Hermes Config

```bash
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config/hermes-nebius/backups/$TS"
install -d -m 700 "$BACKUP_DIR"

[ -f "$HOME/.hermes/config.yaml" ] && cp "$HOME/.hermes/config.yaml" "$BACKUP_DIR/config.yaml"
[ -f "$HOME/.hermes/.env" ] && cp "$HOME/.hermes/.env" "$BACKUP_DIR/env"

printf 'backup_dir=%s\n' "$BACKUP_DIR"
```

Rollback is just:

```bash
cp "$BACKUP_DIR/config.yaml" "$HOME/.hermes/config.yaml"
cp "$BACKUP_DIR/env" "$HOME/.hermes/.env"
```

## 5. Manual Fallback: Add The Secret To Hermes

Hermes supports secrets in `~/.hermes/.env`. Add the Nebius key there so the
YAML config can reference `NEBIUS_API_KEY` without storing the secret in YAML.

```bash
set +x
install -d -m 700 "$HOME/.hermes"
touch "$HOME/.hermes/.env"
chmod 600 "$HOME/.hermes/.env"

if grep -q '^NEBIUS_API_KEY=' "$HOME/.hermes/.env"; then
  echo "OK: ~/.hermes/.env already has NEBIUS_API_KEY"
else
  if [ -z "${NEBIUS_API_KEY:-}" ]; then
    echo "FAIL: NEBIUS_API_KEY is not loaded"
    return 1 2>/dev/null || exit 1
  fi
  printf '\nNEBIUS_API_KEY=%s\n' "$NEBIUS_API_KEY" >> "$HOME/.hermes/.env"
  echo "OK: added NEBIUS_API_KEY to ~/.hermes/.env"
fi
```

## 6. Manual Fallback: Add Nebius As A Hermes Provider

Open the Hermes config:

```bash
hermes config edit
```

Merge this block into `~/.hermes/config.yaml`. Keep existing unrelated settings.
If `custom_providers` or `model_aliases` already exist, add these entries under
the existing top-level keys instead of duplicating the keys.

```yaml
custom_providers:
  - name: nebius-token-factory
    base_url: https://api.tokenfactory.nebius.com/v1/
    key_env: NEBIUS_API_KEY
    api_mode: chat_completions
    models:
      Qwen/Qwen3-235B-A22B-Instruct-2507:
        context_length: 262144
      nvidia/Nemotron-3-Nano-Omni:
        context_length: 262144
      deepseek-ai/DeepSeek-V4-Pro:
        context_length: 1048576

model:
  provider: custom:nebius-token-factory
  default: Qwen/Qwen3-235B-A22B-Instruct-2507

model_aliases:
  nebius-qwen:
    provider: custom:nebius-token-factory
    model: Qwen/Qwen3-235B-A22B-Instruct-2507
  nebius-cheap:
    provider: custom:nebius-token-factory
    model: nvidia/Nemotron-3-Nano-Omni
  nebius-big:
    provider: custom:nebius-token-factory
    model: deepseek-ai/DeepSeek-V4-Pro
```

Why this shape:

- `custom_providers` gives Token Factory a stable provider name inside Hermes.
- `base_url` points at the OpenAI-compatible Token Factory endpoint.
- `key_env` keeps the API key in `~/.hermes/.env`.
- `model.provider` makes Nebius the default provider.
- `model.default` sets the default model Hermes should use.
- `model_aliases` gives you short names for switching during experiments.

For a fresh or empty config file, this whole block can be the complete config.
For an existing config, merge it carefully instead of overwriting active
settings.

## 7. Validate Hermes Config

```bash
hermes config check
hermes config get model
```

Expected model output should include:

```text
provider: custom:nebius-token-factory
default: Qwen/Qwen3-235B-A22B-Instruct-2507
```

If Hermes reports a YAML parse error, restore the backup and re-merge the block.

## 8. Smoke Test Token Factory Directly

This uses the same key but bypasses Hermes, so failures are easier to isolate.
It spends a tiny Token Factory request.

```bash
HTTP_CODE=$(curl -sS -o /tmp/nebius-token-factory-smoke.json -w '%{http_code}' \
  -H "Authorization: Bearer $NEBIUS_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary '{
    "model": "Qwen/Qwen3-235B-A22B-Instruct-2507",
    "messages": [
      {"role": "user", "content": "Reply exactly: token-factory-ok"}
    ],
    "max_tokens": 64,
    "temperature": 0
  }' \
  "https://api.tokenfactory.nebius.com/v1/chat/completions")

printf 'http=%s\n' "$HTTP_CODE"
jq -r '.choices[0].message.content // empty' /tmp/nebius-token-factory-smoke.json
```

Expected:

```text
http=200
token-factory-ok
```

If `jq` is not installed, either install it or inspect the JSON file manually:

```bash
python3 -m json.tool /tmp/nebius-token-factory-smoke.json | sed -n '1,120p'
```

## 9. Smoke Test Hermes

```bash
hermes chat -Q -q "Reply exactly: hermes-nebius-ok"
```

Expected:

```text
hermes-nebius-ok
```

If the direct Token Factory test works but Hermes fails, check:

```bash
hermes config get model
hermes config get custom_providers
grep '^NEBIUS_API_KEY=' "$HOME/.hermes/.env" >/dev/null && echo "Hermes key entry exists"
```

Do not print the key while debugging.

## 10. Switch Models

After the default works, test aliases one at a time:

```bash
hermes chat -Q -m nebius-cheap -q "Reply exactly: cheap-ok"
hermes chat -Q -m nebius-big -q "Reply exactly: big-ok"
```

If aliases do not resolve in your Hermes version, use the full provider-qualified
model name inside chat:

```text
/model custom:nebius-token-factory:nvidia/Nemotron-3-Nano-Omni
```

Keep Qwen as the default until a replacement passes real coding-agent tasks.

## 11. Restart Only If Needed

If a long-running Hermes process does not pick up config changes, restart the
existing process using the same mechanism that already manages it on the VPS.
First identify how it is running:

```bash
ps aux | grep -Ei 'hermes' | grep -v grep || true
systemctl --user status hermes 2>/dev/null || true
```

Use the existing service manager or shell session. Avoid changing unrelated
startup files while validating the provider config.

## Troubleshooting

### `Unknown provider`

Check that `provider` is exactly:

```yaml
provider: custom:nebius-token-factory
```

and that the matching provider entry is named:

```yaml
name: nebius-token-factory
```

### `401` Or `Unauthorized`

The key is missing, expired, or not loaded by Hermes:

```bash
grep '^NEBIUS_API_KEY=' "$HOME/.hermes/.env" >/dev/null && echo "key entry exists"
chmod 600 "$HOME/.hermes/.env"
```

If the entry exists and direct `curl` still returns `401`, create a new Token
Factory key and replace the value in `~/.hermes/.env`.

### YAML Parse Error

Restore the backup, then re-merge:

```bash
cp "$BACKUP_DIR/config.yaml" "$HOME/.hermes/config.yaml"
hermes config edit
```

Common causes are duplicate top-level keys, tabs, and incorrect indentation.

### Model Exists In Catalog But Hermes Still Fails

Use the direct curl smoke test first. If curl works, the problem is Hermes
config shape, not Token Factory access. Re-check `custom_providers`, `key_env`,
and `model.provider`.

## References

- Hermes configuration:
  https://hermes-agent.nousresearch.com/docs/user-guide/configuration
- Hermes custom providers:
  https://hermes-agent.nousresearch.com/docs/integrations/providers
- Hermes source:
  https://github.com/NousResearch/hermes-agent
- Nebius Token Factory quickstart:
  https://docs.tokenfactory.nebius.com/quickstart
- Related Pi setup:
  [Pi Coding Agent on a Nebius Token Factory VPS](pi-coding-agent-nebius-vps.md)
