# Status

## Objective
Switch Claude Code between alternative providers (GLM/z.ai, Kimi, DeepSeek, …)
without duplicating `settings.json` and without storing tokens in clear in the
config. Single canonical `settings.json`, provider routing injected via env.

## Current focus
Initial tool is built and verified. Pending: optional `git commit` of the repo.

## Log

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
