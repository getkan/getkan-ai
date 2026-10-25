# Project roadmap

## Delivery outcomes and subprojects

Order reviewable outcomes and their dependencies. For complex projects, give
each subproject a delivery stage and repeat the four-stage lifecycle below.
Distinguish delivery order from lifecycle stage; omit unnecessary structure
for small projects.

## Current outcome

- Scope and linked SPEC requirements:
- Parent outcome and subproject dependencies:
- Current lifecycle stage:
- Risks, rollback needs, and unresolved decisions:

### Stage 1: Understanding the problem

- Outputs: functional/nonfunctional requirements, environment/datastore
  constraints, measurable success, stack choices, and new integrations in SPEC.
- Exit criteria: material decisions resolved and subprojects/dependencies named.
- Evidence and next-stage approval: record user approval before stage 2 begins.

### Stage 2: High-level design and implementation

- Outputs: architecture and contracts in SPEC, high-level TASKS, skeletons,
  deterministic seed data, and executable end-to-end integration tests.
- Exit criteria: structural design and scaffold verified; expected-red
  integration baseline documented. Harness failures and regressions block exit.
- Evidence and next-stage approval: record user approval before stage 3 begins.

### Stage 3: Detailed design and implementation

- Outputs: user-selected tasks implemented with unit tests and integration
  coverage; design changes and validation evidence recorded.
- Exit criteria: feature scope and applicable checks pass. Pause after each
  validated unit for the commit checkpoint recorded in TASKS.
- Evidence and next-stage approval: record user approval before stage 4 begins.

### Stage 4: Review and pull-request preparation

- Outputs: feature/base review including committed tasks and worktree changes,
  complete validation, addressed findings, and repository-template PR evidence.
- Exit criteria: applicable integration tests and required gates pass; manual
  tests, security, performance, deployment/rollback concerns are covered as
  applicable. No stage 2 expected-failure exception applies to final readiness.
- Handoff: stop; publication and deployment still need explicit authorization.

## Change record

Record concise approved scope/design changes, affected outcomes, and reasons.
Link to SPEC decisions and TASKS evidence rather than duplicating their detail.
