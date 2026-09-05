---
name: playwrite
description: Verify frontend/UI behavior in a real browser using the Playwright tools (open_browser_page, click_element, run_playwright_code) instead of relying on static code reading alone. Use for ALL frontend development — React, Svelte, Vue, CSS, HTML, contenteditable, forms, animations, or any browser-rendered feature — when building, debugging, or validating a fix.
---

# Playwrite

Browser-first verification workflow for frontend work. Reading code can miss
real DOM/browser behavior (focus, selection, contenteditable quirks, layout,
timing). Prove behavior by driving an actual browser instead of guessing.

## Workflow

1. Start the dev server in the background (`run_in_terminal` with
   `mode: async` or `&`), then confirm it's serving before opening a page.
2. Open the target route with `open_browser_page`. Keep the returned page id;
   reuse it for the whole investigation instead of reopening.
3. Prefer `click_element`/interaction tools with an element `ref` from the
   page snapshot over raw CSS-selector clicks in `run_playwright_code` —
   selector-based `locator().click()` can time out on actionability checks for
   absolutely positioned, animated, or overlay-heavy elements common in
   custom UI (e.g. blinking cursors, fixed-position editors). If a selector
   click stalls, retry via `click_element` with a ref, or use `{ force: true }`
   / `element.evaluate(e => e.focus())` in `run_playwright_code`.
4. Reproduce the bug with the smallest interaction sequence first (type,
   press keys, click), then inspect the *actual* DOM state, not just the
   rendered/visible text:
   - `element.innerText` for what the user perceives.
   - `Array.from(el.childNodes).map(n => ({type: n.nodeType, text: n.textContent}))`
     for the real node structure — desyncs (e.g. contenteditable caret bugs)
     often only show up here, not in `innerText`.
   - `window.getSelection()` range info (`startContainer`, `startOffset`) when
     debugging focus/caret/selection issues.
5. Form a hypothesis, change one variable at a time (e.g. swap manual
   `Range`/DOM node insertion for `document.execCommand(...)`), and re-run the
   exact same repro steps to compare before/after DOM state.
6. After editing source files, reload (`page.goto`/`page.reload`) to pick up
   HMR changes, then re-run the full repro to confirm the fix, not just the
   last failing step.
7. Watch for app-level side effects that break automated repro timing (e.g.
   countdown timers, redirects, auto-save) — long tool round-trips can let
   these fire mid-test. Reload and re-run quickly, or account for the timer
   in the test.
8. Clean up background terminals/dev servers with `kill_terminal` once
   validation is complete.

## Safety Rules

- Never treat a passing build/lint/typecheck as sufficient proof for
  interactive/browser-rendered behavior — validate in the browser too.
- Don't leave dev servers or browser pages running after the task is done.
- Don't rely solely on visible/rendered text when debugging sync issues
  between application state and the DOM — inspect raw node structure.

## Validation

- The same interaction sequence that reproduced the bug must be re-run after
  the fix and produce the expected `innerText`/DOM structure.
- Confirm no new console errors or unexpected navigations occurred during the
  repro.
