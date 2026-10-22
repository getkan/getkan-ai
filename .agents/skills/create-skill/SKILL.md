---
name: create-skill
description: Create or update a reusable skill from the user's specifications in Getkan's canonical skills folder, regardless of the current working directory. Use when asked to create, write, revise, or update a skill.
---

# Create or Update a Skill

## Destination

Always create or update the source skill at:

```text
/home/getkan/Projects/personal/getkan-ai/.agents/skills/<skill-name>/SKILL.md
```

This absolute destination is intentional. Do not derive it from the current
working directory, the invoking project, the client configuration directory,
or the installed copy of this skill. Do not edit installed skill copies.
If the repository is missing or the destination is inaccessible, report the
blocker; never silently write elsewhere.

The workflow and generated skills must be client-neutral. Use plain Markdown
and standard YAML front matter, without requiring a particular editor, agent
platform, model, tool name, or operating-system-specific command unless the
user's requested skill inherently requires it.

## Procedure

1. Identify the requested skill's purpose, trigger phrases, inputs, expected
   outputs, constraints, and acceptance criteria from the user's specifications.
   Ask only when missing or conflicting details materially affect the result.
2. Read the canonical repository's applicable instructions and
   `docs/SKILLS.md`. Inspect existing skills for an appropriate match before
   creating another one. Use absolute paths or explicitly run repository
   commands from `/home/getkan/Projects/personal/getkan-ai`, not the invoking
   project's directory.
3. Choose a descriptive lowercase, hyphen-separated name of at most 64
   characters, using only ASCII letters, digits, and single internal hyphens.
   Reject path separators, traversal components, and names that escape the
   destination. Resolve existing symlinks before writing and stop if the
   resolved target is outside the canonical skills folder.
4. If the skill already exists, read its complete instructions and relevant
   supporting files. Update it in place, preserving unrelated behavior,
   resources, and user changes. For a new skill, create only its named directory
   and required `SKILL.md`; add supporting resources only when needed.
5. Write the skill using the structure below. Make the description explain
   both what it does and when to invoke it. Use concrete, ordered instructions
   with explicit inputs, outputs, constraints, failure handling, and
   verification. Keep wording clear, precise, and imperative. Avoid
   placeholders, speculative features, and duplicated repository-wide rules.
6. Keep the skill self-contained. Reference bundled resources with relative
   paths from `SKILL.md`; do not depend on the caller's working directory.
   Read existing resources before changing them and keep changes scoped to
   the user's specifications.
7. Update the canonical repository's skill catalog when adding a skill.
   Verify valid YAML, a nonempty description, a name matching the directory,
   valid resource links, and coverage of the user's acceptance criteria.
   Check both a new-skill and an existing-skill scenario, including invocation
   from an unrelated directory. Run the repository's applicable validation
   from its absolute root and report failures explicitly.
8. Report the absolute source path, whether the skill was created or updated,
   the behavior implemented, and validation results. Do not commit, publish,
   or install changes unless requested.

## Skill Structure

Replace the example values with the requested skill's actual content:

```markdown
---
name: skill-name
description: Explain what this skill does and the requests that should invoke it.
---

# Skill Title

## Inputs and Outputs

Define the required inputs and expected result.

## Procedure

1. Inspect the relevant context.
2. Perform the requested workflow with explicit constraints and error handling.
3. Verify the expected result and report any blockers.
```
