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
3. Implement one reviewable phase at a time, matching existing project
   patterns, naming, and style instead of introducing a new approach.
4. Add or update feature-specific tests that cover the new behavior. Do not
   rely on unrelated existing coverage to justify skipping tests.
5. Run the smallest relevant validation for the phase (a targeted test,
   lint, or build) before moving to the next phase.
6. Keep the diff scoped to the plan and preserve unrelated in-progress
   changes already in the working tree.
7. After every phase in the plan is implemented, run the repository's
   complete local validation gate.

## Boundaries

- Do not expand scope beyond the authorized plan without checking with the
  user first.
- Do not delete pre-existing dead code unless the plan calls for it; mention
  it in the summary if it matters.
- Do not commit, push, or open a pull request unless explicitly authorized.

## Output

Report the files changed, the tests added or updated, and the exact
validation commands run with their results.
