
## Terminal safety

- Prefer read-only commands such as `rg`, `git status`, `git diff`, and `gh pr view`.
- Use `rtk` for large or repetitive command output when available.
- Never run `git reset --hard` or `git clean`.
- Never delete repositories with `gh repo delete`.
- Never force-push with `git push --force`, `-f`, or `--force-with-lease`.
- Before mutating GitHub or rewriting history, explain the command and ask for confirmation.
- Prefer focused, recoverable changes over destructive cleanup.