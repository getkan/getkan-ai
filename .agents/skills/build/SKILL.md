---
name: build
description: Implement an authorized plan, including feature-specific tests. Use when the user authorizes implementation of a task; generates a plan with the plan subagent first when none exists.
---

# build

## Workflow

1. If no plan exists for the requested work, produce one with the `plan`
   workflow (or invoke the `plan` subagent) before editing anything.
2. Read every file the plan touches, and the nearby callers or consumers,
   before changing it.
   For feature development, read the `ai-project-manager` skill and existing
   SPEC/ROADMAP/TASKS. Establish the selected feature/project ID, its lifecycle
   stage, prerequisite evidence, stage approval, and user-selected session
   tasks before editing. Concurrent entries have independent approvals and
   checkpoints; preserve their state and shared-contract dependencies.
3. Implement one reviewable phase at a time, matching existing project
   patterns, naming, and style instead of introducing a new approach.
4. Add or update feature-specific tests that cover the new behavior. Do not
   rely on unrelated existing coverage to justify skipping tests.
5. Run the smallest relevant validation for the phase (a targeted test,
   lint, or build). For features, obey the stage and task checkpoints below
   rather than automatically moving to the next phase.
6. Keep the diff scoped to the plan and preserve unrelated in-progress
   changes already in the working tree.
7. Before final readiness, run the repository's complete local validation gate.

## Feature-development checkpoints

- Stage 1 resolves requirements and technology choices before scaffolding.
  Reuse an existing SPEC; if absent, investigate the environment and record a
  concise, sourced baseline as defined by `ai-project-manager`.
- Stage 2 creates architecture/contracts, skeletons, deterministic seed data,
  and executable integration tests before detailed business logic. Run tests
  and record expected failures from unimplemented behavior; do not weaken
  assertions. Harness failures and regressions remain blockers.
- Stage 3 implements only user-selected tasks, with unit tests alongside each
  implementation step and focused integration checks. After each validated
  unit, remind the user to commit and stop before the next task. Resume after
  a confirmed commit or explicit instruction to continue without committing;
  never stage or commit implicitly.
- At every stage transition, report evidence, request approval, and stop even
  if future tasks are already listed. Stage approval does not waive task
  commit checkpoints. Do not restart previously completed stages without cause.
- Stage 4 requires feature-wide review against the verified base, including
  committed work and current changes, and passing required validation. Stage 2
  expected failures are not an exception to final readiness. Prepare PR
  evidence without publishing unless explicitly authorized.

## Boundaries

- Do not expand scope beyond the authorized plan without checking with the
  user first.
- Do not delete pre-existing dead code unless the plan calls for it; mention
  it in the summary if it matters.
- Do not commit, push, or open a pull request unless explicitly authorized.

## Output

Report the files changed, the tests added or updated, and the exact
validation commands run with their results.
