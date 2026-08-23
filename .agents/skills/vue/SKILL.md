---
name: vue
description: Build, debug, refactor, and test Vue applications with Composition API, reactivity, components, routing, state management, accessibility, and framework conventions.
---

# Vue

## Workflow

1. Inspect the Vue version, build tool, router, state library, compiler options, and neighboring components.
2. Reproduce the behavior at the smallest component or route boundary.
3. Follow the local Composition API, props, emits, and composable conventions.
4. Implement explicit loading, error, empty, and interaction states with semantic markup.
5. Validate with focused tests, type checks, linting, and the production build.

## Safety Rules

- Keep props and emitted events typed and document contract changes through tests.
- Avoid mutating props or hiding side effects inside computed values.
- Preserve keyboard access, focus behavior, labels, and SSR/client boundaries.
- Reuse existing composables and design tokens before adding abstractions.

## Validation

- Run focused component and interaction tests.
- Run linting, formatting, type checking, and build commands.
- Verify route, async, error, empty, keyboard, and responsive states.
