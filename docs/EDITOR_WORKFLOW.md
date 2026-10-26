# AI development and editor workflow

This is the single workflow reference for this repository and the projects it
configures. It covers:

1. Project file roles and the shared installed configuration.
2. Client reference for GitHub Copilot in VS Code, Codex, and OpenCode.
3. The `plan` / `build` / `reviewer` loop in each client.
4. A suggested VS Code workflow.
5. A staged migration to Neovim with tmux orchestrating everything.
6. The complete lifecycle from specification to merge, including security and
   pull-request evidence.
7. Sample workflows for common tasks.

See [AI_LAYOUT.md](AI_LAYOUT.md) for why each installed file is placed where it
is.

## 1. Project file roles

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Maintenance instructions for this repository |
| `agent-config/AGENTS.md` | Portable instructions shared by Codex and Copilot |
| `CLAUDE.md` and `agent-config/CLAUDE.md` | Matching repository and portable instructions for Claude Code |
| `SPEC.md` | Canonical requirements, environment baseline, technology decisions, high-level design, and acceptance criteria |
| `ROADMAP.md` | Delivery outcomes/subprojects, dependencies, lifecycle stage, risks, approval gates, and changes |
| `TASKS.md` | High-level work refined into user-selected tasks, tests, evidence, status, and commit checkpoints |
| `.agents/skills/` | Reusable workflows shared with all clients, including `ask`, `plan`, `build`, and `reviewer` |
| `agent-config/subagents/<name>.config.json` | Client mode and tool permissions for each subagent |
| `docs/` | Repository-local reference material loaded by reference |

Shared concepts:

- **Planning documents**: reuse an existing SPEC directly and preserve existing
  document locations. If SPEC is absent, investigate manifests, Dockerfiles,
  CI workflows, and relevant source/configuration; record a concise, sourced
  environment baseline for future requests. Use `docs/` for new documents
  unless repository instructions specify otherwise.
- **Source of truth**: `agent-config/AGENTS.md` holds instructions shared by
  Codex and Copilot; `agent-config/CLAUDE.md` keeps the same portable guidance
  available to Claude Code. Keep these instruction files aligned.
  `agent-config/` also holds client-specific Codex and OpenCode configuration.
  `.agents/skills/` holds reusable workflows shared by all three clients.
- **Installer**: `./scripts/install.sh` (add `--dry-run` to preview) renders
  and links everything below into place. Rerun it after changing a skill, a
  subagent config file, or adding repositories under `~/github`.
- **Zsh environment integration**: the installer adds managed `codex` and
  `opencode` functions to `${ZDOTDIR:-$HOME}/.zshrc`. They source this
  repository's `.env` in a child shell when invoked, then forward arguments to
  the real client without exporting the key into the parent shell. Run
  `source "${ZDOTDIR:-$HOME}/.zshrc"` or open a new terminal after install.
- **Credentials**: `.env` holds `OPENROUTER_API_KEY`. Never open, print, or
  commit it.

## 2. Client reference

### Choosing a harness

All three harnesses use the shared workflow sources with client-specific
instruction, configuration, and agent integration after `./scripts/install.sh`.
Pick a harness per task, not per project.

| Harness | Model route | Strengths | Boundary enforcement |
| --- | --- | --- | --- |
| GitHub Copilot (VS Code Chat) | GitHub Copilot service | Inline completions, visual diffs, agent picker, browser tools | Tool-level: `ask` has only `read` and `search`; `plan` and `reviewer` have no `edit` or `execute` tool |
| Codex (OpenAI CLI) | OpenRouter via `~/.codex/config.toml` | `codex review --uncommitted`, `AGENTS.md` and skill discovery, plugins | Instruction-only; use `--sandbox read-only` for hard limits |
| OpenCode | OpenRouter via `opencode.json` | Terminal-only, named agents with denied tools | Tool-level: `ask`, `plan`, and `reviewer` deny `edit`, `write`, `patch`, `bash`, `task` |

Notes:

- "OpenAI" in this setup means Codex, OpenAI's coding-agent CLI. This
  repository routes Codex through OpenRouter. Pointing Codex at OpenAI
  directly is a provider change in `agent-config/config.toml`, followed by
  `./scripts/install.sh`; it is not covered here.
