# Project instructions

## Purpose

Describe the project, its users, and the outcome it provides.

## Architecture

- List the important directories and components.
- Identify generated files and external interfaces.
- Document the supported toolchain and target environments.

## Working boundaries

- Preserve unrelated changes.
- Do not expose or commit credentials, sessions, private data, or environment
  files.
- Ask before destructive operations, migrations, deployments, or changes that
  require a product or architecture decision.

## Commands

Document the exact setup, formatting, lint, type-check, test, build, and run
commands used by this repository.

## Validation

- Run focused checks while implementing.
- Run the complete required local gate before reporting the feature done.
  Documented expected-red integration tests may satisfy stage 2 skeleton
  criteria only; harness failures and regressions remain blockers.
- Inspect the final status and diff.
- Verify visible behavior with screenshots or equivalent rendered evidence.
- Report skipped checks and unresolved manual testing explicitly.

## Documentation routing

- Use `ai-project-manager` for feature development and its four-stage lifecycle.
  Pause for approval between stages and for a commit reminder after each
  validated implementation unit; continue without a commit only if instructed.
- Read the existing SPEC for requirements, environment baseline, approved design,
  and acceptance criteria. If absent, investigate the codebase and create a
  concise SPEC before scaffolding.
- Read ROADMAP for subprojects, dependencies, lifecycle stage, and approval gates.
- Read TASKS for user-selected session work, tests, evidence, and commit status.

Point these references to the repository's actual document locations when
adapting this template. Preserve existing locations; default new files to
`docs/` unless repository instructions say otherwise.
