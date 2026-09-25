# Introduction to Codex

Codex is an AI coding agent. It combines a language model with tools that can inspect a repository, edit files, run commands, review changes, and help move a software task from an idea to a verified result.

Codex is most useful when you treat it as a capable engineering collaborator rather than as an autocomplete box. You provide a goal and the relevant constraints. Codex gathers context, proposes or applies a focused change, runs checks, and reports what it actually verified.

This guide introduces the concepts needed to use Codex safely and effectively.

## What Codex Is

A traditional command-line tool follows explicit instructions. A traditional editor helps you manipulate text. An AI coding agent sits between those models:

- It interprets a natural-language task.
- It searches the repository for the code and documentation that control the behavior.
- It reasons about possible changes.
- It uses tools to inspect and modify the working tree.
- It runs tests, linters, builds, or other checks.
- It summarizes the result, including uncertainty and failed checks.

Codex does not make a change correct merely because the change sounds plausible. A reliable session connects every change to a concrete behavior and finishes with executable evidence.

Codex can work at several levels:

- Explain a file, function, configuration setting, or error.
- Find the code path responsible for a behavior.
- Implement a small fix.
- Add or update tests.
- Refactor a well-understood area.
- Review a diff for defects and missing validation.
- Plan a larger feature in phases.
- Run repository maintenance workflows.

The quality of the result depends on the quality of the task boundary, the context available to the agent, and the checks used to validate the result.

## The Codex Configuration Layers

Codex configuration is easier to reason about when separated into layers.

### Instructions

`AGENTS.md` files provide behavioral instructions. They describe how the agent should work: what to inspect, what to avoid, how to validate, and which documents define requirements.

An installed user-level `AGENTS.md` provides a baseline. A repository may also provide project-specific instructions. More specific project instructions can add local conventions, but they should not silently contradict higher-level requirements.

### Configuration

`config.toml` controls Codex settings. Keep portable defaults separate from machine-specific trust entries, credentials, and runtime state.

Do not place secrets, authentication data, session state, or machine-only runtime settings in the portable source configuration. The installer preserves selected existing runtime sections while generating the managed configuration.

### Provider configuration

The base Codex configuration selects the provider and model for ordinary
sessions. This repository configures OpenRouter there by default.

Keep provider keys in the environment or a local secret store. Never commit credentials or place them in a tracked configuration file.

### Rules

Rules are execution policy. They are different from behavioral instructions:

- Instructions tell the agent what it should do.
- Rules allow, forbid, or constrain command execution.
- Skills provide focused workflows.
- Tests and validation provide evidence that the result works.

Rules may allow common read-only inspection commands and forbid selected destructive operations such as hard resets, broad Git cleanup, repository deletion, and force-push variants.

A rule is not a replacement for judgment. A command can be technically allowed and still be wrong for the task. Inspect the target, explain consequential mutations, and prefer recoverable operations.

## Skills

A skill is a reusable workflow stored in a directory containing `SKILL.md`. Skills should be focused enough that an agent can recognize when they apply.

Skills are commonly stored under a repository or user skill directory. Codex can discover skills from its supported repository and user locations.

A skill normally contains:

- YAML front matter with a name and description.
- A clear purpose and trigger boundary.
- Imperative steps.
- Inputs and expected outputs.
- Validation requirements.
- Optional references, scripts, templates, or UI metadata.

Use a skill when the task needs a repeatable workflow. Do not load every skill into every request. Select the smallest relevant skill set.

For example, a project-management skill is appropriate when the task involves specifications, roadmaps, task tracking, approval checkpoints, or planning evidence. Language skills are appropriate when the implementation requires a particular technology.

## A Reliable Codex Session

A strong session usually follows this sequence:

1. State the desired outcome and constraints.
2. Identify the smallest relevant code or documentation surface.
3. Inspect repository instructions and nearby callers or tests.
4. Form a falsifiable hypothesis about the behavior or failure.
5. Make a focused change.
6. Run the cheapest check that could disprove the hypothesis.
7. Repair or extend the same slice if the check exposes a local defect.
8. Run the relevant broader validation.
9. Review the diff for unintended changes.
10. Report changed files, checks run, skipped checks, and remaining risk.

For a small task, this may take only a few commands. For a large feature, repeat the cycle one phase at a time.

## Writing Better Prompts

A useful Codex prompt includes:

- The outcome, not only the symptom.
- The relevant file, command, symbol, or failing test.
- Constraints such as compatibility, security, performance, or scope.
- The desired action: explain, inspect, review, fix, implement, or plan.
- Acceptance criteria.

Weak prompt:

```text
Make the installer better.
```

Stronger prompt:

```text
Update the request handler so it preserves the existing error shape for one transient failure. Add a regression test and run the focused test before the full validator.
```

You do not need to prescribe every implementation detail. Give Codex enough context to choose a local solution and enough acceptance criteria to verify it.

## Reviewing Codex Output

Treat an agent report as a claim that needs evidence. Check:

- Did the stated files actually change?
- Does the diff match the requested scope?
- Did the relevant test run, or was it only inferred?
- Does the test cover the changed behavior?
- Were existing user changes preserved?
- Are generated files, symlinks, and installation targets correct?
- Are security-sensitive values absent from the diff?
- Does the documentation describe the current behavior?

A passing test is valuable but not complete proof. A test can pass while the wrong file is installed, a user-facing workflow is confusing, or an edge case remains untested.

## Safe Command Use

Prefer inspection before mutation. Useful read-only commands include:

```bash
rg --files
rg -n "pattern" path
sed -n '1,120p' path
 git status --short
 git diff --check
```

Use `rtk` when output is large or repetitive and its filtered result is sufficient. Use the raw command when exact output, quoting, error text, or exit status matters.

Before destructive or externally visible actions, verify the exact target. This includes deleting files, rewriting history, force-pushing, changing remote settings, modifying SSH configuration, or publishing a pull request.

## Common Failure Modes

### The agent guessed instead of inspecting

Fix: provide a concrete anchor and require the agent to read the owning implementation or nearby test first.

### The agent changed too much

Fix: define the intended files and behavior, then review `git diff` immediately after the focused edit.

### The agent reported success without running checks

Fix: require an executable validation command and treat unavailable validation as a blocker.

### Instructions became a giant prompt

Fix: keep always-applied instructions short. Move detailed workflows into skills and on-demand documentation. Broad instructions consume context on requests that do not need them.

### The agent followed a stale instruction

Fix: keep requirements, plans, tasks, implementation, and generated files synchronized. Regenerate installed configuration after changing its source.

## Final Checklist

Before considering a Codex task complete:

- The requested behavior is implemented or clearly explained.
- The change is limited to the intended scope.
- Existing user changes were preserved.
- Relevant tests, validation, or manual checks passed.
- Documentation matches the implementation.
- No credentials or runtime state entered tracked files.
- The final report distinguishes verified facts from assumptions.
