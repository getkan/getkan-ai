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
- declared Codex marketplaces and plugins

The installer links instructions, rules, and skills into
their documented locations while preserving runtime state. It renders
`~/.codex/config.toml` as a regular file so it can add machine-specific trust
entries for `~/github` and every Git worktree discovered beneath it. Existing
notification, hook-state, notice, local Node REPL, and runtime
shell-environment settings are carried forward into the rendered file.

## Codex plugins

`agent-config/plugins.toml` is the portable plugin manifest. Each marketplace
entry declares its Codex marketplace name, source, and optional Git ref; each
plugin entry declares a plugin name and its marketplace. The installer adds
all declared marketplaces before it installs declared plugins through the
Codex CLI.

This is additive. Existing local plugin configuration not declared by the
manifest is preserved, and the installer does not track or copy downloaded
plugins, caches, or credentials.

## GitHub project trust

Codex project trust uses exact absolute project paths. A parent project entry
and wildcard entries do not automatically trust nested repositories. On each
run, the installer adds the current user's `~/github` path plus every Git
worktree found recursively below it to the generated config. Rerun the
installer after adding repositories to refresh those entries.

## OpenRouter configuration

The base `config.toml` contains the OpenRouter Responses API endpoint and
default model. `.env` stores the ignored local `OPENROUTER_API_KEY` value, and
The installed `agent` command, implemented by `scripts/install.sh`, loads it
before launch.

## OpenCode provider

The `agent` command also supports OpenCode as an alternate provider:

- `agent --provider opencode` (or `-p opencode`) loads `.env` and execs
  `opencode` instead of `codex`. `agent` with no
  `-p`/`--provider` flag still defaults to Codex.
- `agent-config/opencode.config.json` sets the default OpenRouter-backed
  model. The installer links it to `$OPENCODE_HOME/opencode.json`, defaulting
  `OPENCODE_HOME` to `~/.config/opencode`.
- OpenCode reads the same `OPENROUTER_API_KEY` environment variable that
  `.env` provides to Codex; no separate credential file is managed by this
  repository.

## Subagents: plan, build, reviewer

The `plan`, `build`, and `reviewer` skills under `.agents/skills/` also
render as named custom agents. Each subagent's client mode and permitted or
denied tools live in a human-readable config file,
`agent-config/subagents/<name>.config.json`, instead of being hardcoded in
`scripts/install.sh`:

```json
{
  "mode": "subagent",
  "copilotTools": ["read", "search", "execute", "todo"],
  "opencodeDeniedTools": ["edit", "task"]
}
```

- Target: `~/.copilot/agents/<name>.agent.md`, generated with a `tools` list
  taken from `copilotTools`. `plan` and `reviewer` exclude `edit`, enforcing
  the read-only boundary described in each skill.
- Target: `$OPENCODE_HOME/agent/<name>.md` (default
  `~/.config/opencode/agent/`), generated with the config's `mode` and a
  `tools:` block that denies every name listed in `opencodeDeniedTools`.
  `task` denies calling other subagents. Confirmed with `opencode agent list`
  against the installed OpenCode 1.18.x binary: `plan` and `reviewer` show an
  `edit`/`*` and `task`/`*` deny rule and `build` does not.
- Codex has no native per-agent tool-permission mechanism. Codex sessions
  discover these as ordinary skills (`.agents/skills/plan`,
  `.agents/skills/build`, `.agents/skills/reviewer`) and rely on the skill's
  own instructions to honor the same no-edit boundary.
- Rerun the installer after changing a skill body or a subagent config file
  to refresh the rendered agent files.

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
