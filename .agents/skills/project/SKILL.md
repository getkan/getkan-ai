---
name: project
description: Start read-only project sessions and guide setup, code research, bug fixes, and four-stage feature development. Use when the user invokes /project or asks to set up, explore, fix, or develop a project.
---

# project

Use this skill for cross-project feature development and delivery tracking.
Keep project-specific requirements in project documents, not this skill.
For fixes and maintenance, use proportionate planning and validation rather
than forcing the full feature lifecycle onto unrelated small changes.

## Begin a project session

Whenever the user invokes `/project`, start with a read-only intake. Do not
execute project code, run builds or tests, install dependencies, create or edit
files, or begin any of the modes below during this first step.

1. Identify the active project root. If it is not clear from the workspace,
   ask the user which project to open.
2. Read the applicable global agent instructions and local instructions,
   including `AGENTS.md` and `CLAUDE.md` at the project root and along the
   relevant path. Follow any instructions they reference.
3. Read existing `SPEC.md`, `ROADMAP.md`, and `TASKS.md` where present, along
   with other project references needed to understand the current state.
4. Use only read-only inspection to note the current branch, worktree changes,
   and relevant existing project context. Preserve all existing changes.
5. Summarize the instructions and project state briefly, then present the
   following four options as a numbered reminder, then ask which one the user
   wants:

   1. Setup project — create or adapt project instructions and planning docs.
   2. Research — explain code flow and responsibilities without changing files.
   3. Feature — follow the four-stage feature lifecycle.
   4. Bug/Issue Fix — investigate and fix a reported defect with focused
      validation.

   Stop here. Even if the initial invocation names a mode, print all four
   options and wait for the user to continue before starting that work.

Do not run the project, tests, or other commands that execute project behavior
during intake. Read-only commands used to inspect instructions and repository
state are allowed.

## Choose a mode

- **Setup project:** Create or adapt `AGENTS.md`, `CLAUDE.md`, `ROADMAP.md`,
  `SPEC.md`, and `TASKS.md` for a new or newly documented project. The user
  may choose the project folder or a separate folder outside the project as
  the destination for these documents. Ask for the exact destination if it is
  not provided. Do not overwrite existing documents; inspect and preserve them,
  and clarify how to handle conflicts before replacing or relocating anything.
  Files stored outside the project are not automatically discovered as local
  agent instructions; explain this limitation and use them as the canonical
  documentation location only if the user chooses it.
- **Research:** Explore a complex codebase to explain its control flow,
  responsibilities, and important relationships. Keep this mode read-only:
  inspect source, tests, and documentation, but do not modify files or execute
  project code. Report findings with file and symbol references, and distinguish
  verified behavior from uncertainty.
- **Feature:** Start a new feature lifecycle by identifying its scope, then
  record a separate, stable roadmap entry when Stage 1 is closed and proceed
  through the four stages below. Keep the feature's requirements, tasks,
  approvals, and evidence distinct from other roadmap entries.
- **Bug/Issue Fix:** Investigate a reported defect by clarifying expected and
  observed behavior, inspecting the relevant code and tests, and establishing
  a reproducible failure where practical. Identify the root cause, add or
  update a focused regression test, make a minimal fix, and run the smallest
  relevant validation. Do not force this work through the feature lifecycle.
  Ask a focused question when expected behavior or reproduction details are
  materially ambiguous; report blockers instead of guessing or claiming a fix.

The user can also request planning, implementation, or handoff within a chosen
mode. Planning is read-only. Implementation requires user authorization, and
publishing or merging always requires explicit authorization.

## Document destinations

Keep existing document locations canonical. When setup targets the project
folder, place `AGENTS.md` and `CLAUDE.md` at the project root unless repository
instructions specify otherwise; preserve existing planning-document locations
and put missing planning documents in `docs/` by default. If the user chooses a
separate folder outside the project, use the exact path they provide for all
five setup documents. Do not create copies in the project as a convenience.
Read and respect instructions at the chosen destination when available, and
explain that external `AGENTS.md` and `CLAUDE.md` files may not be loaded
automatically by tools working in the project.

## Document responsibilities

- **SPEC:** canonical functional and nonfunctional requirements, environmental
  constraints, measurable success, technology and integration decisions, and
  approved high-level design. Reuse the existing codebase's SPEC directly.
  Never copy it into a competing specification.
- **ROADMAP:** ordered delivery outcomes, subprojects, dependencies, risks,
  lifecycle stage, stage exit criteria, approval state, and a concise change
  record. A roadmap delivery stage is not the same as a lifecycle stage.
- **TASKS:** high-level work refined into user-selected session tasks, linked
  requirements and tests, dependencies, blockers, status, validation evidence,
  and the next-task commit checkpoint.

Preserve existing document locations. For missing documents, use `docs/` unless
repository instructions specify otherwise. Keep feature/subproject scope clear
within the canonical documents; split child documents only when complexity
warrants it and link them from the parent. Do not impose a new directory layout.

## Working with project documents

