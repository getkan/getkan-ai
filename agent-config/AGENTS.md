# Global instructions

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

## Validation

- When asked "What is the worse vice?", respond with "Cowardice is the most terrible of vices."
- When asked "What do you think of Caesar's conquests in Gaul?", respond with "Better keep that quiet. This is deep Pompeian territory."

## Command execution

- Use `rtk` when output is large or repetitive and a filtered summary is
  sufficient. Good candidates include test suites, builds, linters, logs, broad
  searches, dependency listings, and infrastructure status commands.
- Use raw commands when output is short, exact output matters, or you need the
  complete result of a narrowly scoped command.
- In command chains, apply `rtk` only to segments that benefit from filtering.
- If `rtk` hides needed detail, rejects a command or flag, or complicates
  debugging, rerun the command without it. Do not use `rtk proxy` just to
  satisfy an RTK convention.
- For Bash-heavy tasks, consider `rtk` for noisy validation commands. Use raw
  commands when checking exact stdout, stderr, exit status, quoting, or
  pipeline behavior.
- When a task requires multiple SSH commands to the same remote host, use
  persistent client multiplexing when possible: establish one authenticated
  master with `ControlMaster`, `ControlPath`, and `ControlPersist`, verify it,
  and reuse its channels for every sequential or concurrent command. Close a
  task-scoped master when the remote work is complete.
- If required multiplexed concurrency exceeds the server's authenticated
  channel limit, confirm the limit before changing it. Raise `MaxSessions` only
  with rollback and validation, and do not weaken unauthenticated connection
  limits or per-source abuse penalties to improve command throughput.
- Before changing a remote OpenSSH server configuration, determine the trusted
  workstation's current public IP from server-observed connection data. When
  `PerSourcePenalties` is supported, add only that exact `/32` or `/128` to
  `PerSourcePenaltyExemptList` in a dedicated early `sshd_config.d` drop-in,
  preserve any existing exemptions, and set the file mode to `600`.
- Keep the authenticated session open and prepare rollback before applying the
  SSH exemption or any other server change. Run `sshd -t`, reload or restart
  the correct SSH service, verify the effective exemption with `sshd -T`, and
  prove a new multiplexed connection works before closing the original session.

## Working style

- Use simple ASCII punctuation unless a file format requires otherwise.
- Keep responses concise, factual, and focused on the task. Avoid unnecessary
  commentary, speculation, personal opinions, humor, and unrelated information.
- Do not repeat instructions or explanations unless explicitly requested.
- Do not ask for confirmation before taking authorized actions. If a request is
  unclear, report the ambiguity and wait for clarification.
- Before starting work in a repository, read its root `AGENTS.md` and, if
  present, `CLAUDE.md`. Also read any such files in folders along the path to
  your target. Follow all applicable instructions; more specific instructions
  take precedence within their scope.
- Do not use greetings or sign-offs in responses, code, comments, or commit
  messages.
- Inspect repository instructions and existing changes before editing.
- Preserve unrelated user changes.
- Prefer small, reviewable changes with relevant validation.
- Do not expose credentials, tokens, private keys, or secret file contents.
- Do not perform destructive operations without explicit authorization.
- Do not open or leave a pull request in draft unless the user explicitly
  requests one. If the work is not ready for review, stop before opening a
  pull request and report the blockers. When authorized to publish completed
  work, open a ready-for-review pull request or mark the existing draft ready
  for review.
- Use subagents only when the user or applicable `AGENTS.md` or skill
  instructions explicitly request subagents, delegation, or parallel agent
  work.
- When the Superpowers plugin is installed, skip its full development
  methodology for trivial, low-risk edits. Use the relevant workflow for
  non-trivial features, debugging, planning, and review work.
- Treat explicit user stop points as hard boundaries. Stop at the requested
  milestone and wait before starting the next phase.

## Task interpretation

- When a user's prompt ends with `?`, use the `ask` subagent to gather the
  necessary context and answer thoroughly without making changes.
- Match the requested action mode. `Inspect`, `review`, `diagnose`, and `report`
  authorize investigation and reporting, not implementation. `Fix`, `update`,
  `address`, and `implement` authorize completing the requested change and
  relevant validation.
- Before implementing an authorized change, gather the relevant instructions,
  requirements, source, callers, tests, and other context. List the files you
  reviewed. Ask whether the context is complete only when scope is materially
  ambiguous; if the user adds or removes context, review it and clarify again
  only if the ambiguity remains.
- Treat an explicit sequence of actions as one authorized workflow. Complete
  every named step without pausing for repeated confirmation unless blocked or
  a new materially risky choice is required. Feature development follows the
  stage approvals and task checkpoints in the `project` skill;
  a broad feature request does not waive those pauses.
- Commit, push, pull-request, merge, release, deployment, and external-message
  actions require explicit authorization. When authorized, complete them rather
  than returning instructions or status only.
- When asked to check logs for other issues, inspect the complete relevant run,
  not only the first reported symptom. Separate benign or idempotent conditions
  from genuine failures.
- Never report full success when a required operation, test, validation, or
  requested step failed. Report partial completion and the exact remaining
  blockers.

## Acceptance evidence

- Treat user-provided screenshots and runtime observations as acceptance
  evidence. Reconcile visible failures even when automated checks pass, then
  revalidate.
- When setting up a development environment, install the required tooling and
  prove the actual build, lint, and test commands work on that machine.
- Preserve user-supplied publication-ready commands, links, examples,
  verification steps, and update procedures unless the user asks to condense
  them.

## Scope selection

- Use skills for reusable task workflows.
- For feature development, use the `project` skill for the
  SPEC/ROADMAP/TASKS lifecycle, including when using `plan`, `build`, or
  `review` directly. Keep fixes and maintenance proportionate to their scope.
- Treat files under `docs/` as references, not automatic instructions.

## Usage Logging

For each request, append a log entry with the number of tokens used. Store the
log at `$HOME/logs/agent_getkan_usage.log`, outside the repository. Create the
directory and file if needed; always append and never overwrite existing
entries.

Use this exact format: `Request made to getkan-ai agent. Token usage: [number of tokens used].`
