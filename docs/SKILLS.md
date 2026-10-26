# Shared skills for Codex, GitHub Copilot, and OpenCode

## Purpose

A skill is a reusable workflow with focused instructions, optional references,
and optional scripts.

Use a skill for knowledge that is:

- reused across repositories
- independent of one project's requirements
- specific enough to have a reliable trigger
- too detailed for global or repository instructions

## Discovery locations

Use the current documented location:

```text
repository/.agents/skills/<skill-name>/SKILL.md
~/.agents/skills/<skill-name>/SKILL.md
~/.copilot/skills/<skill-name>/SKILL.md
```

Codex scans repository skill directories from the working directory up to the
repository root and uses `~/.agents/skills/` for user-wide skills. The
installer links this repository's skills into the Codex and Copilot user
locations. It renders the `ask`, `plan`, `build`, and `reviewer` workflows as
named OpenCode agents using their configured permissions.

## Required layout

```text
.agents/skills/skill-name/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
└── scripts/
```

Only `SKILL.md` is required. It must start with YAML front matter containing a
clear `name` and `description`.

## Authoring rules

- Keep each skill focused on one workflow.
- Put trigger terms and boundaries in the description.
- Write imperative steps with explicit inputs, outputs, and validation.
- Load references only when the task needs them.
- Prefer instructions over scripts unless deterministic automation is useful.
- Keep project requirements in project documentation, not reusable skills.
- Use `agents/openai.yaml` only for useful UI metadata or dependencies.

## Repository skills

- `project`
- `ask`
- `build`
- `create-skill`
- `css`
- `deep`
- `js`
- `learn`
- `md-to-pdf`
- `plan`
- `playwrite`
- `python`
- `react`
- `reformat`
- `review-commit`
- `reviewer`
- `svelte`
- `take-note`
- `tailwind`
- `ts`
- `vue`
- `watch`

Run `./scripts/validate.sh` after adding or changing a skill. Validation fails
when this list and the skill directories drift apart.

The `reformat` skill normalizes pasted or dictated text into clean Markdown
without changing its words, punctuation, links, code, or meaning.

The `review-commit` skill reviews and validates selected changes, then creates
a local commit when no user action is needed. It stops for actionable defects,
unclear scope, unresolved decisions, or failed required checks, preserves
unrelated work, and does not push or publish.

The `md-to-pdf` skill uses its bundled Pandoc/Chromium converter to export one
Markdown file or combine ordered Markdown chapters into a printable PDF,
resolving each input's relative images and preserving rendered content.

The `watch` skill runs a local development watch command in a dedicated
background terminal, restarts it up to three times on process failure, and
leaves reported errors alone until the user asks for a specific fix.

The `project` skill owns the cross-project feature lifecycle:
understand the problem; design and scaffold with seed data and integration
tests; implement user-selected tasks with unit tests; review the whole feature
and prepare PR evidence. Pause for approval between stages and for a commit
reminder after each validated implementation unit. Reuse an existing SPEC;
when missing, investigate and record a concise environment baseline. Expected-red
tests are acceptable only for the stage 2 skeleton baseline, not final readiness.
Its bundled SPEC, ROADMAP, TASKS, and AGENTS files are structures to adapt.
The skill owns the operating procedure, while existing project document
locations and requirements remain canonical.
Each feature/project has its own four-stage lifecycle. ROADMAP tracks multiple
entries over time, including concurrent entries at different stages, with
independent approvals and evidence linked by feature/project ID across SPEC
and TASKS. Completing one entry does not advance the others.

## Subagents: ask, plan, build, reviewer

`ask`, `plan`, `build`, and `reviewer` are skills that also render as named
subagents. The installer renders each one into a client-specific custom
agent in addition to linking it as an ordinary skill:

- `ask`: answers questions thoroughly after gathering the necessary context.
  It is read-only and cannot make repository, system, or service changes.
- `plan`: read-only investigation and phased planning. Never edits a file.
- `build`: implements an authorized plan, including feature-specific tests.
  Can call the `plan` subagent when no plan exists yet. Feature work respects
  the project-manager lifecycle and task/commit checkpoints.
- `reviewer`: reviews the whole feature/base diff plus current changes and
  reports the complete validation commands for the parent to run. Never
  edits files or executes commands.

The installer renders these into `~/.copilot/agents/<name>.agent.md` and
`$OPENCODE_HOME/agent/<name>.md` (default `~/.config/opencode/agent/`) using
each subagent's mode and tool permissions from
`agent-config/subagents/<name>.config.json`, not from `scripts/install.sh`.
`ask` is limited to read/search tools in Copilot and denies mutation, shell,
and delegation tools in OpenCode. `plan` and `reviewer` deny `edit` (and, for
OpenCode, `task`, which also denies calling other subagents). Codex has no
native per-agent tool-permission mechanism, so Codex sessions rely on the
skill's own instructions to honor the same boundary.
