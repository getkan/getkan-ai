# Project instructions

## Global coding standards

1. **YAGNI:** Don't build functionality until it is needed.
2. **DRY:** Extract a shared pattern after it appears a second time; avoid
   premature abstraction.
3. **Fail fast:** Prefer explicit errors over silent failures.
4. **Keep it simple:** Start with the obvious solution; optimize only when
   needed.
5. **Delete thoughtfully:** Remove unnecessary code when it is safe to do so;
   less code generally means fewer opportunities for bugs.
6. **Use descriptive names:** Choose clear, self-documenting names for
   variables, parameters, and API endpoints. Prefer names that make intent easy
   for people and language models to understand, without adding needless
   verbosity. For example, use `wait_until_observation_is_saved` rather than
   `wait`.

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
- Inspect the final status and diff.
- Verify visible behavior with screenshots or equivalent rendered evidence.
- Report skipped checks and unresolved manual testing explicitly.

## Documentation routing

- Use `project` for the feature-development lifecycle and its
  approval and task checkpoints.
- Use SPEC for requirements, approved design, and acceptance criteria;
  ROADMAP for outcomes, dependencies, lifecycle status, and approvals; and
  TASKS for selected work, tests, and validation evidence.

Point these references to the repository's actual document locations when
adapting this template. Preserve existing locations; default new files to
`docs/` unless repository instructions say otherwise.
