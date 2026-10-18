# Getkan AI specification

## Problem

Agent installations mix portable configuration with credentials, sessions,
caches, and other machine-local state. Codex and GitHub Copilot also use
different discovery locations. This repository provides one shared agent base
and installs adapters for both clients without replacing project-specific
requirements.

## Users

The primary user is a developer who works on Linux and wants the same safe
GitHub Copilot and OpenRouter-backed Codex or OpenCode baseline in multiple
repositories.

## Required behavior

- Install shared agent instructions, OpenRouter configuration, rules, and
  reusable workflows from this repository.
- Provide GitHub Copilot repository instructions for VS Code.
- Install shared instructions and skills into the appropriate Codex and
  Copilot user directories while keeping project documentation in the
  repository.
- Install a Copilot custom agent named `getkan-ai` that answers setup,
  workflow, requirement, roadmap, and task-status questions from repository
  markdown files.
- Render the `plan`, `build`, and `reviewer` skills as named subagents for
  GitHub Copilot and OpenCode, enforcing a no-edit boundary on `plan` and
  `reviewer` where the client supports tool permissions.
- Trust the current user's `~/github` directory and every Git worktree
  discovered recursively beneath it on each installation.
- Configure Zsh functions so `codex` and `opencode` load the local OpenRouter
  key from `.env` for the client process without exporting it into the parent
  shell.
- Install and link OpenRouter-backed Codex and OpenCode configurations.
- Synchronize declared Codex marketplaces and plugins with Codex's native CLI
  while preserving undeclared machine-local plugin state.
- Preview installation without changing the target system.
- Preserve existing managed targets in timestamped backups before replacement.
- Keep credentials, sessions, history, caches, and runtime databases outside
  the repository.
- Support repeated installation without replacing already-correct links.
- Provide project-planning templates and separate planning from pull-request
  readiness.
- Use the configured review workflow with validation repeated after each
  actionable fix.
- Maintain one workflow document, `docs/EDITOR_WORKFLOW.md`, covering the
  development lifecycle, the Codex, OpenCode, and VS Code Copilot client
  reference, the `plan`/`build`/`reviewer` loop, a VS Code editor workflow, a
  staged Neovim and tmux migration guide, and sample task workflows.
- Validate repository structure, configuration syntax, skill metadata,
  documentation consistency, and installer behavior.
- Run Linux validation for pull requests and default-branch pushes.

## Architecture

- `agent-config/` is the shared source for Codex and Copilot configuration,
  instructions, and rules.
- The installer renders `config.toml` with machine-specific exact trust entries
  while linking the other managed files.
- The installer generates `~/.copilot/agents/getkan-ai.agent.md` from
  `agent-config/AGENTS.md` and `~/.copilot/agents/control-ai.agent.md` from
  `copilot-config/AGENT_CONTROL.md`.
- `.agents/skills/` contains reusable workflows linked into `AGENTS_HOME`.
- The same `.agents/skills/` directories are linked into `~/.copilot/skills`.
- The `plan`, `build`, and `reviewer` skills are additionally rendered into
  `~/.copilot/agents/<name>.agent.md` and `$OPENCODE_HOME/agent/<name>.md`
  as named subagents.
- `docs/` contains repository-local reference files loaded when needed.
  `docs/EDITOR_WORKFLOW.md` is the single workflow and client reference; it
  replaces the former `WORKFLOW.md`, `CLIENT_WORKFLOW.md`, and
  `CLIENT_REFERENCE.md`.
- `scripts/install.sh` performs user-scoped installation, including managed
  Zsh functions for loading the OpenRouter key and an OpenRouter-backed
  `opencode.json` linked into `OPENCODE_HOME` (default `~/.config/opencode`).
- `scripts/validate.sh` and installer integration tests provide local and CI
  evidence.
- `AGENTS.md`, this specification, `docs/ROADMAP.md`, and `docs/TASKS.md`
  define how the repository is maintained.

## Security and privacy

- Never track authentication files, session history, caches, logs, or runtime
  databases.
- Do not require administrator privileges for normal installation.
- Keep destructive actions narrowly scoped and require explicit authorization.
- Give GitHub Actions the minimum permissions required by each job.
- Pin third-party actions and let Dependabot keep those pins current.

## Compatibility

- The shell installer targets Bash on Linux.
- Optional tools may add validation but must not make ordinary installation
  depend on unrelated developer tooling.

## Non-goals

- Mirroring the complete Codex home directory.
- Managing credentials, plugin caches or authentication, sessions, or caches.
- Routing GitHub Copilot requests through OpenRouter; these are separate
  services.
- Providing one identical runtime for Codex and Copilot; each client retains
  its own discovery and execution behavior.
- Replacing project-specific instructions or requirements.
- Installing Codex, GitHub Copilot, OpenCode, third-party review CLIs, or
  local model servers.
- Adding security scanners that do not support the repository's languages.
- Installing or managing editor configuration such as VS Code settings,
  Neovim plugins, or tmux configuration; the workflow document provides
  samples only.

## Acceptance criteria

- `./scripts/validate.sh` passes from a clean checkout.
- Linux installer integration tests verify dry-run safety, backup
  preservation, machine-local configuration state, correct links, generated
  GitHub trust entries, and idempotence in isolated temporary directories.
- Every skill has valid front matter and the documented skill inventory matches
  the actual directories.
- The pull-request readiness workflow requires a clean Codex review loop and
  does not depend on a third-party review service.
- Pull requests run validation and dependency review on the latest commit.
- Workflow documentation in `docs/EDITOR_WORKFLOW.md` covers planning,
  implementation, review, manual testing, merge gates, client reference,
  editor workflows, and sample task workflows, and `./scripts/validate.sh`
  requires it to exist.

## Unresolved questions

- Whether future installers should add more VS Code-specific automation beyond
  repository instructions.
