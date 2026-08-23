---
name: svelte
description: Build, debug, refactor, and test Svelte and SvelteKit applications using idiomatic components, reactivity, stores, actions, routing, and accessibility.
---

# Svelte

## Workflow

1. Inspect the Svelte or SvelteKit version, compiler settings, routes, load functions, and component boundaries.
2. Reproduce the issue in the smallest component, route, or reactive statement.
3. Use idiomatic runes or legacy syntax consistently with the local codebase.
4. Implement explicit loading, error, empty, and browser/server states.
5. Validate with focused tests, type checks, linting, and a production build.

## Safety Rules

- Respect SvelteKit server/client boundaries and do not expose private environment values.
- Keep reactive dependencies clear and avoid accidental subscriptions or mutation.
- Preserve semantic HTML, keyboard access, and form behavior.
- Match the project's adapter, routing, and data-loading conventions.

## Validation

- Run the narrowest component or route test first.
- Run formatting, linting, type checking, and the project build.
- Verify hydration, navigation, loading, failure, and responsive states when relevant.
