---
name: skill
description: Create or update reusable skills in Getkan's canonical skills folder, or record a narrow durable learning directive in portable agent instructions or a skill. Use when asked to create, write, revise, update, or learn an agent instruction or skill.
---

# Create, Update, or Learn a Skill

## Inputs and Outputs

Use the user's skill specification or requested learning directive, target
skill/instruction file when supplied, and the canonical Getkan AI repository.
Create or update one canonical skill, or make a narrow durable instruction
change in an authorized target. Report the absolute source path, the operation
performed, and validation results.

## Boundaries

- Store skill source files only under
  `/home/getkan/Projects/personal/getkan-ai/.agents/skills/<skill-name>/SKILL.md`.
  Do not derive the canonical destination from the current working directory,
  edit installed copies, or silently write elsewhere.
- Learning changes may modify only `agent-config/AGENTS.md`,
  `agent-config/CLAUDE.md`, or a skill file under `.agents/skills/`. Keep the
  portable instruction files aligned when changing shared global behavior.
- Do not make code changes based on a learning directive. Keep edits narrow;
  preserve unrelated instructions, commands, safety rules, and workflows.
- Use client-neutral plain Markdown and standard YAML front matter for skills.
  Do not add platform-specific requirements unless inherent to the requested
  workflow.

## Procedure

1. Choose the operation from the user's request:

   - **Create or update a skill:** use when asked to create, write, revise, or
     update a reusable skill.
   - **Record a learning directive:** use when asked to remember a new
     instruction or behavior durably for future sessions.

   Ask only if missing or conflicting details materially affect the target or
   behavior. For an ambiguous learning directive, ask for the precise rule
   wording before editing.

2. Read the canonical repository's `AGENTS.md` and `docs/SKILLS.md`, then
   inspect relevant existing skills and target files. Use absolute repository
   paths or run commands from `/home/getkan/Projects/personal/getkan-ai`.
   Resolve a requested skill name as lowercase ASCII letters, digits, and
   single internal hyphens, at most 64 characters. Reject separators,
   traversal, invalid names, and resolved paths outside `.agents/skills/`.

3. Apply only the selected operation:

   ### Create or update a skill

   - Identify the skill's purpose, trigger phrases, inputs, outputs,
     constraints, and acceptance criteria from the user's request. Reuse or
     update an existing skill when it is an appropriate match.
   - Write the source to the canonical skill path. For an existing skill, read
     its complete instructions and relevant resources; preserve unrelated
     behavior and user changes. For a new skill, create only its named
     directory and required `SKILL.md`; add supporting files only when needed.
   - Include valid YAML front matter with a directory-matching `name` and a
     nonempty `description` explaining what the skill does and when to invoke
     it. Give concrete ordered instructions with inputs, outputs, constraints,
     failure handling, and verification. Avoid placeholders, speculative
     features, and duplicated repository-wide rules.
   - Keep the skill self-contained. Reference bundled resources with paths
     relative to `SKILL.md`, and read existing resources before changing them.
   - Update `docs/SKILLS.md` when adding or removing a skill; do not alter the
     catalog for edits to an existing skill.

   ### Record a learning directive

   - Read the target before changing it. Choose `agent-config/AGENTS.md` for
     portable global behavior, `agent-config/CLAUDE.md` for its corresponding
     Claude Code instructions, or the relevant skill file for a reusable
     workflow rule.
   - Add only the specific durable rule requested. Prefer one focused bullet or
     small section, avoid duplicating existing guidance, and preserve the
     established command-execution, safety, workflow, and validation rules.
   - When changing shared global behavior, keep `agent-config/AGENTS.md` and
     `agent-config/CLAUDE.md` aligned. Do not change other files unless the
     requested directive requires that authorized target.

4. Verify the outcome. For a skill, check YAML front matter, matching name,
   nonempty description, valid resource links, and coverage of the request.
   For a learning directive, confirm the rule is present and existing
   instructions remain intact. Check both create-new and update-existing
   skill scenarios where applicable, including invocation from an unrelated
   directory. Run `/home/getkan/Projects/personal/getkan-ai/scripts/validate.sh`
   after creating or changing a skill.

5. Report the absolute source path, whether the skill was created or updated
   or which learning directive target changed, the behavior implemented, and
   validation results. State failures explicitly. Do not commit, publish, or
   install changes unless requested.