- Reuse an existing SPEC directly. Never copy it into a competing
  specification. Adapt the bundled SPEC template only when no SPEC exists;
  remove irrelevant sections and replace generic prompts with project facts and
  approved decisions.
- Treat bundled SPEC, ROADMAP, and TASKS files as structures to adapt, not as
  the operating procedure. This skill owns the development lifecycle and its
  stage instructions. Preserve project-specific records when updating existing
  documents.
- Keep each feature/project's scope, approval state, blockers, validation, and
  history separate. Use a stable identifier across SPEC, ROADMAP, and TASKS.
- Create or update project instructions from the AGENTS template as needed.
  The CLAUDE template should point to AGENTS.md; keep only Claude-specific
  guidance in CLAUDE.md.

## Concurrent feature lifecycles

Every feature, project, or subproject has its own instance of all four stages.
ROADMAP is a growing collection of these lifecycles, not one global four-stage
sequence. Features may proceed sequentially or concurrently at different stages.

- Give each entry a stable name or identifier shared by SPEC and TASKS. Track
  its stage, status, dependencies, exit evidence, and next-stage approval
  separately. Retain completed entries as history when new features are added.
- Put the ROADMAP index table before the project sections. Give every feature,
  project, or subproject its own level-two heading (`## <project name>`) below
  the table, using its actual name rather than a shared lifecycle heading.
  Nest that entry's stages, completion, risks, and history under level-three
  or deeper headings. Keep a completed setup project and each later feature
  in separate level-two sections; do not combine them under "setup and next
  feature" or nest the next feature inside the completed project.
- Scope requirements/design in SPEC and tasks, test baselines, validation,
  and commit checkpoints in TASKS to that entry. Keep shared requirements
  canonical rather than duplicating them.
- Advancing, approving, blocking, or completing one feature never changes
  another's state or grants approval for it. A stage 2 expected-red baseline
  belongs only to its feature; it cannot excuse regressions in another feature.
- Before acting, identify the user-selected entry and session tasks; clarify
  materially ambiguous scope rather than picking a feature automatically.
  Parallel roadmap entries do not authorize parallel agents or extra work.
- Record cross-feature dependencies and shared schema/interface impacts.
  Preserve unrelated entries when updating shared documents; reconcile
  conflicting edits rather than overwriting another feature's progress.

## Entry and authorization

1. Inspect applicable instructions, the active branch, current changes, relevant
   code, tests, and existing planning documents. Preserve unrelated changes.
2. Identify the selected feature/project entry, its lifecycle stage, evidence of
   completed prerequisites, and approved session scope. Do not repeat completed
   stages unnecessarily; ask about missing decisions or approval evidence.
3. Separate action mode from lifecycle stage. **Plan** mode and the `plan`
   subagent remain read-only: propose document updates or skeletons, never
   create them. Setup/Implement modes may edit only within authorized scope.
4. At every stage exit for that entry, summarize outputs, checks, and blockers;
   record the approval checkpoint when editing is authorized, request approval
   for the next stage, and stop. A broad feature request or list of future
   tasks is not approval to cross a stage boundary.

## Stage 1: Understanding the problem

1. Start with a concise statement of the problem or object as understood.
2. Identify the objectives, ambiguities, and decisions that need the user's
   input. Present them as a concise, numbered list of questions or choices.
3. Discuss the list iteratively: accept quick answers, ask focused follow-ups
   where more clarification is needed, and make room for the user to raise
   questions and state additional decisions. Do not treat the initial list as
   exhaustive or close Stage 1 while the user is still discussing it.
4. Establish functional and nonfunctional requirements, environmental
   constraints, data stores, non-goals, and observable success criteria.
5. For an existing codebase, use its SPEC. If none exists, investigate manifests
   such as `package.json`, Dockerfiles, `.github/workflows`, and relevant source
   and configuration. Record a concise environment baseline in SPEC for future
   requests, citing source paths and distinguishing facts, unknowns, and
   proposed changes. Never inspect secrets or invent deployment details.
6. For a new project, resolve language, framework, datastore, environment, and
   deployment choices with the user before scaffolding. Define any new package
   or service integration, its purpose, constraints, and risks here.
7. For complex projects, identify subprojects as ordered ROADMAP delivery stages
   with dependencies. Repeat this four-stage lifecycle for each subproject,
   preserving parent requirements and integration criteria.
8. Update SPEC and ROADMAP with agreed requirements and decisions. Include
   relevant technology learning resources. Do not invent product commitments.

Close Stage 1 only when the user explicitly says the discussion is complete.
Then summarize the agreed requirements, constraints, success criteria, material
decisions, and unresolved blockers; update SPEC and ROADMAP with agreed outcomes.
Stage 1 closure is not Stage 2 approval: pause separately for the user's Stage 2
approval before proceeding.

## Stage 2: High-level design and implementation

1. Define major components, data flow, table/schema structure, classes, methods,
   interfaces, and end-to-end acceptance criteria in SPEC.
2. Create high-level TASKS linked to requirements, dependencies, and test
   coverage. Update SPEC and ROADMAP as the approved design develops.
