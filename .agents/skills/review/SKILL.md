---
name: review
description: "G-AI: Review staged, unstaged, untracked, or committed branch changes, give actionable feedback and suggested solutions, and identify validation commands. Use for code review, checking changes, or pull-request readiness. Do not implement fixes, branch, commit, push, or open a pull request."
---

# Review

## Inputs and Outputs

Use the selected repository and change scope, applicable instructions, and any
supplied base revision. Produce evidence-backed findings, suggested solutions,
validation requirements, and a readiness assessment. This skill also serves
as the read-only `review` subagent.

This skill is independent of `branch`, `commit`, and `push-pr`. A review does
not authorize fixes or Git mutations, and a clean review does not start the
next skill. Chain steps only when the user explicitly requests them.

## Procedure

1. Resolve the target repository and read its applicable instructions. Inspect
   branch, recent history, staged and unstaged changes, and relevant untracked
   files without reading secrets. Establish the exact scope; ask only if
   multiple plausible boundaries materially affect the review.
2. For pending changes, use the current HEAD as the verified base. For a
   feature-wide review, verify the feature base and inspect committed changes
   against it as well as pending work. A clean worktree is not evidence that
   committed feature work was reviewed. Report when there is nothing in scope.
3. Read every selected change with sufficient surrounding source, callers,
   requirements, and tests to judge correctness, regressions, and acceptance
   coverage. For feature work, consult `project` and relevant SPEC, ROADMAP,
   and TASKS; keep each feature's approvals, baseline, and evidence separate.
4. Identify actionable defects with file/line evidence, impact, the conditions
   that trigger the issue, and a concrete suggested solution. Rank by severity.
   Distinguish verified false positives and optional improvements from blockers.
   Do not silently fix findings or report speculative problems as proven bugs.
5. Discover applicable focused and final validation commands, including lint,
   type-check, build, tests, required manual evidence, and automated review
   gates. Report the exact commands for the caller to execute; this read-only
   workflow does not execute tests or other validation commands. Never launch
   a nested review. A required review command that would nest this review is
   not run; explain the repository's applicable review-mode exception.
6. Assess available check evidence without claiming unrun checks passed.
   Failed required checks, missing evidence, and incomplete acceptance coverage
   are blockers to readiness. A documented Stage 2 expected-red baseline may
   satisfy permitted skeleton-stage criteria, never final feature readiness.

## Completion Report

List the reviewed scope and verified base; findings ranked by severity with
locations, impact, and suggested solutions; verified false positives when
relevant; exact checks already run with results; commands still to run and
manual evidence needed; and remaining risks or blockers. If no actionable
defects were found, say so without implying unperformed validation passed.

Never edit files, stage changes, create branches or commits, push, open a PR,
merge, weaken checks, or advance a project lifecycle stage.
