# Getkan AI tasks

## Current status

Stable. No active phase, selected session tasks, planned features, or pending
feature approvals. Do not choose new work from historical proposals.

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

## Completed: Cross-project feature-development workflow

- [x] Define SPEC/ROADMAP/TASKS responsibilities and the four-stage lifecycle.
- [x] Require stage approval pauses, user-selected implementation tasks, unit
  tests alongside implementation, and per-unit commit reminders.
- [x] Define skeletons, seed fixtures, and executable integration tests before
  detailed implementation, with documented expected failures at stage 2 only.
- [x] Align plan/build/reviewer, reusable templates, and workflow references.
- [x] Add lifecycle/template checks and generated-agent body comparisons.

Evidence: commit `69908de`. `./scripts/validate.sh` passed, including installer
integration tests and 20 skill checks; Bash syntax, ShellCheck, and
`git diff --check` passed during implementation. The repeated Codex review
reported no actionable findings. The subsequent code review's document-location
finding was corrected before the commit. These are historical results for that
change, not a new verification of remote GitHub settings or live installation.

## Inactive historical proposals

Default-branch rulesets, required PR/check/conversation gates, independent
approval settings, and local-model token optimization are not current tasks.
Their removal from the active queue does not certify completion. Any resumption
requires an explicit request and verification of the current state.

## Completion rule

Create active tasks only for explicitly requested work. Move them to completed
only after their stage-specific acceptance criteria and required validation are
recorded. Never mark external GitHub settings complete without live verification.
