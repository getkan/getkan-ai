---
name: css
description: Design, implement, debug, and test CSS for responsive interfaces, layout, cascade, accessibility, animation, and maintainable component styles.
---

# CSS

## Workflow

1. Inspect the existing design tokens, component styles, reset, and responsive breakpoints.
2. Identify the cascade, layout context, and smallest reproducible viewport or state.
3. Make the smallest selector and token change that fixes the visual behavior.
4. Preserve semantic HTML, focus states, reduced-motion behavior, and readable contrast.
5. Verify representative desktop, mobile, interaction, and overflow states.

## Safety Rules

- Prefer existing variables and component patterns over one-off values.
- Avoid specificity escalation, unnecessary `!important`, and layout shifts.
- Keep text inside its containers and test long, localized, and empty content.
- Do not hide focus indicators or rely on color alone to communicate state.

## Validation

- Run the project formatter and style checks.
- Inspect changed states at narrow and wide viewports.
- Check keyboard focus, reduced motion, contrast, and overflow where relevant.
