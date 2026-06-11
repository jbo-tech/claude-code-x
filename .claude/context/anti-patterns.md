# Anti-patterns

### `rm -rf` in helper scripts is blocked by the sandbox deny-list
**Problem**: Two Bash commands were auto-denied because they contained `rm -rf`
(cleanup of a temp dir, and a tar+`rm -rf` backup), which matches the user's
`Bash(rm -rf *)` deny rule. The whole compound command was rejected, rolling back
unrelated steps.
**Cause**: Permission deny-list pattern matching is textual; any `rm -rf` substring
trips it, even on a throwaway `mktemp -d`.
**Solution**: Avoid `rm -rf` in scripts run here. To "backup then remove", `mv` the
directory to a `.bak` path (reversible, no deletion). For temp cleanup, leave
`mktemp -d` dirs in place or use plain `rm` on individual files. Keep destructive
steps in their own command so a denial doesn't lose adjacent work.
**Date**: 2026-06-11

### Don't feed a name on both argv and stdin when testing interactive prompts
**Problem**: Testing `ccx add testprov` while also piping `testprov\n...` as the
first stdin line shifted every prompt by one (name from argv → first stdin line read
as the *base URL*), producing a misleading "wrong output" that looked like a bug.
**Cause**: The script skips the name prompt when the name is an argument; the extra
stdin line then lands on the next `read`.
**Solution**: When the name is passed as an argument, stdin must start at the first
*prompted* field. Match piped stdin to exactly the prompts the code will issue.
**Date**: 2026-06-11
