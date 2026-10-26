---
name: push-pr
description: Push the current Git branch to its remote, then ask whether to open a pull request when the branch is not named main or master. Use when asked to push changes, publish a branch, or push and open a PR. Do not create commits or force-push.
---

# Push and Pull Request

## Inputs and Outputs

Use the selected repository, current branch, and any supplied remote, upstream,
PR base, or PR requirements. Produce verified push status and, only when
authorized, a verified pull-request URL, or an explicit blocker report.

This skill is independent of `branch`, `review`, and `commit`; it does not run
them automatically or require that they were invoked. Invoking it authorizes
the push, subject to repository confirmation requirements, not PR creation
unless that is explicitly requested. Chain only the steps the user authorizes.

## Procedure

1. Resolve the repository and read applicable instructions. Inspect branch,
   HEAD, upstream, remote configuration, outgoing commits, and worktree status
   without exposing credentials in remote URLs. Stop for detached or unborn
   HEAD. Pending work is not pushed; report it and never stage or commit it.
2. Determine the intended remote and destination from explicit instructions,
   the branch's upstream, and repository conventions. Ask if competing remotes
   or destinations make publication ambiguous. Verify the remote branch state
   and outgoing commits; do not push unrelated branches, tags, or commits
   outside the intended history. Honor required publication checks.
3. Explain the destination and outgoing scope and honor applicable confirmation
   rules. Push only the current branch to the verified destination, establishing
   upstream tracking when appropriate. Never force-push, delete remote refs,
   reset, rebase, merge, or automatically pull to resolve rejection. On failure,
   report the exact blocker and actual local/remote state; do not proceed to PR
   creation as though publication succeeded.
4. Verify the remote branch points to the intended local HEAD and report any
   worktree changes still not published. An already up-to-date branch is a
   successful no-op, not an error.
5. Compare the local branch name exactly with `main` and `master`. On either,
   report push status without offering or creating a PR. On any other branch,
   check for an existing open PR for the verified head repository and branch.
   Report an existing PR rather than creating a duplicate. If none exists,
   ask whether the user wishes to open a PR and stop for the answer, unless
   the user already explicitly authorized PR creation in this request.
   Do not ask again after a decline.
6. When PR creation is authorized, verify the target repository and base branch
   and inspect the complete proposed diff and commits. Do not assume the base
   is `main`; use the requested or verified repository default and clarify
   material ambiguity. Inspect repository PR templates, preserve their
   structure, and supply accurate scope and exact validation commands/results.
   Run required publication gates if evidence is missing or stale. Missing
   required evidence is a PR blocker even if the push already succeeded.
7. Use the repository host's standard tooling (prefer `gh` for GitHub) to create
   a ready-for-review PR unless a draft was explicitly requested. Verify its
   URL, head, base, and state. Do not mark an existing draft ready, edit an
   existing PR, merge, or publish elsewhere without the required authorization.

## Completion Report

Report the pushed branch, remote destination, commit, push result, pending
local changes, and existing or newly created PR URL when applicable. Distinguish
push success from PR failure, refusal, or awaiting approval. Never claim the
whole workflow succeeded when a requested step remains blocked.