- Copilot is a separate service and is never routed through OpenRouter.

### Codex

| Purpose | Path |
| --- | --- |
| Global instructions | `~/.codex/AGENTS.md` (symlink to `agent-config/AGENTS.md`) |
| Settings and OpenRouter configuration | `~/.codex/config.toml` (rendered, not a symlink; see below) |
| Command rules | `~/.codex/rules/` |
| User skills | `~/.agents/skills/<name>/SKILL.md` |
| Repository instructions | `AGENTS.md` from the repository root to the working directory |
| Repository skills | `.agents/skills/<name>/SKILL.md`, discovered from the working directory up to the repository root |

`~/.codex/config.toml` is rendered fresh on every install: the Codex base
config from `agent-config/config.toml`, plus a trusted-project entry for
`~/github` and every Git worktree found beneath it, plus any machine-local
`notify`/`marketplaces`/`plugins`/`notice`/`hooks.state`/
`mcp_servers.node_repl`/`shell_environment_policy.set` state your existing
file already had (this installer does not manage or overwrite that state).

```bash
codex                                   # interactive TUI via OpenRouter
codex --model <id>                      # override the OpenRouter model
codex --sandbox read-only               # hard no-edit session, useful for $plan
codex review --uncommitted              # built-in review gate
codex plugin marketplace add <src>      # declared in agent-config/plugins.toml
codex plugin add <name>@<marketplace>   # declared in agent-config/plugins.toml
```

Codex has no native concept of a named, tool-restricted subagent. `plan`,
`build`, and `reviewer` are ordinary skills for Codex; invoke one by name (for
example `$plan`) and Codex follows that skill's boundaries by instruction only.

### OpenCode

OpenCode (opencode.ai) is a separate terminal coding-agent CLI. Install it with
its own installer (not managed by this repository):

```bash
curl -fsSL https://opencode.ai/install | bash
```

This installs the binary to `~/.opencode/bin/opencode` and adds that directory
to `PATH` in your shell's rc file.

| Purpose | Path |
| --- | --- |
| Default model/provider | `$OPENCODE_HOME/opencode.json` (symlink to `agent-config/opencode.config.json`) |
| V2 TUI keybindings | `$OPENCODE_HOME/cli.json` (symlink to `agent-config/opencode.cli.json`) |
| Subagents | `$OPENCODE_HOME/agent/<name>.md`, rendered from `.agents/skills/<name>/SKILL.md` plus `agent-config/subagents/<name>.config.json` |

`OPENCODE_HOME` defaults to `~/.config/opencode`; it is this installer's own
override variable (mirroring `CODEX_HOME`/`COPILOT_HOME`), not something
OpenCode itself reads. OpenCode picks up `OPENROUTER_API_KEY` from the
environment the same way Codex does. OpenCode v2 reads TUI keybindings from
`cli.json` rather than `opencode.json`; the managed file binds Return to prompt
submission and Tab/Shift+Tab to forward/reverse agent cycling.

```bash
opencode                          # interactive TUI, configured default model
opencode run "<message>"          # one-shot, non-interactive
opencode run --agent plan "<msg>" # one-shot with a named agent
opencode debug agents             # list agents and resolved permissions
opencode debug config             # show the fully resolved configuration
```

Every custom agent under `$OPENCODE_HOME/agent/*.md` is merged into the `agent`
key of the resolved config automatically. `build` and `plan` use mode `all`
because those names also identify OpenCode's built-in primary agents; making
either subagent-only removes it from the TUI's primary-agent list. `reviewer`
uses mode `subagent`. `plan` and `reviewer` deny `edit`, `write`, `patch`,
`bash` (no file writes or commands) and `task` (cannot invoke other
subagents); `build` has no restrictions, so it can call `plan` when a task has
no plan yet.

### VS Code Copilot

