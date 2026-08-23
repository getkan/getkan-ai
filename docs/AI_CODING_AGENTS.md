# Introduction to AI Coding Agents

AI coding agents are software tools that use language models together with repository access and development tools. They can inspect code, explain behavior, edit files, run commands, write tests, review diffs, and help coordinate a software change.

They are different from ordinary chatbots because they can act on a working tree. They are different from ordinary autocomplete because they can reason across files and carry out multi-step engineering tasks. They are also different from human engineers: they can be fast and broad, but they do not automatically know the project context, the correct business intent, or whether a plausible result is actually correct.

The productive model is supervised collaboration. The human owns the goal, priorities, risk tolerance, and final decision. The agent accelerates investigation and implementation while producing evidence that makes its work reviewable.

## What an AI Coding Agent Can Do

Depending on its tools and permissions, an agent may be able to:

- Search a repository and follow references.
- Read source code, tests, configuration, and documentation.
- Explain errors and unfamiliar architecture.
- Propose a design or phased implementation plan.
- Edit one or more files.
- Run tests, linters, formatters, builds, and diagnostic commands.
- Inspect Git status and diffs.
- Create or update tests and documentation.
- Review changes for defects, regressions, and missing coverage.
- Interact with external systems such as issue trackers or pull requests.

Capability is not the same as authorization. An agent may have a tool that can edit files or run commands, but the task still needs a clear boundary. Keep permissions proportional to the work.

## The Core Operating Model

A dependable agent workflow has four parts:

1. **Context**: Provide the repository rules, relevant files, current behavior, and constraints.
2. **Action**: Let the agent make a focused, reviewable change.
3. **Evidence**: Run checks that can falsify the agent's assumption.
4. **Review**: Inspect the result and decide whether it is ready.

Skipping one of these parts creates predictable problems. Without context, the agent guesses. Without a focused action, it edits too broadly. Without evidence, it reports plausibility as correctness. Without review, subtle regressions reach the branch.

## Start With a Concrete Outcome

Describe the behavior you want, not only the technology involved.

Weak:

```text
Improve authentication.
```

Stronger:

```text
When an expired session is submitted to POST /sessions, return the existing 401 response shape and do not create a new session. Add a regression test for the expired-session path and run the focused authentication tests.
```

A good task states:

- The current problem or desired behavior.
- The relevant entry point, file, symbol, command, or failure.
- Constraints and non-goals.
- Acceptance criteria.
- The validation command or evidence expected.

For large work, ask for a plan first. For small, well-understood work, allow the agent to inspect and implement directly.

## Give the Agent the Right Context

Agents perform better when context is relevant, current, and bounded. Useful context includes:

- Project instructions and contribution rules.
- The specification and acceptance criteria.
- The active roadmap and task status.
- The owning implementation.
- A nearby test or call site.
- The exact error output.
- Compatibility and deployment constraints.

Do not attach the entire repository by default. More context can increase cost, latency, and distraction. Start with the smallest useful surface and expand only when evidence requires it.

A practical context order is:

1. Repository instructions.
2. The named file, symbol, or failing command.
3. The nearest caller, consumer, or test.
4. The specification or documentation that defines the behavior.
5. Broader references only if the local evidence is insufficient.

## Plan Versus Implementation

Planning and implementation are different modes.

A planning request should produce:

- Scope and non-goals.
- A sequence of reviewable steps.
- Dependencies and risks.
- Acceptance criteria.
- Automated validation.
- Manual validation.
- Approval or pause points.

An implementation request should execute the authorized work and validate it. Do not silently turn a plan-only request into code changes. Conversely, do not stop at a proposal when the user explicitly asked for an implementation and the work is safe to perform.

Use a project-management skill when the task involves requirement-linked plans,
phase boundaries, task status, and validation evidence. Keep pull-request
readiness separate from planning so implementation is not mistaken for review
completion.

## Use Small, Reversible Changes

Prefer the smallest change that tests the current hypothesis. Small changes are easier to inspect, revert, and validate.

Good practices include:

- Edit the owning abstraction rather than patching a downstream symptom.
- Preserve existing public APIs unless the requirement calls for a change.
- Avoid unrelated formatting and cleanup.
- Do not introduce a new abstraction until it removes real complexity.
- Keep generated-file changes tied to their source templates.
- Preserve user work in dirty files and unrelated areas.
- Use focused patches rather than rewriting whole modules.

When uncertainty is high, make a reversible probe: add a narrow test, inspect a type, log a decision, or run a small command that distinguishes between competing explanations.

## Verify the Hypothesis

Before editing, state a falsifiable local hypothesis. For example:

```text
The request is failing because the serializer drops the field before validation. A focused test that submits the field and inspects the serialized payload will disprove that theory if the field survives serialization.
```

After the first substantive edit, run the cheapest meaningful check. Good checks include:

- A focused unit or integration test.
- A narrow typecheck or lint command.
- A direct reproduction of the failing behavior.
- A parser or configuration validation.
- A generated-output comparison.

If the check fails, repair the same slice and rerun it before expanding the scope. If the check disproves the hypothesis, move one nearby abstraction boundary toward the code that actually controls the behavior.

## Tests Are Part of the Change

A test should exercise the risk introduced by the change. Do not add a test merely to increase a coverage number.

Useful regression tests specify:

- The setup and relevant inputs.
- The behavior that previously failed or could regress.
- The expected output or side effect.
- Important negative cases.
- The boundary that the test protects.

For configuration and installers, test more than the happy path. Include idempotence, backup preservation, stale targets, missing sources, malformed inputs, and dry-run behavior when those are part of the contract.

