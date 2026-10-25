# Project tasks

## Current scope and session

- Feature/subproject and ROADMAP outcome:
- Current lifecycle stage and approval evidence:
- Tasks selected by the user for this session:
- Next stage approval required:

## High-level tasks

Define major features in stage 2, linked to SPEC acceptance criteria and
dependencies. Refine only user-selected work into detailed session tasks.

## Session task

- Reviewable outcome and scope:
- State: Not started / In progress / Blocked / Completed.
- SPEC requirements and acceptance criteria:
- Detailed design: SQL queries, methods, affected files, and implementation steps.
- Unit tests written alongside implementation:
- Integration tests and deterministic seed fixtures:
- Automated/manual validation: exact commands, results, and evidence.
- Dependencies or blockers:

## Stage 2 integration baseline

Record executed test commands, intended behavior, and precise expected failures
from unimplemented stubs. Do not skip or weaken tests to obtain a green result.
Harness/setup failures, broken discovery, and unrelated regressions are blockers.
Expected-red tests may satisfy stage 2 criteria, not implementation or final
feature readiness. Do not bypass repository commit or CI policy.

## Commit checkpoint

After each validated unit, remind the user to commit and stop before starting
the next task. Record the confirmed commit or explicit instruction to continue
without committing. Task selection alone does not authorize continuation, staging,
or committing.

## Completed

Move tasks here only after their stage-specific acceptance criteria pass and
validation evidence is recorded. Stage 2 may complete with its documented
expected-red integration baseline; the feature is not complete until required
final checks pass. Record skipped checks, blockers, and residual risk explicitly.
