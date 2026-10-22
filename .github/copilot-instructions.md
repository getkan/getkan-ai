# GitHub Copilot instructions

- Follow the repository instructions in `AGENTS.md`.
- Read `docs/SPEC.md`, `docs/ROADMAP.md`, and `docs/TASKS.md` when present and when the task requires project requirements or workflow state.
- Keep changes focused, preserve unrelated worktree changes, and validate edits with the smallest relevant command.
- Do not read, print, commit, or modify `.env`; it contains local secrets.
- OpenRouter is the repository's external model provider. GitHub Copilot remains a separate VS Code service and is not routed through OpenRouter.
- Run `./scripts/install.sh` to install the repository's OpenRouter configuration and Zsh environment functions. Invoke `codex` directly after reloading `.zshrc`.
