---
name: deep
description: Use this skill for deliberate, high-confidence work that benefits from slower reasoning, evidence gathering, and careful validation before changing code.
---

# Deep

## Trigger

Use this skill when the task is ambiguous, sensitive, architecture-heavy, or likely to have more than one root cause. Prefer it for debugging, reviews, refactors, and correctness-critical changes where correctness matters more than speed.

## Workflow

1. State the working hypothesis before changing code.
2. Gather the minimum evidence needed to test that hypothesis: exact failing output, relevant stack trace, narrow file reads, and nearby tests.
3. Prefer a single root-cause fix over broad cleanup or speculative rewrites.
4. Validate the fix with the smallest relevant command that checks the changed behavior.
5. If evidence is incomplete, pause and request the missing fact instead of guessing.
6. Repeat only the narrow verification needed to confirm the fix and guard against regressions.

## Deep reasoning rules

- Treat speed as secondary to correctness.
- Explicitly check assumptions before patching.
- Prefer exact file anchors and nearby call sites over whole-repo exploration.
- Keep the change narrow and reviewable.
- Do not broaden scope while the failing behavior is still under investigation.
- Preserve unrelated work and avoid refactors that are not required for the fix.

## Validation

- Reproduce the issue with the smallest relevant command or failing test.
- Run the narrowest validation after the fix.
- Only expand scope when the evidence says the broader behavior is affected.
- Report the evidence, not just the conclusion.
