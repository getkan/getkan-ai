# getkan-ai

Shared agent base for GitHub Copilot in VS Code, an OpenRouter-backed Codex
client, and an OpenRouter-backed OpenCode client. It keeps portable
instructions, configuration, rules, reusable skills, and reference
documentation in one repository, then installs each item into the
client-specific location that consumes it. See
[docs/CLIENT_REFERENCE.md](docs/CLIENT_REFERENCE.md) for the full command
and configuration reference across all three clients, and
[docs/CLIENT_WORKFLOW.md](docs/CLIENT_WORKFLOW.md) for how to use the
shared `plan`/`build`/`reviewer` subagents in each one.

## Install

Preview and install:

```bash
./scripts/install.sh --dry-run
./scripts/install.sh
```

Restart Codex and VS Code after installation. Existing managed files are backed
up under `~/.codex/backups/`. Credentials, sessions, history, caches, and
plugins not declared in the manifest are preserved.

The installer manages:

- `agent-config/` into Codex, OpenCode, and Copilot instruction targets
- declared Codex marketplaces and plugins from `agent-config/plugins.toml`
- `.agents/skills/` into both `~/.agents/skills/` and `~/.copilot/skills/`
- the `getkan-ai` Copilot custom agent into `~/.copilot/agents/`
- the `plan`, `build`, and `reviewer` subagents into `~/.copilot/agents/`
  and `$OPENCODE_HOME/agent/`
- a globally available `agent` command in `~/.local/bin/` that launches
  `scripts/install.sh`, defaulting to Codex or selecting OpenCode with
  `-p opencode`

## Codex plugins

Declare marketplaces and plugins in `agent-config/plugins.toml`. During a
normal installation, the installer runs Codex's native marketplace and plugin
commands for each declaration. This is additive: plugins or marketplaces not
declared in the manifest remain machine-local and are not removed.

The manifest tracks sources and plugin selections only. Downloaded plugin
files, caches, credentials, and authentication remain in `~/.codex` and are
never committed.

### Trust GitHub projects

Every installation renders `~/.codex/config.toml` with trusted-project entries
for that user's `~/github` directory and every Git worktree found recursively
beneath it. This includes repositories inside organization or grouping
subdirectories.

Codex trust entries match exact project roots rather than directory globs, so
the installer discovers each repository instead of relying on a parent or `*`
entry. Rerun the installer after creating or cloning repositories so new
worktrees are added. Common dependency and build directories are skipped during
discovery.

## Codex basics

New to Codex? It's OpenAI's coding agent CLI (and IDE extension), separate
from GitHub Copilot. A few things worth knowing before you dive in:

- Codex reads configuration from `CODEX_HOME` (`~/.codex` by default),
  including `AGENTS.md` (instructions), `config.toml` (settings), `rules/`
  (which shell commands it may run without asking), and skills under
  `~/.agents/skills`. The installer in this repository populates those files
  for you; see [docs/AI_LAYOUT.md](docs/AI_LAYOUT.md) for exactly what goes
  where and why.
- This repository configures Codex to use OpenRouter by default. The provider
  and model settings live in `~/.codex/config.toml`; see "Codex-OpenRouter
  Use" below.
- `AGENTS.md` files are how you give Codex durable project instructions. This
  repository's maintenance instructions are in [AGENTS.md](AGENTS.md),
  while the portable client instructions live in `agent-config/AGENTS.md`.
- Run `codex --help` or start `codex` with no arguments to open the
  interactive TUI once it is installed and configured.

## Codex-OpenRouter Use

For the OpenRouter-backed Codex client, copy `.env.example` to `.env`, add the
key, and install the repository configuration:

```bash
cp .env.example .env
./scripts/install.sh
```

Then use the globally available `agent` command from any directory (ensure
`~/.local/bin` is on `PATH`):

```bash
agent
```

Trust the current project directory persistently with:

```bash
agent --trust
```

The wrapper reads only `OPENROUTER_API_KEY` from `.env`; the file is ignored by
Git and must never be committed.

## OpenCode

[OpenCode](https://opencode.ai) is a separate terminal coding-agent CLI,
installed with its own installer (`curl -fsSL https://opencode.ai/install |
bash`), not by this repository. This repository configures it to use the
same OpenRouter credential as Codex:

```bash
agent -p opencode
```

See [docs/CLIENT_REFERENCE.md](docs/CLIENT_REFERENCE.md) for OpenCode's
configuration file locations and commands.

## Copilot in VS Code

GitHub Copilot loads the repository instructions from
[.github/copilot-instructions.md](.github/copilot-instructions.md) in VS Code.
Copilot is a separate service and cannot be configured to use OpenRouter as its
model endpoint.

The installer generates `~/.copilot/agents/getkan-ai.agent.md` from
`agent-config/AGENTS.md`, adding Copilot-specific metadata. It links repository
skills into `~/.copilot/skills` without installing documentation as global
instructions.

Set `COPILOT_HOME` before installing to use a different Copilot root. In
Copilot Chat, select `getkan-ai` and ask whether it is working; it should answer
from this repository's markdown files and name the files it used.

## AI development workflow

The reusable workflow separates planning from implementation and review:

- `$ai-project-manager` reads or creates `AGENTS.md`, `docs/SPEC.md`,
  `docs/ROADMAP.md`, and `docs/TASKS.md`, pauses at plan-approval boundaries,
  and executes one reviewable phase at a time.
- Review the final diff, run the repository validation, record manual testing,
  and verify CI and review state before merge.

Project-document templates live under
`.agents/skills/ai-project-manager/assets/project-docs/`. Adapt them to the
project instead of leaving placeholder requirements.

See [docs/WORKFLOW.md](docs/WORKFLOW.md) for the complete lifecycle.

## Validate

```bash
./scripts/validate.sh
```

The validation includes an isolated Linux installer integration test and runs
dependency review for pull requests.

## Repository layout

- `AGENTS.md`: instructions for maintaining this repository
- `docs/SPEC.md`, `docs/ROADMAP.md`, and `docs/TASKS.md`: requirements,
  phase order, and validated task status
- `.agents/skills/`: reusable skills
- `.env.example`: template for the ignored OpenRouter credential file
- `agent-config/`: shared Codex and Copilot source configuration, instructions,
  and rules
- `docs/`: reference documentation loaded only when explicitly requested
- `scripts/`: installation and validation

See [docs/AI_LAYOUT.md](docs/AI_LAYOUT.md) for detailed discovery and
configuration behavior.

For background, see [docs/CODEX_INTRODUCTION.md](docs/CODEX_INTRODUCTION.md)
and [docs/AI_CODING_AGENTS.md](docs/AI_CODING_AGENTS.md). For reducing model
usage and cost, see [docs/TOKEN_OPTIMIZATION.md](docs/TOKEN_OPTIMIZATION.md).
