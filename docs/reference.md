# Reference — claude-code-x

## Drift — to arbitrate

### Drift (intent vs code)

| # | Type | File to look at | Question to resolve |
|---|------|----------------|---------------------|
| D1 | Diverged | `bin/ccx` / `install.sh` | Decision "Variant A (file chmod 600) over variant B (pass/GPG)" says tokens are stored chmod 600, not encrypted. Code now also supports sourcing from central store — the decision should be updated to reflect the two-tier model (central store + provider `.env`). [→ detail](#d1-central-store-not-in-decisions) |
| D2 | Not applied | `.claude/context/status.md` | Status log stops at 2026-06-11. The `ccx add` central store integration, `install.sh` store bootstrap, and provider `.env` migration (2026-06-13) are not traced. [→ detail](#d2-status-log-stale) |

### Debt

| # | Where | What | Cost of leaving |
|---|-------|------|-----------------|
| T1 | `bin/ccx:115` | `grep -q "^${key_var}="` uses unsanitized user input in a regex pattern. A variable name with regex metacharacters (e.g. `FOO[1]`) would match unintended lines. [→ detail](#t1-grep-pattern-injection) | Low — interactive prompt, single-user tool, but worth a `grep -qF` fix. |
| T2 | `bin/ccx:143` | Central store path is hardcoded in the `printf` inside `add_provider()` rather than using `$CENTRAL_STORE`. [→ detail](#t2-hardcoded-store-path) | Low — only breaks if `$LLM_PROVIDER_KEYS` override is used. |
| T3 | `install.sh:39-55` | The heredoc template in `install.sh` duplicates the key list from the real `providers.env`. No single source of truth for the initial template. [→ detail](#t3-duplicated-template) | Low — one-shot bootstrap, unlikely to drift, but a second place to update. |

### Docs inventory

| File | Verdict | Reason |
|------|---------|--------|
| `README.md` | Complementary | Covers install/usage/security — different purpose from these docs. |
| `.claude/context/decisions.md` | Complementary | Intent record, consumed by drift analysis. Keep. |
| `.claude/context/status.md` | Complementary but stale | See D2. |
| `.claude/context/anti-patterns.md` | Complementary | Dev memory. Keep. |

---

## `bin/ccx` — CLI entry point

### Commands

| Command | Inputs | Behavior | Exit code |
|---------|--------|----------|-----------|
| `ccx` / `ccx -h` / `ccx help` | — | Prints help + provider list to stderr. | 0 |
| `ccx add [name]` | Interactive: name (if not in argv), base URL, model, token or store variable. | Creates `~/.config/claude-code-x/<name>.env` (600). If central store exists, proposes sourcing it. | 0 on success, 1 on validation error or abort. |
| `ccx <provider> [args...]` | Provider name, optional claude args. | Sources `<provider>.env`, validates permissions (600/400), exports env, `exec claude [args]`. | 1 if provider unknown or perms wrong; otherwise claude's exit code. |

### Environment variables consumed

| Variable | Default | Effect |
|----------|---------|--------|
| `CLAUDE_CODE_X_DIR` | `~/.config/claude-code-x` | Config directory for provider `.env` files. |
| `LLM_PROVIDER_KEYS` | `~/.config/llm-provider-keys/providers.env` | Central key store path. Used by `ccx add` to propose sourcing. |

### Environment variables set (exported to claude)

| Variable | Source | Purpose |
|----------|--------|---------|
| `ANTHROPIC_BASE_URL` | Provider `.env` | API endpoint for the proxy. |
| `ANTHROPIC_AUTH_TOKEN` | Provider `.env` (value or `$STORE_VAR`) | Auth token for the proxy. |
| `ANTHROPIC_MODEL` | Provider `.env` | Default model name. |
| `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` | Provider `.env` (optional) | Per-tier model overrides. |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Provider `.env` (optional) | Model for subagents. |
| `CLAUDE_CODE_EFFORT_LEVEL` | Provider `.env` (optional) | Effort level override. |

### Security hardening (launch path)

1. Permission check: refuses any `.env` not chmod 600 or 400.
2. `set -a` / `set +a`: env vars exported only within this process.
3. `ulimit -c 0`: prevents core dumps from capturing the token.
4. `exec claude`: replaces the process — no parent shell retains the env.

### <a id="d1-central-store-not-in-decisions"></a>D1 — Central store not in decisions

`decisions.md` records "Variant A (file chmod 600) over variant B (pass/GPG)" as the token storage decision. The code now has a second layer: provider `.env` files source `~/.config/llm-provider-keys/providers.env` (the central store shared with other projects). This two-tier model is a meaningful architectural choice that should be traced as a decision.

**Action**: add a decision entry for "provider `.env` sources central key store instead of embedding tokens directly".

### <a id="t1-grep-pattern-injection"></a>T1 — grep pattern injection in `ccx add`

Line 115: `grep -q "^${key_var}="` — the variable name comes from user input. If it contains regex metacharacters, the match is unreliable. Fix: use `grep -qF "${key_var}=" | grep "^${key_var}="` or validate `key_var` against `[A-Z_][A-Z0-9_]*`.

### <a id="t2-hardcoded-store-path"></a>T2 — hardcoded store path in add_provider

Line 143: `printf '... "$HOME/.config/llm-provider-keys/providers.env"\n'` — should use `$CENTRAL_STORE` instead of the hardcoded path, so the `$LLM_PROVIDER_KEYS` override is respected.

---

## `install.sh` — installer

### Behavior

1. Creates `~/.config/claude-code-x/` with mode 700.
2. Symlinks `bin/ccx` → `~/.local/bin/ccx`.
3. If `~/.config/llm-provider-keys/providers.env` does not exist, prompts to create it with a commented-out template (700 dir, 600 file).
4. Prints next steps.

Idempotent: re-running overwrites the symlink and skips store creation if it exists.

### <a id="d2-status-log-stale"></a>D2 — Status log stale

`status.md` last entry is 2026-06-11. The central store integration work (2026-06-13) — `ccx add` store option, `install.sh` bootstrap, provider `.env` migration — is not logged.

### <a id="t3-duplicated-template"></a>T3 — duplicated template

The heredoc at lines 39-55 lists key placeholders (`OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, etc.). This duplicates the real store's structure. If a new provider key is added to the convention, two places must be updated. Not urgent — it's a one-shot bootstrap — but worth noting.

---

## `providers.env.example` — template

Documents two patterns:

- **Pattern A (recommended)**: source the central key store, reference the key by variable name (`ANTHROPIC_AUTH_TOKEN=$ZAI_API_KEY`).
- **Pattern B (standalone)**: embed the token directly (`ANTHROPIC_AUTH_TOKEN="REPLACE_ME"`).

Also lists known base URLs for reference (GLM, Kimi, DeepSeek, OpenRouter).

---

## `.gitignore`

Blocks `*.env` (real secrets). Allows `*.env.example` and `providers.env.example` explicitly.

---

## Config resolution order

```
1. ~/.config/llm-provider-keys/providers.env    (central store, sourced by provider .env)
2. ~/.config/claude-code-x/<provider>.env        (provider-specific: URL, model, token ref)
3. Environment variables from the user's shell   (overridden by set -a sourcing)
```

All three layers are shell-sourced (`set -a`), so later assignments win. The central store provides raw keys; the provider `.env` maps them to `ANTHROPIC_*` variables.
