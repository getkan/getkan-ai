---
name: js
description: "G-AI: Build, debug, refactor, and test JavaScript applications using modern ECMAScript, browser APIs, Node.js, package managers, and project conventions."
---

# JavaScript

## Workflow

1. Inspect the package manifest, runtime target, module system, and existing scripts.
2. Reproduce the behavior with the smallest relevant command or test.
3. Implement the smallest change that preserves the public API and local style.
4. Handle asynchronous control flow, errors, input boundaries, and cleanup explicitly.
5. Validate with formatting, linting, type-aware checks when available, and focused tests.

## Safety Rules

- Preserve the project's module system and supported runtime versions.
- Avoid floating dependencies and unrelated package upgrades.
- Do not log secrets, tokens, or sensitive request data.
- Keep browser and server-only APIs on their correct side of the boundary.

## Validation

- Run the narrowest relevant test first.
- Run the repository lint and test scripts before completion.
- Verify both success and failure paths for changed behavior.
