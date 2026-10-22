# Introduction to OpenAI for coding work

OpenAI provides language models and several products built on them. For coding
work in this repository, the products that matter are the models themselves
and Codex, OpenAI's coding-agent CLI. This guide explains how those pieces fit
together, how this repository connects to them, and how to get better results
from OpenAI models.

For Codex concepts, read [CODEX_INTRODUCTION.md](CODEX_INTRODUCTION.md). Use
[EDITOR_WORKFLOW.md](EDITOR_WORKFLOW.md) for setup, the day-to-day workflow
across clients, and operational review procedures.

## The OpenAI pieces

| Piece | What it is | How you use it here |
| --- | --- | --- |
| Models | Language models such as the GPT family, including reasoning models | Selected by name in Codex configuration |
| Codex CLI | A terminal coding agent that reads the repository, edits files, runs commands, and reviews diffs | `codex`, `codex review --uncommitted` |
| OpenAI API | The HTTP API that serves the models, including the Responses API | Reached indirectly through OpenRouter |
| ChatGPT | The consumer chat product | Not configured by this repository |

Codex is the harness; the model is the engine. You can change the model
without changing the workflow, and the workflow (skills, `AGENTS.md`, rules,
review loop) stays the same.

## How this repository connects to OpenAI models

This repository does not call OpenAI directly. Codex is configured to use
OpenRouter, a gateway that exposes models from many providers, including
OpenAI, behind one API key.

The relevant settings live in `agent-config/config.toml` and are rendered into
`~/.codex/config.toml` by `./scripts/install.sh`:

```toml
model = "<openrouter-model-id>"
model_provider = "openrouter"

[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
wire_api = "responses"
```

- `model` is the default model for every session. OpenRouter model ids are
  prefixed with the provider, for example `openai/<model>`.
- `wire_api = "responses"` uses the Responses API shape, which Codex expects.
- `env_key` names the environment variable holding the key. The managed
  `codex` Zsh function loads it from this repository's `.env` per invocation.

Use a different model for one session without changing configuration:

```bash
codex --model openai/<model>
```

To make the change permanent, edit `agent-config/config.toml`, rerun
`./scripts/install.sh`, and restart Codex. Do not edit `~/.codex/config.toml`
by hand; the next install overwrites it.

Connecting Codex to OpenAI directly instead of through OpenRouter is a
provider change and an authentication change. It is not set up by this
repository.

## Choosing a model

Model names and availability change often, so this guide does not recommend a
specific model. Choose by the shape of the task:

| Task | What to prefer |
| --- | --- |
| Multi-step changes, debugging, planning, review | A reasoning model at medium or high effort |
| Mechanical edits, renames, formatting, small fixes | A faster, cheaper model or lower reasoning effort |
| Very large files or many files at once | A model with a large context window |
| Repeated identical tasks | The cheapest model that passes your validation |

Check current model ids, context sizes, and prices on the OpenRouter models
page before switching, and confirm the model supports tool calling, which
Codex requires.

## Settings that change results

These keys in `agent-config/config.toml` affect quality, speed, and cost:

| Setting | Effect | Guidance |
| --- | --- | --- |
| `model_reasoning_effort` | How much the model thinks before answering | `medium` is a good default. Raise for hard debugging or design; lower for mechanical work |
| `plan_mode_reasoning_effort` | Reasoning effort used in planning mode | Keep at or above the normal effort; planning mistakes are expensive |
| `model_verbosity` | Length of the model's prose | `low` keeps reports short; the diff and checks carry the detail |
| `approval_policy` | When Codex asks before acting | `on-request` lets Codex ask for risky actions instead of running them silently |
| `sandbox_mode` | What Codex may modify | `workspace-write` limits writes to the workspace; use `--sandbox read-only` for planning |

Higher reasoning effort is not free. It increases latency and token usage.
Raise it for a specific session when a task stalls, rather than globally.

## Tips for getting the best results

### Give a goal, constraints, and a check

OpenAI reasoning models do best with a clear outcome and a way to verify it,
not a step-by-step script.

```text
Goal: the orders endpoint returns 404, not 500, for an unknown id.
Constraints: keep the existing error response shape; no new dependencies.
Check: add a regression test and run the focused test, then the full suite.
```

### Let the model reason; do not ask it to show its reasoning

Reasoning models already think internally. Prompts like "think step by step"
add length without improving results. Ask for the result and the evidence
instead.

### Point at anchors

Name the file, symbol, failing command, or error text. A concrete anchor
prevents the model from guessing which code path you meant and reduces token
usage spent on search.

### Keep always-loaded instructions short

`AGENTS.md` is sent with every request. Long instructions cost tokens on every
turn and dilute the rules that matter. Put detailed workflows in skills and
reference documents, and load them only when needed. See
[TOKEN_OPTIMIZATION.md](TOKEN_OPTIMIZATION.md).

### Start a new session for a new task

Long sessions accumulate stale context. Start a fresh `codex` session when the
task changes, and restate the goal rather than relying on earlier turns.

### Follow the operational workflow

Use the [editor workflow](EDITOR_WORKFLOW.md) for planning, implementation,
validation, and review procedures.

## Cost and usage

- OpenRouter bills per token, and prices differ by model. Input context,
  including `AGENTS.md`, skills, and files the agent reads, usually dominates.
- Reasoning tokens are billed even though you do not see them.
- Set a spending limit and review usage on the OpenRouter dashboard.
- Prefer targeted reads and filtered command output (`rtk`) over dumping whole
  files or logs into the conversation.

## Security and privacy

- The API key lives only in the ignored `.env` file. Never paste it into a
  prompt, commit it, or print it in a terminal that is being recorded.
- Code and command output you share with the agent are sent to the model
  provider through OpenRouter. Do not include secrets, customer data, or
  private keys in context.
- Review OpenRouter's provider and data-retention settings for your account if
  your code has confidentiality requirements.

## Common problems

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Authentication error on start | `.env` missing or key empty, or shell not reloaded | Fill `.env`, run `source "${ZDOTDIR:-$HOME}/.zshrc"` |
| Model not found | Wrong OpenRouter model id | Copy the exact id from the OpenRouter models page |
| Tool calls fail or the agent cannot edit | Model does not support tool calling | Choose a model that supports tools |
| Configuration change ignored | Edited `~/.codex/config.toml` directly or did not restart | Edit `agent-config/config.toml`, rerun the installer, restart Codex |
| Project not trusted | Repository outside `~/github` or added after install | Rerun `./scripts/install.sh`, or trust it when Codex prompts |

## Checklist

- The model id is valid on OpenRouter and supports tool calling.
- Reasoning effort matches the task rather than a global maximum.
- Prompts state a goal, constraints, and a check.
- Large tasks were planned before editing.
- `codex review --uncommitted` ran and each finding was verified.
- No secrets entered prompts, logs, or tracked files.
