---
name: ts
description: Build, debug, refactor, and test TypeScript applications with strict types, safe APIs, module boundaries, and reliable compiler diagnostics.
---

# TypeScript

## Workflow

1. Inspect `tsconfig`, package scripts, module resolution, and neighboring types.
2. Reproduce the issue with the compiler or the narrowest relevant test.
3. Model inputs, outputs, errors, and nullable states explicitly.
4. Implement the smallest type-safe change without weakening compiler settings.
5. Validate compilation, linting, formatting, and focused runtime tests.

## Safety Rules

- Prefer narrowing and discriminated unions over assertions.
- Keep public types stable unless the task requires a contract change.
- Do not use `any` to silence an error; explain unavoidable escapes locally.
- Preserve the project's runtime and declaration-output targets.

## Validation

- Run the relevant `tsc` command with the repository configuration.
- Run focused tests and then the standard project checks.
- Check emitted behavior when a type-only change affects runtime code.
