# Repository instructions

## Scope

This repository is the source of truth for Getkan's portable Codex
configuration, reusable skills, and durable coding-agent instructions. The root
`AGENTS.md` is the project maintenance file for this repository. The
portable client instructions shared by Codex and Copilot are stored in
`agent-config/AGENTS.md`; its Claude Code counterpart is
`agent-config/CLAUDE.md`.

## Operating principles

- Working code only. Plausibility is not correctness; verify before reporting
  done.
- Never fabricate file paths, APIs, commit hashes, command output, or test
  results. Read the file, run the command, or say what is unknown.
- Say when a premise appears wrong before implementing around it.
- Ask before proceeding only when a request has multiple plausible
  interpretations and the choice materially affects the result.
- Touch only what the task requires. Avoid drive-by refactors, formatting, or
  cleanup.
- Keep communication direct and concise. Skip flattery, filler, ceremonial
  openings, and emoji.

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

## Command execution

- Prefer running code, tests, linters, and type checks over guessing.
- Read complete errors, logs, and stack traces before fixing them.

## Before editing

- State the plan or success criteria before editing. For non-trivial work,
  include the verification you expect to run.
- Read the files you will touch and the nearby callers, consumers, or docs that
  define their behavior.
- Match existing project patterns, naming, layout, and style even if a different
  approach would be appealing in a new project.
- Resolve ambiguity by reading code or running commands when practical; surface
  assumptions out loud when they affect the result.

## Editing

- Keep credentials, tokens, sessions, history, caches, logs, and runtime
  databases out of this repository.
- Put reusable workflows in `.agents/skills/<name>/SKILL.md`.
- Put portable shared agent configuration in `agent-config/`.
- Put project maintenance instructions in this file.
- Do not assume files in `docs/` are loaded automatically.
- Use the minimum code or documentation change that solves the stated problem.
- Do not add speculative features, abstractions, configurability, or hooks.
- Do clean up orphans created by your own change, such as unused imports or
  obsolete helper functions.
- Do not delete pre-existing dead code unless asked; mention it in the summary
  if it matters.

## Documentation routing

Read only the documents needed for the task:

- `docs/SPEC.md` for product requirements, boundaries, acceptance criteria, and
  resources for learning more about technologies utilized in the project, when
  present in the workspace.
- `docs/ROADMAP.md` for ordered outcomes, risks, phase exit criteria, and a log
  of changes over time, when present in the workspace.
- `docs/TASKS.md` for the current phase, validation status, and remaining work,
  when present in the workspace.
- `docs/AI_LAYOUT.md` for agent discovery and installation boundaries.
- `docs/SKILLS.md` when creating or changing skills.
- `docs/EDITOR_WORKFLOW.md` for the development lifecycle, Codex, OpenCode,
  and VS Code Copilot client reference, the `plan`/`build`/`reviewer` loop,
  the VS Code and Neovim/tmux editor workflow, and sample task workflows.
- `docs/LOCAL_MODEL_INTEGRATION.md` when working on local model token
  optimization.

## Verification

- Run the smallest meaningful verification during iteration and the requested
  or relevant final verification before reporting done.
- During implementation, prefer focused checks first (for example a targeted
  test or lint scope) to keep iteration fast.
- If verification fails, fix the cause instead of weakening the check.
- For UI or visual changes, verify visually with screenshots or equivalent
  rendered output.
- Run `./scripts/validate.sh` before commit or pull-request creation when
  changing configuration, skills, install scripts, or repository layout.
- Run `./scripts/test-install.sh` directly when diagnosing installer behavior.
- After the complete local gate passes for a non-trivial change, review the
  uncommitted changes. Verify every finding against the current diff, fix only
  actionable defects, rerun affected validation, and repeat the review until no
  actionable findings remain.
- When the active task is itself a code review, inspect the changes and report
  findings directly. Never start a nested review from review mode.
- Treat an unavailable or failed review as an explicit readiness blocker. Do not
  silently substitute a third-party review CLI.

## Maintenance

- Keep this file short enough to follow. Add rules only when they prevent a real
  repeat mistake or document durable project behavior.
- Route corrections to the narrowest durable scope: cross-repository behavior
  belongs in `agent-config/AGENTS.md`, reusable workflows belong in a skill, and
  project-specific behavior belongs in this file or its specification. Do not
  duplicate the same rule across scopes.
- When the user corrects an approach, tighten the relevant rule instead of
  appending a vague warning.