| Purpose | Path |
| --- | --- |
| Repository instructions (this repo only) | `.github/copilot-instructions.md` |
| Custom agent: repository Q&A | `~/.copilot/agents/getkan-ai.agent.md` |
| Custom agent: control/config | `~/.copilot/agents/control-ai.agent.md` |
| Subagents | `~/.copilot/agents/<name>.agent.md` for `plan`, `build`, `reviewer` |
| Skills | `~/.copilot/skills/<name>/SKILL.md` |

`COPILOT_HOME` (default `~/.copilot`) overrides the install location. Each
custom agent file has YAML front matter:

```yaml
---
description: "..."
name: "plan"
tools: [read, search, todo]
user-invocable: true
---
```

`plan` and `reviewer` have only `read`, `search`, and `todo`, so VS Code will
not offer file-editing or command actions while either is selected. `build`
adds `edit`, `execute`, and `agent` (so it can invoke the `plan` agent). To use
one, open Copilot Chat, open the agent picker, and select `plan`, `build`,
`reviewer`, `getkan-ai`, or `control-ai` by name.

### Changing a subagent

1. Edit the shared prompt body in `.agents/skills/<name>/SKILL.md`, and/or its
   permissions in `agent-config/subagents/<name>.config.json` (`mode`,
   `copilotTools`, `opencodeDeniedTools`).
2. Rerun `./scripts/install.sh`.
3. Restart Codex, OpenCode, or VS Code to pick up the change.

Do not hand-edit a rendered `~/.copilot/agents/*.agent.md` or
`~/.config/opencode/agent/*.md` file; the next install overwrites it.

## 3. The plan / build / reviewer loop

1. **`plan`** investigates the task and returns a phased plan. It never edits
   a file.
2. **`build`** implements one authorized phase at a time, adds
   feature-specific tests, and runs focused validation after each phase. If no
   plan exists yet, it produces one first (calling `plan`, where the client
   supports that). For features, it follows `project`: pause for
   stage approval and after each validated unit for the commit checkpoint.
3. **`reviewer`** inspects the resulting diff and reports defects, false
   positives, and the complete validation commands for you or the parent agent
   to run. It never edits a file or runs commands.

Each step matches a skill in `.agents/skills/<name>/SKILL.md`; read that file
for the exact boundaries and output format.

### In VS Code Copilot

1. Select the `plan` agent and describe the task. Review the phased plan.
2. Switch to `build` to implement approved phases (or ask `build` directly; it
   can invoke `plan` itself).
3. Switch to `reviewer` and ask it to review the branch. Run the validation
   commands it reports.
4. Address defects with `build`, then ask `reviewer` again until it reports no
   actionable findings.

### In Codex

```text
$plan     Describe the task; read the returned plan before continuing.
$build    Implement the approved plan and its tests.
$reviewer Review the resulting diff and report validation commands.
```

The no-edit boundary for `$plan` and `$reviewer` is instruction-only. For a
hard guarantee, run `$plan` in `codex --sandbox read-only` or review its
response before authorizing any edit.

### In OpenCode

1. Start with `opencode run --agent plan "<task>"` (or switch agents inside the
   TUI).
2. Once you approve the plan, switch to `--agent build`.
3. Switch to `--agent reviewer` to inspect the diff and get the validation
   commands.
4. Confirm resolved permissions with `opencode debug agents`.

## 4. Suggested VS Code workflow

### One-time setup

1. Clone repositories under `~/github` so the installer trusts them for Codex.
2. Install and reload the shell:

   ```bash
   cp .env.example .env   # first time only; add the key
   ./scripts/install.sh
   source "${ZDOTDIR:-$HOME}/.zshrc"
   ```

3. Restart VS Code. In Copilot Chat, confirm the agent picker lists `plan`,
   `build`, `reviewer`, `getkan-ai`, and `control-ai`.
4. In each project, create or adopt `AGENTS.md` and locate and reuse the existing
   SPEC, ROADMAP, and TASKS at their actual paths with `$project`
   (Codex), or ask the `getkan-ai` agent to use that skill. Create missing
   planning documents under `docs/` unless repository instructions specify
   otherwise; do not create competing copies of existing documents.

### Window layout

