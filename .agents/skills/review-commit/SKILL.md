---
name: review-commit
description: Review and validate selected Git changes, then commit them when no user action is required. Use when asked to review and commit, check and commit, or commit after a clean review. Stop for actionable defects, unresolved decisions, failed required checks, or unclear scope; do not push or publish.
---

# Review and Commit

## Inputs and Outputs

Use the user's selected repository and change scope, applicable repository
instructions, and any supplied base revision or commit-message requirements.
When scope is omitted, inspect pending changes and recent task context; ask
only if multiple plausible scopes materially affect what would be committed.

Produce either a verified local commit with its hash, reviewed scope and check
results, or a concise blocker report with the user action needed. Invoking this
workflow authorizes the local commit after review, subject to applicable
confirmation requirements. It does not authorize fixes, history rewriting,
publication, or advancing a project lifecycle stage.

## Procedure

1. Resolve the target repository independently of the current working directory.
   Read its applicable instructions and inspect the branch, recent history,
   staged and unstaged diffs, and relevant untracked files. Establish the exact
   files and hunks selected for the commit. Preserve unrelated changes and
   previously staged work; do not use blanket staging.
2. Determine the review boundary. For a pending-change checkpoint, use the
   current HEAD as the verified base. For a feature-wide review, verify the
   feature's base and include committed changes as well as pending work. If
   nothing in scope is uncommitted, report that there is nothing to commit;
   do not create an empty commit or rewrite an existing one.
3. Review every selected change with enough surrounding source, callers,
   requirements and tests to judge correctness, regressions and acceptance
   coverage. Include relevant untracked files. Distinguish actionable defects
   from verified false positives and optional suggestions. Use required review
   workflows without nesting reviews or assuming a particular agent platform.
4. Discover and run the repository's applicable validation and required
   automated review gates. Start with focused checks and run the required final
   gate. Record exact commands and results. Missing tools, failed checks, and
   required manual evidence are blockers, not passes. A documented Stage 2
   expected-red baseline is acceptable only when repository policy permits
   committing it and every failure matches an explicitly unimplemented
   contract; it never establishes final feature readiness.
5. Decide whether user action is needed. Stop without committing for actionable
   defects, ambiguous scope, unresolved product decisions, unexpected failures,
   incomplete required validation, or missing authorization. Report the
   finding and the smallest decision or correction needed. Do not silently fix
   findings or waive checks. Nonblocking suggestions alone do not require
   another approval.
6. If no user action is needed, summarize the clean review and intended commit,
   then proceed without redundant confirmation unless applicable instructions
   require it. Recheck the diff and status before staging. If the reviewed
   content changed, review and validate the affected changes again. Stage only
   the reviewed scope and inspect the staged diff, including whitespace.
   Ensure the index contains exactly the selected changes; if unrelated staged
   work cannot be preserved while isolating the commit safely, stop and ask.
7. Create one non-interactive local commit with a concise descriptive message
   and any required trailers. Honor hooks; do not bypass a failure, amend, or
   retry blindly. On commit failure, inspect the resulting status and report
   the error without claiming success. Verify the resulting commit's hash,
   contents and remaining worktree status. Report whether unrelated changes
   remain; never claim a clean worktree without checking.

## Completion Report

List the commit hash and subject, reviewed scope, actionable findings, checks
and outcomes, skipped checks with reasons, and residual risks. If blocked,
state explicitly that no commit was created and what the user must resolve.
Do not push, open a pull request, merge, deploy, or start the next task.
