# Getkan AI roadmap

## Phase 1: Portable agent foundation

Status: Complete

### Outcome

Shared instructions, OpenRouter configuration, rules, skills, and reference
docs install into the appropriate Codex and Copilot locations without replacing
private client runtime state.

### Exit criteria

- The Linux installer supports preview and timestamped backups.
- Repository validation rejects private runtime state and malformed portable
  configuration.

## Phase 2: Workflow alignment

Status: Complete

### Outcome

The repository and reusable skills encode the complete planning, implementation,
review, manual-testing, and merge workflow.

### Included work

- Add repository planning documents and reusable project templates.
- Separate project planning from pull-request readiness.
- Add cross-platform installer integration tests and pull-request CI.
- Add Dependabot coverage, dependency review, and PR evidence prompts.
- Add GitHub Copilot repository instructions for VS Code.
- Establish `agent-config/` as the shared Codex and Copilot source directory.
- Install shared skills and docs into the Copilot user directories.
- Use the OpenRouter client for local pull-request readiness checks.
- Render exact trusted-project entries for every Git worktree beneath the
  current user's `~/github` directory.

### Risks

- Required GitHub checks cannot be configured until their final names exist on
  the default branch.

### Exit criteria

- Local validation and skill validation pass.
- Linux installer integration tests pass locally and in CI.
- The final diff contains only workflow-alignment changes.

## Phase 3: Enforced repository governance

Status: In progress

### Outcome

GitHub settings enforce the review and validation gates documented by the
repository.

### Included work

- Require pull requests and successful validation checks.
- Require conversation resolution.
- Require an independent approval when repository ownership makes that
  practical.
- Confirm secret scanning, push protection, Dependabot, and dependency review.

### Exit criteria

- The repository ruleset protects the default branch.
- Required checks run against the latest pull-request commit.
- The documented merge gate matches GitHub settings.

## Phase 4: Local model token optimization

Status: Not started

See [docs/LOCAL_MODEL_INTEGRATION.md](docs/LOCAL_MODEL_INTEGRATION.md) for the
beginner-level glossary, model overview, and staged setup guide.

### Outcome

Small local models (SmolLM3 3B, Gemma 4 12B, and Qwen 3.6) take the first pass
over prompts and context before a premium model is invoked, reducing premium
token usage without degrading task quality. Every part of the setup is
documented at a level a beginner to local LLMs can follow and verify.

### Included work

- Document, in beginner-friendly terms, what each local model does, how model
  size and quantization affect resource use and quality, and how routing
  between local and premium models works. Link background resources for
  concepts introduced (context windows, quantization, model runtimes).
- Stand up a local model runtime on the host (for example Ollama or
  llama.cpp) serving SmolLM3 3B, Gemma 4 12B, and Qwen 3.6.
- Define how Codex or the OpenRouter profile routes a request to a local
  model first for basic prompt evaluation, context search, and token
  optimization, then forwards to a premium model.
- Measure and record token usage before and after local pre-processing to
  confirm the optimization goal is met.
- Containerize the local model runtime with Docker once the host setup is
  validated.
- Document moving the containerized runtime to a separate machine on the
  local network, including the network and security considerations of
  exposing a local model endpoint.
- Expand the local models' role from pre-processing to a first-pass
  implementation attempt, with premium models reviewing and correcting their
  output, once local model quality supports it.

### Risks

- Small local models may produce low-quality or incorrect first-pass output,
  requiring careful scoping of what they are trusted to do at each stage.
- Larger models (Gemma 4 12B) may exceed available host resources; running
  models in Docker or on a separate machine adds latency, network exposure,
  and additional attack surface that must be secured deliberately.
- This phase introduces meaningfully more infrastructure and concepts than
  earlier phases; pacing and documentation must match a beginner's
  familiarity with local LLMs.

### Exit criteria

- Local models run on the host and measurably reduce premium token usage for
  routed requests without a documented quality regression.
- Beginner-level documentation covers every component introduced in this
  phase: local runtime, routing, containerization, and (if completed)
  separate-machine deployment.
- The containerized deployment is validated before any separate-machine
  deployment is attempted.
