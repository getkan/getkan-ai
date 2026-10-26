---
name: commit
description: Create a local Git commit for selected changes with a concise descriptive message. Use when asked to commit or save changes in Git. Preserve unrelated staged and unstaged work, honor required checks and hooks, and do not automatically review, branch, push, or open a pull request.
---

# Commit

## Inputs and Outputs

Use the selected repository, files or hunks, and any supplied message or commit
conventions. Produce one verified local commit with its hash, subject, scope,
check results, and remaining worktree state, or an explicit blocker report.

This skill is independent of `branch`, `review`, and `push-pr`. It does not
require a prior invocation of those skills or launch them automatically.
Invoking it authorizes the local commit, subject to repository requirements.
It does not authorize fixes, history rewriting, or publication.

## Procedure

1. Resolve the target repository and read applicable instructions. Inspect
   branch, recent commit conventions, staged and unstaged diffs, and relevant
   untracked files. Never read or stage secrets. Honor explicit file/hunk
   selection. With no selection, prefer the existing staged scope; otherwise
   infer a single coherent pending change from the task context. Ask when
   competing scopes materially affect what would be committed.
2. Establish the exact intended content. Reading the diff is necessary to
   choose scope and describe it, not a substitute for a requested code review.
   Do not make review a new mandatory phase, but stop for known actionable
   defects, unresolved decisions, unsafe scope, or failed required checks.
   If nothing selected is uncommitted, report that there is nothing to commit;
   never create an empty commit or amend an existing commit implicitly.
3. Discover and run the repository's required pre-commit checks and honor
   existing validation evidence only if it covers the unchanged selected
   content. Missing tools, unexpected failures, missing required review or
   manual evidence, and hook failures are blockers. Do not waive policy,
   silently fix files, or weaken checks. Distinguish documented expected-red
   baselines only where the repository explicitly permits committing them.
4. Draft a concise imperative subject describing the actual change, following
   repository conventions and any supplied wording. Add a body only when useful
   for rationale or important context; include all required trailers.
5. Summarize the intended scope and message. Honor required confirmation, then
   recheck status and diff for concurrent changes. Stage only selected paths
   or hunks, never blanket-stage the repository. Inspect the staged diff and
   whitespace, ensuring it contains exactly the intended commit. Preserve
   unrelated staged work; if it cannot be safely isolated, stop and ask.
6. Create one non-interactive local commit. Honor hooks; do not bypass them,
   amend, force, or retry blindly. If the commit fails, inspect status and
   report the error and any hook modifications without claiming success.
7. Verify the new commit's hash, message, and contents against the selected
   scope. Inspect the remaining staged, unstaged, and untracked changes.

## Completion Report

Report the commit hash and subject, committed scope, checks and outcomes,
skipped checks with reasons, and remaining changes. If blocked, explicitly
state that no commit was created and what must be resolved. Do not push,
open a PR, or start another skill unless requested.
