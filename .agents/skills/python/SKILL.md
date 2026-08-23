---
name: python
description: Build, debug, refactor, and test Python applications with project environments, typing, packaging, errors, security, and reliable command-line or service behavior.
---

# Python

## Workflow

1. Inspect the project metadata, supported Python version, environment manager, entry points, and test layout.
2. Reproduce the issue with the smallest relevant command or test.
3. Follow local conventions for modules, typing, exceptions, configuration, and dependency management.
4. Implement the smallest change with explicit input validation and resource cleanup.
5. Validate formatting, linting, type checking, unit tests, and representative integration behavior.

## Safety Rules

- Never commit credentials, private data, generated environments, or runtime state.
- Prefer standard-library and existing dependencies before adding a package.
- Keep exceptions actionable and avoid catching broad errors without a recovery plan.
- Preserve CLI output and exit-code contracts when scripts may consume them.

## Validation

- Run the narrowest pytest or project test first.
- Run the configured formatter, linter, and type checker.
- Exercise success, invalid input, failure, and cleanup paths.