- Editor area: code and diffs.
- Secondary side bar: Copilot Chat.
- Integrated terminal, split into:
  - Terminal 1: `codex` or `opencode` for terminal-based agent work.
  - Terminal 2: the dev server or watcher (see the `watch` skill).
  - Terminal 3: tests, `git status`, `git diff`.

This three-terminal split maps directly onto tmux windows later, which keeps
the migration in section 5 mechanical.

### Daily loop

1. **Orient.** Ask the `getkan-ai` agent, "What is the current phase and the
   next open task?" It answers from TASKS and ROADMAP at the project's actual
   document locations.
2. **Branch.** `git switch -c <type>/<short-name>`.
3. **Plan.** Select `plan` and describe the task with acceptance criteria.
   Read the phased plan. Correct it before approving.
4. **Build.** Select `build` for the approved lifecycle stage and user-selected
   session tasks. Review each unit's diff and validation. At its commit
   reminder, commit or explicitly instruct continuation without committing.
   Approve each next lifecycle stage separately.
5. **Review.** Select `reviewer`. It inspects the feature against its base,
   including committed tasks and current changes, and reports defects and
   validation commands. Run them in Terminal 3.
6. **Codex review gate.** In Terminal 1, run `codex review --uncommitted` and
   follow the review loop in section 6.
7. **Record.** Update TASKS after stage-specific criteria pass. Stage 2
   expected-red integration tests require explicit evidence, not a claim of
   feature completion.
8. **Publish.** Commit, push, and open a ready-for-review pull request using
   the repository template, only when you decide the work is ready.

### When to use which harness inside VS Code

- Inline completion and small edits: Copilot inline suggestions.
- Multi-file feature with visual diff review and hard no-edit planning:
  Copilot Chat with `plan` -> `build` -> `reviewer`.
- Large refactor, long autonomous run, or a cheaper or different model:
  `codex` or `opencode` in the integrated terminal while you keep editing.
- Terminal-only work with hard no-edit planning: OpenCode.
- Final pre-commit gate: always `codex review --uncommitted`.

## 5. Migrating to Neovim with tmux

The goal is to move the editor without changing the AI workflow. Skills,
`AGENTS.md`, and the `plan` / `build` / `reviewer` loop stay the same; only
the surface changes. Migrate in stages and keep VS Code available until each
stage feels routine.

### Stage 0: tmux around VS Code

Start using tmux for terminals while VS Code is still the editor.

Minimal `~/.tmux.conf`:

```tmux
set -g prefix C-a
unbind C-b
bind C-a send-prefix

set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 50000
set -sg escape-time 10
set -g focus-events on
set -g default-terminal "tmux-256color"
set -as terminal-features ",*:RGB"
setw -g mode-keys vi

bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind r source-file ~/.tmux.conf \; display "reloaded"
```

`escape-time` and `focus-events` matter later for Neovim responsiveness and
autoread.

Exit criterion: you run agents, dev servers, and tests in tmux by habit.

### Stage 1: agents live in tmux

Move all terminal agents out of the VS Code terminal and into a standard tmux
session per project. A small launcher keeps every project identical:

```bash
#!/usr/bin/env bash
# ~/bin/dev: open or attach to a per-project tmux workspace.
set -euo pipefail

dir="$(cd "${1:-.}" && pwd)"
name="$(basename "$dir" | tr . _)"

if ! tmux has-session -t "$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -n edit -c "$dir"
  tmux new-window -t "$name" -n agent -c "$dir"
  tmux new-window -t "$name" -n run -c "$dir"
  tmux split-window -t "$name:run" -h -c "$dir"
  tmux new-window -t "$name" -n git -c "$dir"
  tmux select-window -t "$name:edit"
fi

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$name"
else
  tmux attach -t "$name"
fi
```

| Window | Contents |
| --- | --- |
| `edit` | Editor (`code .` now, `nvim` later) |
| `agent` | `codex` or `opencode` sessions; one pane per parallel task |
| `run` | Left: dev server or watcher. Right: tests |
| `git` | `git status`, `git diff`, `lazygit`, `gh pr` |

Exit criterion: VS Code is only used for editing and Copilot Chat.

### Stage 2: Neovim for reading and review

Install Neovim and use it in the `edit` window for reading code and reviewing
agent diffs, while VS Code remains the place you write code.

