# Getkan AI tasks

## Completed phase: Workflow alignment

- [x] Add project planning documents and reusable planning templates.
- [x] Add a focused pull-request readiness skill.
- [x] Add an isolated Linux installer integration test.
- [x] Add pull-request CI, dependency review, Dependabot, and a PR template.
- [x] Add GitHub Copilot repository instructions and OpenRouter configuration.
- [x] Establish `agent-config/` as the source for Codex/Copilot shared
  instructions and client-specific Codex/OpenCode configuration.
- [x] Install shared skills into Codex and Copilot user directories and render
  selected workflows as OpenCode agents; keep reference docs repository-local.
- [x] Configure Zsh to load the OpenRouter key when Codex or OpenCode runs.
- [x] Trust all Git worktrees beneath the current user's `~/github` directory.
- [x] Run local repository, shell, installer, workflow, and skill validation.
- [x] Confirm installer integration and recursive GitHub trust
  generation passes in CI.
- [x] Inspect the final diff and stage only workflow-alignment changes.
- [x] Install and configure OpenRouter-backed Codex and OpenCode clients.
- [x] Add `plan`, `build`, and `reviewer` skills rendered as named subagents
  for GitHub Copilot and OpenCode.
- [x] Consolidate `WORKFLOW.md`, `CLIENT_WORKFLOW.md`, and
  `CLIENT_REFERENCE.md` into `docs/EDITOR_WORKFLOW.md`, and update
  references in `AGENTS.md`, `README.md`, and `scripts/validate.sh`.
- [x] Document a VS Code workflow, a staged Neovim and tmux migration, and
  sample task workflows in `docs/EDITOR_WORKFLOW.md`.
- [x] Run `./scripts/validate.sh` after the documentation consolidation.
- [x] Commit `docs/EDITOR_WORKFLOW.md` together with the `docs/WORKFLOW.md`
  removal so CI's required-file check passes. Verified in commit `673983f`;
  `docs/EDITOR_WORKFLOW.md` is tracked and `docs/WORKFLOW.md` is absent.

## Current phase: Enforced repository governance

- [ ] Configure a default-branch ruleset after CI check names exist remotely.
- [ ] Require pull requests, successful validation, and conversation resolution.
- [ ] Require an independent approval when repository ownership permits it.

## Completion rule

Move current-phase tasks to completed only after their acceptance criteria and
required validation pass. Keep external GitHub settings pending until verified
through the live repository.
