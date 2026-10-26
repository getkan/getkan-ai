# getkan-ai

Portable agent instructions and skills for GitHub Copilot in VS Code and
OpenRouter-backed Codex, with OpenCode-specific configuration and agents.
The installer adapts the shared workflow to each client's configuration and
discovery model.

## Install

For OpenRouter-backed Codex and OpenCode, create `.env` from the example and
add your key. Then preview and install:

```bash
cp .env.example .env
./scripts/install.sh --dry-run
./scripts/install.sh
```

Restart Codex and VS Code after installation. The installer backs up managed
files before replacing them and preserves client runtime state.

## What is managed

- Codex instructions, configuration, command rules, skills, and declared
  marketplaces/plugins.
- OpenCode configuration and generated `ask`, `plan`, `build`, and `review`
  agents.
- Copilot instructions, skills, and custom agents.
- Zsh functions that load the local OpenRouter key for `codex` and `opencode`.

Copilot remains a separate GitHub service; it is not routed through OpenRouter.
The `.env` file is ignored by Git and must never be committed.

## Documentation

- [Agent layout and discovery](docs/AI_LAYOUT.md)
- [Operational workflow and client reference](docs/EDITOR_WORKFLOW.md)
- [Product requirements](docs/SPEC.md), [roadmap](docs/ROADMAP.md), and
  [current tasks](docs/TASKS.md)
- [Codex introduction](docs/CODEX_INTRODUCTION.md),
  [OpenAI model guide](docs/OPEN_AI_INTRODUCTION.md), and
  [Copilot introduction](docs/COPILOT_INTRODUCTION.md)
- [Shared skills](docs/SKILLS.md)

`docs/EDITOR_WORKFLOW.md` is the authoritative procedure for setup, planning,
implementation, review, and editor workflows. The other documents describe
client-specific concepts and link there for operational steps.

## Validate

```bash
./scripts/validate.sh
```
