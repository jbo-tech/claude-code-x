# Decisions

### Inject provider env, never rewrite settings.json
**Decision**: Provider switching sets `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN`
/ `ANTHROPIC_*_MODEL` as environment variables at launch; `settings.json` is never
written. `settings.json` (symlinked from the separate `claude-setup` repo) stays the
single source of truth for permissions/hooks/statusline.
**Context**: The old per-provider full `settings.json` copies duplicated everything
and drifted from the canonical file — that divergence was the original problem.
**Alternatives considered**: Tools that rewrite the live `settings.json`
(farion1231/cc-switch, frondesce/claudecode-switch) reproduce the divergence;
desktop Tauri apps (cc-switch, VibeAround) add a heavy third-party dependency with
unaudited key storage.
**Date**: 2026-06-11

### Variant A (file chmod 600) over variant B (pass/GPG)
**Decision**: Store tokens in `~/.config/claude-code-x/<provider>.env`, chmod 600,
dir 700, set explicitly in code (umask-proof). Not encrypted at rest.
**Context**: Threat model = revocable third-party LLM keys on a single-user laptop.
infra-expert confirmed the real exposure is backup/sync + disk encryption, not file
mode; B's marginal gain is small and adds friction. ccx refuses any non-600 .env.
**Alternatives considered**: B (`pass`/GPG, encrypt at rest) — kept as the documented
upgrade path if `~/.config` ends up synced uncontrolled or keys become high-value.
**Date**: 2026-06-11

### Standalone POSIX-sh script, not a zsh function
**Decision**: `ccx` is a script at `~/.local/bin/ccx` (symlinked from the repo),
written in POSIX sh.
**Context**: `ccx` does `exec claude`, so it never needs to mutate the parent shell.
A separate process gives total isolation by construction (no env leak into the
interactive shell). POSIX sh maximises durability over zsh-specific behaviour.
**Alternatives considered**: a zsh function in `.zshrc` — would require an explicit
subshell to avoid env leakage and edits the user's rc file.
**Date**: 2026-06-11

### Naming: repo + config dir `claude-code-x`, command `ccx`
**Decision**: Repo and `~/.config` dir named `claude-code-x` (explicit in the tree);
command stays the short `ccx`.
**Context**: User found `claude-code-other` unclear and wanted something explicit in
the filesystem while keeping a terse command. `claude-setup` is a SEPARATE repo and
must not be touched by this project.
**Date**: 2026-06-11
