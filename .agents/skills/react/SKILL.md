---
name: react
description: "G-AI: Build, debug, refactor, and test React applications with component boundaries, hooks, state, effects, accessibility, performance, and framework conventions."
---

# React

## Workflow

1. Inspect the React version, rendering framework, route boundary, data flow, and nearby components.
2. Reproduce the issue at the smallest component or interaction boundary.
3. Keep state local when possible and define a clear owner for shared state.
4. Implement accessible markup, stable loading/error/empty states, and the smallest component change.
5. Validate behavior with focused tests and rendered checks at relevant viewports.

## Safety Rules

- Follow the repository's React compiler, hooks, and server/client component conventions.
- Keep effects for synchronization with external systems; derive render data during rendering.
- Preserve keyboard behavior, labels, focus management, and semantic structure.
- Avoid premature memoization and broad rerenders unless measurement or local guidance supports it.

## Validation

- Run focused component and interaction tests.
- Run lint, type checks, and the production build when applicable.
- Verify loading, error, empty, success, keyboard, and responsive states.
