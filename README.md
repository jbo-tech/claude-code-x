# claude-code-x

Switch Claude Code between alternative providers (GLM/z.ai, Kimi, DeepSeek, …)
without ever touching your `settings.json`.

## Why

The naive approach — keeping one full `settings.json` per provider and swapping
them — duplicates your permissions/hooks/statusline across files that then drift
apart, and stores API tokens in world-readable config. `claude-code-x` keeps a
single canonical `settings.json` and injects only the **provider variables**
(base URL, auth token, model names) through the environment at launch.

## How it works

`ccx <provider>` sources `~/.config/claude-code-x/<provider>.env`, then
`exec claude`. The token lives only in that short-lived process's environment:

- never written into `settings.json`
- never exported into your interactive shell (the script is its own process)
- `exec` leaves no parent process holding it
- `ulimit -c 0` prevents a crash core dump from capturing it
- `ccx` refuses any `.env` not `chmod 600`/`400` (fail loud, don't leak)

`settings.json` (permissions, hooks, statusline) is always read by Claude Code
regardless of provider — so it stays the single source of truth and the same
rules apply everywhere. No divergence by construction.

## Install

```sh
./install.sh
```

Creates `~/.config/claude-code-x/` (700) and symlinks `ccx` into
`~/.local/bin`.

## Add a provider

Interactive (recommended) — token input is hidden, file written `600`:

```sh
ccx add            # prompts for name, base URL, model, token
ccx add glm        # name given, prompts for the rest
```

Or by hand, from the template:

```sh
cp providers.env.example ~/.config/claude-code-x/glm.env
$EDITOR ~/.config/claude-code-x/glm.env   # set ANTHROPIC_AUTH_TOKEN
chmod 600 ~/.config/claude-code-x/glm.env
```

`ccx add` writes only base URL, token and default model. For per-tier model
overrides (`ANTHROPIC_DEFAULT_SONNET_MODEL`, `…HAIKU…`, subagent, effort), edit
the resulting `.env` — see `providers.env.example`.

## Use

```sh
ccx glm          # Claude Code on GLM/z.ai
ccx kimi         # Claude Code on Kimi/Moonshot
ccx deepseek     # Claude Code on DeepSeek
ccx              # help + provider list (with their routes)
ccx add [name]   # add a provider interactively
claude           # untouched: official Anthropic
```

## Central provider keys

Other projects (llm-sparring, jobset&match-v2) use a shared key store at
`~/.config/llm-provider-keys/providers.env`. ccx does **not** read from it
directly — it uses its own per-provider `.env` files because each provider
overrides `ANTHROPIC_BASE_URL`, model names, and auth in a way that's specific
to the Claude Code API proxy pattern.

If you want to avoid duplicating raw API keys between ccx and the central store,
you can source the central file inside a provider `.env`:

```bash
# ~/.config/claude-code-x/deepseek.env
# shellcheck source=/dev/null
. "$HOME/.config/llm-provider-keys/providers.env"
ANTHROPIC_BASE_URL=https://api.deepseek.com
ANTHROPIC_AUTH_TOKEN=$DEEPSEEK_API_KEY
ANTHROPIC_MODEL=deepseek-chat
```

This is optional — ccx works fine standalone.

## Security notes

- Secrets live in `~/.config/claude-code-x/*.env`, `600`, **outside this repo**.
  `.gitignore` blocks `*.env` as a belt-and-braces second line.
- The real exposure for this threat model (revocable third-party LLM keys, a
  single-user laptop) is **backup/sync, not the file mode**: make sure
  `~/.config/claude-code-x` is not synced in clear to any cloud, and prefer a
  LUKS-encrypted disk against physical theft. If you can't exclude it from an
  uncontrolled sync, switch to encrypting the tokens at rest (e.g. `pass`/GPG).