Suggested minimal plugin set (managed with `lazy.nvim`):

| Need | Plugin |
| --- | --- |
| Plugin manager | `folke/lazy.nvim` |
| LSP | `neovim/nvim-lspconfig` with `mason.nvim` |
| Fuzzy find | `nvim-telescope/telescope.nvim` or `ibhagwan/fzf-lua` |
| Syntax | `nvim-treesitter/nvim-treesitter` |
| Git signs and hunks | `lewis6991/gitsigns.nvim` |
| Reviewing agent diffs | `sindrets/diffview.nvim` |
| Pane navigation shared with tmux | `christoomey/vim-tmux-navigator` |
| Copilot completions | `github/copilot.vim` or `zbirenbaum/copilot.lua` |
| Copilot chat (optional) | `CopilotC-Nvim/CopilotChat.nvim` |

Settings that matter when agents edit files under you:

```lua
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})
```

Review an agent's work with `:DiffviewOpen` (working tree vs `HEAD`) and stage
or revert hunks with gitsigns.

Exit criterion: you review every agent diff in Neovim instead of the VS Code
Source Control view.

### Stage 3: Neovim as the primary editor

Write code in Neovim. VS Code becomes optional, kept for browser-based UI
verification and Copilot Chat agent-picker workflows if you still want them.

What changes for the AI harness:

- **Copilot custom agents.** The `ask`, `plan`, `build`, and `reviewer` agents in
  `~/.copilot/agents/` are a VS Code Copilot Chat feature. Neovim Copilot
  plugins provide completions and chat, but do not load those agent files.
  In a terminal, use the GitHub Copilot CLI (`copilot`) if it is installed
  and supports custom agents in your version, or use the next two options.
- **Codex** becomes the main harness. Invoke `$ask` for read-only questions,
  `$plan`, `$build`, and `$reviewer` as skills in the `agent` window. Run
  planning with `codex --sandbox read-only` when you want a hard no-edit
  guarantee.
- **OpenCode** provides the tool-enforced `ask` / `plan` / `build` / `reviewer`
  agents from the terminal.
- **Review gate** is unchanged: `codex review --uncommitted`.

Final layout per project:

```text
session <project>
  1:edit   nvim
  2:agent  [codex: feature] | [opencode: reviewer]
  3:run    [dev server]     | [tests]
  4:git    lazygit / gh
```

Useful tmux habits for agent work:

- One `agent` pane per independent task. Name panes with
  `tmux select-pane -T <task>` so you can find them.
- Use `prefix [` (copy mode, vi keys) to copy agent output into Neovim.
- Run parallel agents on separate Git worktrees (`git worktree add
  ../<repo>-<task> -b <branch>`) and give each worktree its own tmux session
  with `dev ../<repo>-<task>`. Rerun `./scripts/install.sh` if the worktree is
  under `~/github` so Codex trusts it.

Exit criterion: a full task from `plan` to pull request without opening
VS Code.

## 6. Complete lifecycle

### Four-stage feature development

The `project` skill defines the cross-project contract. These stages
apply to feature development, not every maintenance edit. Keep planning-only
requests and the `plan`/`reviewer` agents read-only: propose changes rather than
creating documents or skeletons. Authorized editing is a separate action mode.

1. **Understanding the problem.** Establish functional/nonfunctional
   requirements, environmental constraints, datastore needs, non-goals, and
   measurable success in SPEC. Reuse the existing SPEC; if absent, investigate
   the codebase and record its environment concisely, citing evidence and
   unknowns without reading secrets. For new projects, decide language,
   framework, datastore, environment, and deployment before scaffolding.
   Define new packages/services here. Update SPEC and ROADMAP. For complex
   projects, identify subprojects as roadmap delivery stages with dependencies
   and repeat the lifecycle for each. **Stop for stage 2 approval.**