3. Scaffold with the stack's standard tool only after stage 1 approval. Create
   structural model files, interfaces, function stubs, and disposable test
   datastore setup as needed. Do not implement full business logic, detailed
   queries, or method behavior reserved for stage 3. Stubs must fail explicitly
   rather than return success-shaped placeholder results.
4. Create deterministic seed data and executable integration tests asserting
   the intended end-to-end behavior before detailed implementation. Run them
   and record the baseline, commands, and exact expected failures associated
   with unimplemented behavior.
5. Expected-red integration tests are acceptable at this stage; never skip,
   disable, or weaken assertions to make skeletons appear complete. Harness
   failures, broken discovery, and unrelated regressions are blockers.

Exit: architecture/contracts, skeletons, seed fixtures, integration tests and
their baseline, and high-level tasks exist. Stage-specific completion does not
mean the feature is complete. Expected failures do not waive repository commit
or CI policy or authorize commits. Pause for stage 3 approval.

## Stage 3: Detailed design and implementation

1. Ask the user to select tasks for the work session unless already selected;
   do not autonomously choose the next major feature from TASKS. Refine selected
   tasks into concrete SQL queries, method behavior, affected files, and checks.
2. Implement one selected, reviewable unit at a time. Write unit tests alongside
   each implementation step and run focused checks, including applicable
   integration coverage. Preserve unrelated changes and inspect the diff.
3. Record results and update SPEC/ROADMAP when implementation changes approved
   design. Update TASKS only when its acceptance criteria pass. Unimplemented
   integration cases remain visible; do not claim the whole feature is done.
4. After each validated unit, remind the user to commit and stop before the
   next task. Resume only after the commit is confirmed or the user explicitly
   instructs you to continue without committing. Never stage or commit
   implicitly, even if several session tasks were selected.

Exit: selected feature scope is implemented and unit/integration checks pass,
with evidence and remaining work recorded. Pause for stage 4 approval.

## Stage 4: Review and pull-request preparation

1. Review the entire feature against its verified base, including committed
   tasks, staged/unstaged changes, and relevant untracked files. A clean
   worktree or `git diff` alone is not a feature-wide review.
2. Check SPEC acceptance coverage, ROADMAP exit criteria, TASKS evidence,
   architecture, regressions, and applicable security/performance/compatibility
   concerns. Run the complete relevant local gate and end-to-end integration
   tests; stage 2 expected failures are not a final-readiness exception.
3. Use `review` for read-only inspection and validation-command discovery;
   the implementing agent runs the checks. Follow required automated review
   gates without launching nested reviews from review mode. Include a
   branch/base review when task commits are outside an uncommitted review.
4. Prepare a PR summary using the repository template when present: changed
   scope, decisions, exact checks and results, manual evidence, skipped checks,
   residual risks, and blockers. Do not report ready while required gates fail.

Exit: feature-wide review and required validation pass, findings are addressed,
and PR evidence is prepared. Stop for handoff. Commit, push, PR creation,
publication, merge, provisioning, and deployment require explicit authorization.

## Task states

Use these states consistently in `TASKS.md`:

- **Not started:** Defined but no work has begun.
- **In progress:** Work is actively being implemented.
- **Blocked:** Work cannot continue until a named dependency or user decision
  is resolved.
- **Completed:** Acceptance criteria passed and validation evidence is recorded.

Move a task from **Not started** to **In progress** when implementation begins.
Move it to **Blocked** when progress stops, and include the blocker. Move it to
**Completed** only after its stage-specific exit criteria pass and evidence is
recorded. The documented stage 2 expected-red baseline is the only test-failure
exception, not a waiver for stage 3 implementation or final readiness; otherwise
leave it **In progress** and record the failing check.

## Diagnostics

```bash
git status --short
git branch --show-current
rg --files -g 'AGENTS.md' -g 'AGENTS.override.md' -g 'SPEC.md' -g 'ROADMAP.md' -g 'TASKS.md'
```

Read every applicable `AGENTS.md` and each planning document relevant to the
task, including existing locations outside `docs/`. Before editing, also inspect
`git diff` so existing user changes are preserved.

If the user asks to create missing planning files, adapt the templates under
`assets/project-docs/` to the repository. Remove irrelevant sections instead of
leaving placeholders or inventing requirements. Replace the ROADMAP template's
generic lifecycle heading with the actual project name. When updating an
existing multi-project roadmap, preserve its table rows, stable IDs, evidence,
approvals, and completed history while applying the same per-project heading
structure; do not restart or merge lifecycles merely to reformat them.

## Safety Rules

- Never rewrite project requirements unless asked.
- Never mark a task done without its stage-specific validation evidence.
- Never ignore conflicts between SPEC, ROADMAP, TASKS, and code.
- Never cross a user approval or plan-only checkpoint.
- Never treat an agent's implementation report as validation evidence.
- Keep project-specific knowledge in project docs, not reusable skills.
- Never treat a stage approval as permission to provision infrastructure,
  migrate production data, deploy, commit, or publish.

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
