---
name: tailwind
description: "G-AI: Build and refactor Tailwind CSS interfaces using utility composition, responsive variants, theme tokens, accessibility states, and project configuration."
---

# Tailwind CSS

## Workflow

1. Inspect the Tailwind version, content globs, theme extension, plugins, and component conventions.
2. Reuse existing design tokens and utility patterns before adding configuration.
3. Compose utilities in a readable order and keep responsive and state variants intentional.
4. Add custom CSS or theme values only when utilities cannot express the requirement cleanly.
5. Validate generated styles, responsive behavior, accessibility states, and production builds.

## Safety Rules

- Use the project's configured version and avoid unsupported utility syntax.
- Do not add arbitrary values when a shared token exists.
- Keep class strings maintainable; extract repeated patterns using the local convention.
- Check content scanning so production builds retain every required class.

## Validation

- Run the repository lint, formatter, and build checks.
- Test mobile, desktop, hover, focus, disabled, and reduced-motion states.
- Confirm production CSS generation includes the changed utilities.
