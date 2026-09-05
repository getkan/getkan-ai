---
name: ai-project-manager
description: Manage repository planning documents and phased delivery. Use when setting up a repository, creating or updating SPEC.md, ROADMAP.md, or TASKS.md, planning implementation, tracking task status, or preparing validated work for review.
---

# ai-project-manager

Use this skill for repository-level planning and delivery tracking. Keep
project requirements in the repository documents; keep this skill's workflow
generic.

## Choose a mode

- **Setup:** Use when the repository is empty or the user explicitly requests
  project scaffolding and planning documents.
- **Plan:** Use when requirements, milestones, risks, or tasks need to be
  created or clarified without implementation.
- **Implement:** Use when the user authorizes work described by an existing
  plan or task.
- **Handoff:** Use when the user asks to prepare, review, publish, or merge
  completed work. Publishing and merging still require explicit authorization.

## Setup

1. Inspect the repository and its instructions. If it is empty, ask what kind
   of project to create and suggest an appropriate stack. Do not scaffold until
   the user chooses a project type.
2. Scaffold the selected project using its standard tool. For example, for a
   Next.js project run `npm create next-app@latest my-app --yes` before
   customizing it. Adapt the command to the requested project and package
   manager.
3. Create `README.md` and a `docs/` directory. Create only the planning files
   needed by the project: `docs/SPEC.md`, `docs/ROADMAP.md`, and
   `docs/TASKS.md`.
4. Ask for missing product decisions, offering concrete suggestions based on
   the chosen stack and project type. Include concise learning materials for
   the specified technology in `SPEC.md`.
5. Make the planning files internally consistent. When the user provides broad
   goals, expand them into measurable requirements, milestones, and subtasks;
   do not invent product commitments.

## Workflow

1. Inspect `AGENTS.md`, applicable instruction files, current changes, and the
   active branch before reading or changing planning documents.
2. Locate and read the relevant `docs/SPEC.md`, `docs/ROADMAP.md`, and
   `docs/TASKS.md`. Treat them as the source of project requirements and
   workflow state.
3. Identify missing requirements, unresolved decisions, dependencies, risks,
   affected files, and conflicts between documents and code.
4. Define one reviewable phase. Map its tasks to acceptance criteria and state
   automated checks, manual checks, rollback, dependencies, and any approval
   or pause point.
5. If the user requested planning only, present the plan and stop. If an
   unresolved decision materially changes scope, ask the user before editing.
6. When implementation is authorized, execute one phase at a time and keep
   edits limited to that phase.
7. Run the smallest meaningful validation after each phase. Inspect the diff,
   record the checks and results, and update task status only after exit
   criteria pass.
8. For handoff, summarize changed files, validation evidence, skipped checks,
   residual risks, and any required manual review. Do not commit, push, open a
   pull request, publish, or merge unless explicitly authorized.

## Task states

Use these states consistently in `TASKS.md`:

- **Not started:** Defined but no work has begun.
- **In progress:** Work is actively being implemented.
- **Blocked:** Work cannot continue until a named dependency or user decision
  is resolved.
- **Completed:** Acceptance criteria passed and validation evidence is recorded.

Move a task from **Not started** to **In progress** when implementation begins.
Move it to **Blocked** when progress stops, and include the blocker. Move it to
**Completed** only after validation passes; otherwise leave it **In progress**
and record the failing check.

## Diagnostics

```bash
git status --short
git branch --show-current
rg --files -g 'AGENTS.md' -g 'AGENTS.override.md' -g 'docs/SPEC.md' -g 'docs/ROADMAP.md' -g 'docs/TASKS.md'
```

Read every applicable `AGENTS.md` and each planning document relevant to the
task. Planning files live under `docs/`; do not create or rely on root-level
variants. Before editing, also inspect `git diff` so existing user changes are
preserved.

If the user asks to create missing planning files, adapt the templates under
`assets/project-docs/` to the repository. Remove irrelevant sections instead of
leaving placeholders or inventing requirements.

## Safety Rules

- Never rewrite project requirements unless asked.
- Never mark a task done without validation or a stated reason validation was skipped.
- Never ignore conflicts between SPEC, ROADMAP, TASKS, and code.
- Never cross a user approval or plan-only checkpoint.
- Never treat an agent's implementation report as validation evidence.
- Keep project-specific knowledge in project docs, not reusable skills.
- Prefer small reviewable phases over broad plans.

## Validation

For every phase, record:

- The requirements and acceptance criteria it satisfies.
- The automated and manual checks selected before implementation.
- The exact checks run and their results, or the reason a check was skipped.
- The task status change, only after the exit criteria pass.
- The diff scope, including confirmation that unrelated changes were preserved.

In the final report, list changed files, validation evidence, skipped checks,
residual risk, and required manual review.

- For a newly scaffolded project, verify the actual build, lint, and test
  commands available for its stack. Gitignore planning documents only when
  the project policy explicitly calls for local-only planning files.
