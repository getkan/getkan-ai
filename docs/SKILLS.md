# Shared skills for Codex and GitHub Copilot

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
installer links this repository's skills into both user locations so the same
workflows are available to Codex and Copilot.

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

- `ai-project-manager`
- `css`
- `js`
- `python`
- `react`
- `svelte`
- `tailwind`
- `ts`
- `vue`

Run `./scripts/validate.sh` after adding or changing a skill. Validation fails
when this list and the skill directories drift apart.