2. **High-level design and implementation.** Define components, data flow,
   tables, classes, method contracts, and end-to-end acceptance criteria.
   Update SPEC/ROADMAP and create high-level TASKS. Use standard scaffolding
   tools, structural model files, interfaces, and explicit stubs; do not
   implement full business logic or detailed SQL/method behavior. Create
   deterministic seed fixtures and executable integration tests before detailed
   implementation. Run them and record expected failures from stubs. These
   failures are acceptable at this stage; broken test infrastructure or
   unrelated regressions are not. Do not disable assertions or bypass commit/CI
   policy. **Stop for stage 3 approval.**
3. **Detailed design and implementation.** The user selects work-session
   tasks. Refine detailed SQL and methods, implement one reviewable unit at a
   time, and write unit tests alongside each step. Run focused unit/integration
   checks and record evidence and approved design changes. After each validated
   unit, **remind the user to commit and stop before the next task**. Resume
   after a confirmed commit or explicit instruction to continue without one.
   Never stage or commit implicitly. When feature scope and checks are complete,
   **stop for stage 4 approval.**
4. **Review and pull-request preparation.** Review the entire feature against
   its verified base, including committed work and current changes. Run complete
   relevant validation, integration tests, and required review gates. Resolve
   findings, check SPEC/ROADMAP/TASKS coverage, and prepare PR evidence using the
   repository template. Stage 2 expected failures do not excuse final failures.
   **Stop for handoff; publishing requires explicit authorization.**

A roadmap delivery outcome may span all four lifecycle stages. A session task
is a smaller selected unit within stage 3. Each feature/project repeats all four
stages independently. ROADMAP keeps an index and a lifecycle record per entry,
retaining completed features while new ones start; concurrent features may be
at different stages. Link SPEC requirements and TASKS evidence with the same
feature/project ID. Scope approvals, blockers, expected-red baselines, and
commit checkpoints to that entry, not a global project stage. Before acting,
identify the user-selected feature and preserve other entries; track shared
interfaces and cross-feature dependencies explicitly. Concurrent entries do not
authorize extra work or parallel agents.

Do not infer stage approval from a
broad feature request, or permission to provision, migrate production data, or
deploy from a technology decision.

### Validation and publication gates

The following checks support the lifecycle above; they do not authorize
crossing its stage or task checkpoints.

1. Install this repository's shared instructions, configuration, rules, and
   reusable skills for each client.
2. Inspect the real repository, branch, worktree, architecture, runtime paths,
   and existing validation.
3. Put repository maintenance conventions and boundaries in `AGENTS.md`.
4. Define observable requirements, non-goals, and acceptance criteria in
   `SPEC.md`.
5. Order outcomes, risks, exit criteria, and validation in `ROADMAP.md`.
6. Break the current phase into reviewable work in `TASKS.md`.
7. Use `plan` (or `$project`) to produce a requirement-linked plan
   with automated and manual validation.
8. For features, stop for approval at every lifecycle stage transition.
9. Implement one approved phase with `build`, run focused checks, and inspect
   the diff.
10. Run `reviewer` and the complete local gate for final readiness. Record
    stage-specific task evidence, including the limited stage 2 exception above.
11. Run the built-in Codex review:

    ```bash
    codex review --uncommitted
    ```

    When tasks have already been committed, also review the whole feature:

    ```bash
    codex review --base <verified-base>
    ```

    Inspect committed changes plus staged/unstaged and relevant untracked
    files; an empty uncommitted diff is not a completed feature review.

12. Verify every finding against the current diff. Fix only actionable
    defects, rerun affected validation, and repeat `codex review --uncommitted`
    until no actionable findings remain. Document verified false positives
    without changing correct code. A review-mode Codex instance reports
    findings directly and must not launch another nested review.
13. Commit the focused change, push it, and open a ready-for-review pull
    request only when authorized. Create or leave a draft only when the user
    explicitly requests one. If known gates remain, stop before opening the
    pull request and report the blockers.
14. Require a completed Codex review loop, CI validation, applicable security
    checks, and a fresh independent review on the latest commit.
15. Fix or explain every review item, resolve completed threads, and repeat the
    checks after every push.
16. Complete and document required manual testing on the real target
    environment.
17. Merge only after the final diff, planning documents, CI, security checks,
    reviews, threads, and manual tests are clean.

### Security baseline

Establish the security checks that apply to the repository instead of adding
irrelevant gates:

