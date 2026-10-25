# Project specification

Use the existing SPEC directly when present. Adapt this template only when a
SPEC is missing; omit irrelevant sections rather than invent requirements.
Scope feature/subproject additions explicitly without duplicating project-wide
requirements. Use the same feature/project identifiers as ROADMAP and TASKS
to separate requirements, design, acceptance criteria, and approved changes
for sequential or concurrent features. Preserve other features' scope and
record shared contracts and cross-feature dependencies explicitly.

## Problem

Describe the problem this project solves and why it matters.

## Users

Identify the intended users and their important constraints.

## Required behavior

- Describe observable user and system behavior.
- Define error, empty, loading, and recovery behavior where applicable.

## User experience

Describe primary workflows, accessibility requirements, and supported layouts
or interfaces.

## Architecture and data flow

Describe major components, state ownership, storage, external services, and
interfaces. In stage 2, define table/schema structure, classes, method
contracts, and component boundaries before detailed implementation.

## Environment baseline and technology decisions

For an existing codebase without a SPEC, investigate manifests (for example
`package.json`), Dockerfiles, CI workflows, and relevant source/configuration.
Record a concise baseline for future requests with source paths: language,
framework, datastore, runtime/toolchain, environment, deployment, and existing
validation commands. Distinguish observed facts from unknowns and proposals;
never read secrets or infer undocumented production configuration.

For new projects, record approved stack and deployment decisions before
scaffolding. For new packages/services, record purpose, interfaces, constraints,
and risks. Include concise technology learning resources when useful.

## Security and privacy

Document trust boundaries, permissions, sensitive data, and required security
checks.

## Performance and compatibility

Define supported environments and measurable budgets or compatibility
requirements.

## Non-goals

- List adjacent work that is intentionally outside the project scope.

## Acceptance criteria

- Use observable, testable outcomes.
- Link requirements to automated and manual checks and end-to-end success.
- Define deterministic seed fixtures and executable integration tests in
  stage 2. Record the baseline in TASKS, including expected failures caused by
  stubs; require passing applicable checks before final feature completion.

## Approved changes

Record concise requirement/design decisions and their affected roadmap outcomes.
Keep unresolved proposals separate from approved changes.

## Unresolved questions

- Record decisions that must be resolved before implementation.