A passing test suite does not prove that every requirement is satisfied. Pair automated tests with manual checks for user-facing workflows, generated files, permissions, installation targets, and external integrations.

## Command and Tool Safety

An agent with terminal access can be extremely useful and can also cause damage quickly. Set a command policy appropriate to the repository.

Prefer:

- Read-only inspection before mutation.
- Exact paths and explicit targets.
- Focused file removal rather than broad cleanup.
- Normal Git pushes over history rewriting.
- Backups before replacing managed configuration.
- Dry-run modes for installers and migration scripts.
- Raw command output when exact errors or exit codes matter.
- Filtered output such as `rtk` when logs or test output are large and the filtered result is sufficient.

Require explicit confirmation or a higher review bar for:

- Deleting files or repositories.
- Rewriting Git history.
- Force-pushing.
- Changing production data or infrastructure.
- Modifying SSH or firewall configuration.
- Publishing external messages, releases, or pull requests.
- Handling credentials, tokens, or private data.

Behavioral instructions can tell an agent not to run dangerous commands, but they do not always enforce that restriction. Use native command policies, pre-tool hooks, wrappers, sandboxing, or human approval for deterministic blocking.

## Manage Context and Token Cost

Every instruction and attachment competes for context. A large always-applied prompt can increase token usage and reduce room for code, errors, and user requirements.

Use this hierarchy:

- Keep global instructions short and broadly applicable.
- Use file-scoped instructions for a technology or directory.
- Use skills for repeatable, on-demand workflows.
- Use reference docs for detailed explanations that are loaded only when needed.
- Attach exact error output rather than entire logs when possible.
- Avoid duplicating the same policy in multiple files.
- Regenerate installed files when their source changes.

Keep baseline guidance, reusable workflows, and detailed reference material in
separate locations. An agent may be able to read project documents and use
terminal tools, but a task should still request only the relevant documents.

## Human Review Responsibilities

Human review is not optional because an agent wrote the code. Review the result as an engineering change.

Check:

- Correctness against the stated behavior.
- Security and privacy implications.
- Error handling and failure modes.
- Compatibility with supported environments.
- Data migrations and rollback behavior.
- Performance and resource impact.
- Accessibility and user experience for UI changes.
- Test quality and missing edge cases.
- Documentation and operational follow-up.
- Unrelated changes or accidental generated artifacts.

Read the diff before trusting the summary. The summary describes intent; the diff shows what happened.

## Documentation and Source of Truth

Keep one authoritative source for each kind of knowledge:

- Project maintenance rules belong in the project's instruction file.
- Portable instructions belong in a shared instruction source.
- Requirements belong in a specification.
- Ordered outcomes belong in a roadmap.
- Current work belongs in a task tracker.
- Reusable procedures belong in skills.
- Detailed explanations belong in reference documentation.

When the architecture changes, update implementation, tests, and documentation together. Do not leave old installation paths or obsolete client assumptions in reference material.

## Working With Copilot and Codex

Codex and GitHub Copilot are separate clients. Shared repository content can improve consistency, but it does not erase differences in discovery, tools, models, command policy, or context handling.

For any client:

- Identify its supported instruction, skill, configuration, and rule locations.
- Keep client-specific adapters separate from shared guidance.
- Match the agent's tools to the requested mode and risk level.
- Do not assume that a file is active merely because it exists in a directory;
  verify client discovery behavior.

## Common Failure Modes

### Overconfident implementation

The agent makes a plausible change without proving the behavior. Require a focused check and a clear evidence report.

### Context overload

The agent receives every document and loses the task signal. Narrow the prompt and move detailed material into skills or references.

### Hidden scope expansion

A small fix triggers a cleanup of unrelated files. Review the diff after the first edit and explicitly preserve unrelated changes.

### Tool permission mismatch

The agent is told to run tests but has no execute tool, or it is given edit access for a read-only review. Match tools to the requested mode.

### Stale generated configuration

The source file changed but the installed agent or configuration did not. Rerun the installer and verify the generated output.

### Conflicting instructions

Multiple instruction files state different policies. Define ownership, remove duplication, and keep client-specific adapters separate from shared guidance.

### Unvalidated external action

The agent creates a pull request, changes remote settings, or modifies infrastructure without a review gate. Require explicit authorization and verify the target first.

## A Practical Task Template

Use this template when asking an AI coding agent to perform work:

```text
Outcome:
  Describe the behavior or artifact that should exist when complete.

Context:
  Name the relevant files, symbols, tests, commands, or errors.

Constraints:
  State compatibility, security, performance, scope, and non-goals.

Acceptance:
  List observable conditions that prove the task is complete.

Validation:
  Name the focused check first, then the broader check.

Mode:
  Choose inspect, review, plan, implement, or explain.
```

Example:

```text
Outcome: Add retry handling for one transient API error.
Context: Start at src/client/request.ts and its nearest request tests.
Constraints: Preserve the public API; do not retry authentication failures.
Acceptance: Retry only the documented transient error, preserve error shape,
and add a regression test.
Validation: Run the focused client test, then the full test suite.
Mode: implement.
```

## Final Checklist

Before accepting an AI-assisted change:

- The goal and non-goals were clear.
- The agent inspected the owning code path.
- The implementation is focused and reversible.
- A meaningful check could have disproved the hypothesis and was run.
- Tests cover the changed behavior and important negative paths.
- The diff contains no credentials or unrelated changes.
- Documentation and generated artifacts match the source.
- External or destructive actions were explicitly authorized.
- The final report states what was verified and what remains uncertain.