- Enable secret scanning and push protection where available.
- Configure Dependabot for every package ecosystem and GitHub Actions.
- Run dependency review when dependency manifests can change.
- Configure CodeQL for every language in the repository that CodeQL supports.
- Document accepted exceptions with a reason, owner, and review date.

### Required pull request evidence

Record the problem, approach, important decisions, exact automated checks,
manual tests, screenshots for visible changes, limitations, skipped validation,
and follow-up work.

### Documentation rule

Do not rely on a coding agent discovering arbitrary documents by filename.
Reference supporting documents from `AGENTS.md`, a selected skill, or the task
prompt. Keep the specification, roadmap, tasks, and implementation
synchronized when requirements or architecture change.

## 7. Sample workflows

Each workflow lists the harness steps and the editor surface. Replace bracketed
text. Prompts are written for Copilot Chat agents; for Codex, prefix with
`$plan`, `$build`, or `$reviewer`; for OpenCode, use
`opencode run --agent plan|build|reviewer`.

### 7.1 Build a new controller

Example: a REST controller for an `orders` resource in an existing service.

1. Branch: `git switch -c feat/orders-controller`.
2. `plan`:

   ```text
   Plan a new orders controller with list, get, create, and update
   endpoints. Follow the routing, validation, error handling, and auth
   patterns of the existing [users] controller. Identify the service and
   repository layers it should call, the request/response schemas, and the
   test files to add. Do not edit files.
   ```

   Check the plan names a concrete existing controller to mirror, the routes,
   status codes, and the test command.
3. Use `project` with `build`, pausing for approval between stages:
   - Stage 1: use the service's SPEC or investigate its environment if missing;
     record controller requirements and integration choices.
   - Stage 2: define DTOs/contracts, controller/service skeletons, seed orders,
     and an executable integration test through the router. Record expected
     failures before implementing behavior.
   - Stage 3: implement user-selected controller/service tasks with unit tests
     alongside each step. Validate each unit, remind the user to commit, and
     pause before the next task.
4. Run the service in the `run` window and exercise one endpoint with `curl`
   to confirm wiring, not just tests.
5. After stage 4 approval, `reviewer`, then `codex review --uncommitted` and
   `codex review --base <verified-base>` for already committed feature tasks.
6. Update API docs or OpenAPI spec if the project keeps one.

### 7.2 Create a new microservice

1. Use `project` for stage 1: decide language/framework, datastore,
   deployment environment, authentication, callers, constraints, and measurable
   success with the user. Record SPEC and ROADMAP before scaffolding; pause
   for stage 2 approval.
2. Create the repository under `~/github`, then run `./scripts/install.sh`
   from this repository so Codex trusts it.
3. Bootstrap planning documents with `$project` (Codex) or the
   `project` skill (Copilot): `AGENTS.md`, `docs/SPEC.md`,
   `docs/ROADMAP.md`, `docs/TASKS.md`.
4. `plan`:

   ```text
   Plan stage 2 from docs/SPEC.md: a skeleton using the official generator,
   contracts/stubs for health and readiness, logging and configuration,
   a Dockerfile, test harness, seed fixtures, integration tests, and CI.
   Defer full endpoint behavior to stage 3. List exact validation commands
   and expected failures from unimplemented behavior. Do not edit files.
   ```

5. `build` stage 2 within approved scope. Prefer the framework's scaffolding
   command over hand-written boilerplate. Run integration tests and record
   the skeleton baseline; pause for stage 3 approval.
6. Implement user-selected stage 3 tasks with unit tests alongside each step
   and commit reminders between tasks. Verify implemented behavior for real:
   build the container, run it, and `curl` the health endpoint.
7. Add `.github/workflows`, Dependabot, and CodeQL per the security baseline in
   section 6.
8. After stage 4 approval, review the whole feature and prepare PR evidence.
   Later subprojects (domain endpoint, persistence, messaging) repeat the
   lifecycle with their own approval gates.

tmux tip: run `docker compose up` or the dev server in `run:left`, tests in
`run:right`, and the agent in `agent`.

### 7.3 Fix a bug

