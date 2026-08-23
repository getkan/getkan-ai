---
name: learn
description: Update the portable agent instructions or a skill file with a narrow, reviewable learning directive while preserving the existing command, safety, and workflow rules.
---

# Learn

## Goal

Use this skill when the user wants the agent to learn a new instruction or behavioral rule and store it in a durable shared location for future sessions.

## Scope

This skill applies to either of these targets:

- `agent-config/AGENTS.md` for portable global behavior
- a skill file under `.agents/skills/<name>/SKILL.md` when the user wants to encode a reusable workflow rule
- do not modify any files except for these

## Workflow

- Ensure that the learn skill modifies only its relevant files and does not make code changes based on the learning instructions.

1. Read the target file before changing it.
2. Decide whether the rule belongs in the global portable instructions or in a specific skill.
3. Add only the specific new rule or learning directive the user requested.
4. Keep the change narrow and avoid duplicating existing guidance.
5. Preserve the established command-execution, safety, workflow, and validation requirements already in the file.
6. Keep the wording short, directly actionable, and easy to review.
7. If the requested behavior is ambiguous, ask for the exact rule wording before editing.

## Editing rules

- Prefer a single focused bullet or small section addition in the relevant file.
- Do not rewrite unrelated sections or reorder existing instructions.
- Do not add broad policy, redundant warnings, or speculative behavior.
- Keep changes consistent with the surrounding style and wording.
- Prefer minimal, durable updates that reflect a real learning requirement.
- When the new instruction is reusable across tasks, prefer the relevant skill file over the global AGENTS file.

## Validation

- Confirm the new instruction is present in the chosen target file.
- Verify the existing rules remain intact.
- Make the edit as small and reviewable as possible.
- When using this skill, ensure changes apply only to the specified skill or AGENTS.md, and not to the repository directly unless explicitly authorized.
