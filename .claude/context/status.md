# Status

## Objective
Switch Claude Code between alternative providers (GLM/z.ai, Kimi, DeepSeek, …)
without duplicating `settings.json` and without storing tokens in clear in the
config. Single canonical `settings.json`, provider routing injected via env.
Provider API keys centralized in `~/.config/llm-provider-keys/providers.env`.

## Current focus
Central key store integration complete. Pending: commit, fix minor debt items
(T1 grep pattern, T2 hardcoded path — see `docs/reference.md`).

## Log

### 2026-06-13
- Done:
  - **Audit** of provider key migration against `validation-provider-keys.md`.
    Found: all 4 `.env` files still had hardcoded keys, `GLM_API_KEY` and
    `MOONSHOT_API_KEY` missing from central store, `ccx add` and `install.sh`
    unaware of the central store.
  - **Scoped** 5-step migration plan (store keys, migrate `.env`, `ccx add`
    store option, `install.sh` bootstrap, `providers.env.example` two-pattern).
  - **Implemented** all 5 steps — 6/6 success criteria met:
    - Added `ZAI_API_KEY` + `MOONSHOT_API_KEY` to central store.
    - Rewrote 4 provider `.env` files: all now source central store, no raw keys.
    - `ccx add` prompts "Use central key store?" when store exists; writes
      sourcing pattern or raw token accordingly.
    - `install.sh` proposes creating the central store if absent.
    - `providers.env.example` documents both Pattern A (store) and B (standalone).
  - **Documentation** generated: `docs/architecture.md`, `docs/reference.md`
    (2 drift items, 3 debt items identified).
- Blocked: none.
- Next:
  - Fix T1 (grep pattern injection in `ccx add`) and T2 (hardcoded store path).
  - Update `decisions.md` with central store decision (D1 drift item).
  - `git commit` the session's work.

### 2026-06-11
- Done:
  - Renamed repo `claude-code-switcher` → `claude-code-x` (dir + config dir naming).
  - Built `bin/ccx` (POSIX sh): launches `claude` with provider env sourced from
    `~/.config/claude-code-x/<provider>.env`, `exec` + `ulimit -c 0`, refuses any
    `.env` not chmod 600/400.
  - `install.sh` (idempotent: dir 700 + symlink to `~/.local/bin/ccx`),
    `providers.env.example`, `README.md`, `.gitignore` (`*.env` blocked).
  - Migrated 3 tokens from old `~/.config/claude-code-other/*` into 600 `.env`
    files; old dir moved to locked backup `~/.config/claude-code-other.bak-*`.
  - Added `ccx add [name]` (interactive, hidden token input, single-quoted values
    → metachar-safe, written 600) and a structured help screen (`ccx`) listing
    providers with their route host.
  - Verified: routing for glm/kimi/deepseek, perms, no secret in repo, gitignore,
    canonical `settings.json` untouched, metachar-token robustness. 15/15 criteria.
- Blocked: none.
- Next:
  - Optional: `git commit` initial state.
  - User hygiene (out of code): confirm MEGA doesn't sync `~/.config` (daemon was
    mid-login, not enumerated); delete `~/.config/claude-code-other.bak-*` once
    `ccx` confirmed live; LUKS absent (known caveat for physical theft).
