---
name: branch
description: Create and switch to a new Git branch while preserving existing staged, unstaged, and untracked changes. Use when asked to branch existing work or move current changes onto a new branch. Do not review, commit, push, or open a pull request.
---

# Branch

## Inputs and Outputs

Use the selected repository, existing changes, and any requested branch name
or starting revision. Produce the new branch name, starting commit, and
confirmation that the worktree and index were preserved, or a blocker report.

This skill is independent of `review`, `commit`, and `push-pr`. Run another
skill only when the user requests it. Invoking this skill authorizes creating
and switching to a new local branch, subject to repository confirmation rules.

## Procedure

1. Resolve the target repository from the user's context, not just the current
   directory. Read applicable instructions. Inspect the current branch or
   detached HEAD, HEAD commit, staged and unstaged diffs, and untracked files.
   Do not read secret files. Record the index and worktree state for comparison.
2. Use the supplied branch name, or derive a concise descriptive name from the
   existing work and repository naming conventions. Ask only if the work's
   purpose or requested starting point is materially ambiguous. Validate the
   name with Git and check for collisions with local and remote-tracking refs.
   Never overwrite, reset, or silently reuse an existing branch.
3. Default to creating the new branch at the current HEAD, retaining existing
   commits and pending changes. If a different base is requested, explain any
   incompatibility with the pending work and stop rather than moving changes
   through a stash, checkout, reset, rebase, or cherry-pick without authorization.
   An unborn repository has no starting commit; report that limitation rather
   than making an initial commit implicitly.
4. Summarize the branch name and starting point, honor any required
   confirmation, and create and switch with a non-forcing Git operation such
   as `git switch -c <name>`. Do not stage, edit, stash, or commit files.
5. Verify the active branch and HEAD and compare the index, tracked changes,
   and untracked-file set with the recorded state. On failure, inspect and
   report the actual resulting state; do not attempt destructive recovery.

## Completion Report

Report the new branch, starting commit, preservation of pending changes, and
any blockers. Do not automatically start a review, commit, push, or PR.