1. Reproduce first. Capture the failing command, request, or log.
2. `plan` (or the `deep` skill for subtle bugs):

   ```text
   Diagnose this failure: [error, stack trace, reproduction]. Identify the
   root cause with file and line evidence, and propose a fix plus a
   regression test that fails before the fix. Do not edit files.
   ```

3. `build`: add the failing regression test first, confirm it fails, then
   apply the fix and confirm it passes.
4. `reviewer`, then `codex review --uncommitted`.

### 7.4 Frontend or UI change

For a new UI feature, follow the four-stage lifecycle in section 6: requirements
and approval; component contracts/skeletons, seed fixtures and integration
tests and approval; user-selected implementation tasks with unit tests and
commit checkpoints; approval for feature-wide review and PR preparation.
The following editor/browser steps support that lifecycle, not bypass it.

1. Start the dev server in `run:left` with the `watch` skill.
2. `plan` the change, naming components, styles, and states (empty, loading,
   error).
3. `build` with the relevant skill (`react`, `vue`, `svelte`, `css`,
   `tailwind`).
4. Verify in a real browser with the `playwrite` skill, or Copilot browser
   tools in VS Code. Capture screenshots for the pull request.
5. `reviewer`, then `codex review --uncommitted`.

UI verification is the main reason to keep VS Code installed after the Neovim
migration.

### 7.5 Refactor without behavior change

1. Confirm the existing tests cover the code you will move. If not, add
   characterization tests in a separate first commit.
2. `plan` the refactor as small, independently passing phases.
3. Prefer language tooling (LSP rename, `pylance-refactoring`, codemods) over
   free-form agent edits.
4. Run the full test suite after every phase, not just at the end.
5. `reviewer` should confirm no public API or behavior changed.

### 7.6 Dependency or runtime upgrade

1. `plan`: read the upstream changelog and migration guide, list breaking
   changes that affect this codebase, and the files involved.
2. `build`: change the manifest with the package manager, regenerate the
   lockfile, then fix call sites.
3. For Python version changes, use `add-python-version-support` or
   `drop-python-version-support`.
4. Run the full suite, the build, and a real start of the application.

### 7.7 Review someone else's pull request

1. `gh pr checkout <number>` in the `git` window.
2. `reviewer`: "Review this branch against `main`; report defects with file
   and line evidence and the validation commands to run."
3. Run the reported commands. Read the diff yourself in `:DiffviewOpen main`
   or the VS Code diff view.
4. Post comments with `gh pr review` only after you have verified each
   finding.

### 7.8 Add or change a skill in this repository

1. Use the `create-skill` skill to draft `.agents/skills/<name>/SKILL.md`.
2. Update the skill list in [SKILLS.md](SKILLS.md); `./scripts/validate.sh`
   checks that it matches `.agents/skills`.
3. Run `./scripts/install.sh`, restart the clients, and confirm the skill is
   discovered.
4. Run `./scripts/validate.sh`, then `codex review --uncommitted`.

### 7.9 Capture what you learned

- Use the `learn` skill to add a narrow rule to `agent-config/AGENTS.md` or a
  skill when an agent repeats a mistake. Keep `agent-config/CLAUDE.md` aligned
  whenever shared global guidance changes.
- Use the `take-note` skill to save a useful question and answer for later.

## 8. Quick reference

| Action | VS Code | Neovim + tmux |
| --- | --- | --- |
| Open project workspace | `code .` | `dev .` |
| Plan | Copilot Chat -> `plan` | `codex` -> `$plan` or `opencode run --agent plan` |
| Implement | Copilot Chat -> `build` | `codex` -> `$build` or `opencode run --agent build` |
| Review | Copilot Chat -> `reviewer` | `codex` -> `$reviewer` or `opencode run --agent reviewer` |
| Review gate | `codex review --uncommitted` | same |
| Inspect diff | Source Control view | `:DiffviewOpen` |
| Run dev server | integrated terminal | `run` window, left pane |
| Run tests | integrated terminal | `run` window, right pane |
| Validate this repository | `./scripts/validate.sh` | same |
| Inspect OpenCode agents | - | `opencode debug agents` |
