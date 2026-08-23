# Agent configuration layout

This repository is a shared agent base for GitHub Copilot in VS Code and an
OpenRouter-backed Codex client. The clients remain separate services, but the
installer distributes the same source instructions, skills, and reference docs
to each client's discovery locations.

## What Codex loads automatically

Codex automatically discovers a limited set of files:

| Purpose | User scope | Repository scope |
| --- | --- | --- |
| Instructions | `~/.codex/AGENTS.md` | `AGENTS.md` from the repository root to the working directory |
| Configuration | `~/.codex/config.toml` | `.codex/config.toml` in trusted projects |
| Skills | `~/.agents/skills/` | `.agents/skills/` from the working directory to the repository root |
| Rules | `~/.codex/rules/` | Project rules next to an active trusted `.codex/config.toml` layer |

Codex does not recursively read arbitrary files under `docs/`. A loaded
`AGENTS.md`, selected skill, or user prompt must point Codex to the relevant
document.

## Why this repository is not a full home-directory mirror

The active `~/.codex` directory mixes portable configuration with private and
ephemeral runtime state. Examples include:

- `auth.json`
- installation identifiers
- session transcripts and history
- SQLite state and write-ahead logs
- model and application caches
- downloaded plugins
- shell snapshots

Tracking or replacing those files would expose credentials, create noisy
changes, and make the setup less portable.

This repository manages only:

- global instructions
- user configuration defaults
- command rules
- reusable skills

The installer links instructions, rules, the OpenRouter profile, and skills into
their documented locations while preserving runtime state. It renders
`~/.codex/config.toml` as a regular file so it can add machine-specific trust
entries for `~/github` and every Git worktree discovered beneath it. Existing
notification, hook-state, notice, local Node REPL, and runtime
shell-environment settings are carried forward into the rendered file.

## GitHub project trust

Codex project trust uses exact absolute project paths. A parent project entry
and wildcard entries do not automatically trust nested repositories. On each
run, the installer adds the current user's `~/github` path plus every Git
worktree found recursively below it to the generated config. Rerun the
installer after adding repositories to refresh those entries.

## OpenRouter profile

Codex profile files live directly under `CODEX_HOME` and use the name
`<profile>.config.toml`.

- `openrouter.config.toml` for the OpenRouter Responses API endpoint.
- `.env` for the ignored local `OPENROUTER_API_KEY` value.
- `scripts/openrouter.sh`, or the installed `agent` command, to load `.env`
  and launch.

The profile layers over `config.toml` only when selected with `--profile`, so
OpenRouter settings do not affect ordinary Codex sessions.

## Shared Copilot installation

The generated Copilot custom agent is based on `agent-config/AGENTS.md` and
receives Copilot-specific frontmatter at install time. No files are installed
into `~/.copilot/instructions`; repository documentation remains local and is
read by the agent when needed.
- This complements, and does not replace, this repository's own
  `.github/copilot-instructions.md`, which still applies only when this
  repository is open.

The installer also renders a user-profile custom agent for Copilot Chat:

- Target: `~/.copilot/agents/getkan-ai.agent.md`.
- The agent is named `getkan-ai`, has the standard read, edit, search, execute,
  todo, and agent tools, and instructs Copilot to answer repository status,
  requirements, workflow, validation, and setup questions from the current
  workspace's markdown files.
- Default location: `~/.copilot/agents/getkan-ai.agent.md`. Set `COPILOT_HOME`
  before installing to override this target.
- To confirm it is loaded, select the `getkan-ai` agent in Copilot Chat and ask
  whether it is working. The expected answer should cite facts from `ROADMAP.md`,
  `TASKS.md`, and `SPEC.md`, including the current phase and a repository
  non-goal.

The installer links skills from `.agents/skills` into `~/.copilot/skills` and
installs the generated custom agent into `~/.copilot/agents`. Documentation in
`docs/` remains repository-local and is loaded only when a prompt, skill, or
agent explicitly references it.

## Skill location migration

Older local layouts may place skills under `.codex/skills`. Current Codex
documentation uses `.agents/skills` for user and repository skills. This
repository uses `.agents/skills` as its canonical location.

## Direct `CODEX_HOME` use

Do not point `CODEX_HOME` at this repository. Codex writes runtime state into
`CODEX_HOME`, while this repository intentionally separates managed files from
runtime data. Use `scripts/install.sh` instead.

## Verification

After installation, restart Codex and ask:

```text
List the instruction sources and relevant skills active for this repository.
```

The expected instruction order is:

1. `~/.codex/AGENTS.md` from `agent-config/AGENTS.md`
2. the repository's own project instructions, when present
3. any closer nested `AGENTS.md` or `AGENTS.override.md`
