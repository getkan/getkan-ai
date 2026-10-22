# Introduction to GitHub Copilot in VS Code

GitHub Copilot is GitHub's AI assistant. In VS Code it provides inline code
suggestions, a chat panel, and an agent mode that can read the workspace, edit
files, and run commands. This repository installs custom agents and skills for
Copilot so it follows the same instructions and workflow as Codex and
OpenCode.

Copilot is a separate service from Codex and OpenRouter. It uses GitHub's
model access and your GitHub Copilot subscription; it is never routed through
OpenRouter.

For the shared workflow across clients, read
[EDITOR_WORKFLOW.md](EDITOR_WORKFLOW.md). For general agent concepts, read
[CODEX_INTRODUCTION.md](CODEX_INTRODUCTION.md); most of it applies to Copilot
agent mode as well. Use the editor workflow as the source for setup and
operational procedures.

## The Copilot surfaces

| Surface | What it does | Best for |
| --- | --- | --- |
| Inline suggestions | Ghost-text completions as you type | Finishing lines, boilerplate, tests that follow a pattern |
| Next edit suggestions | Predicts the next related edit elsewhere in the file | Repetitive follow-on edits after a change |
| Chat (ask) | Answers questions about code with workspace context | Explaining code, finding where something happens |
| Agent mode | Plans, edits multiple files, runs terminal commands, iterates on errors | Multi-file features and fixes |
| Custom agents | Named agents with their own instructions and tool list | Enforcing the `plan` / `build` / `reviewer` boundaries |
| Inline chat | Chat scoped to a selection in the editor | Small, local rewrites |

Feature names and menus change between VS Code releases. If something below
does not match your version, check the VS Code Copilot documentation.

## What this repository installs for Copilot

| Item | Location | Purpose |
| --- | --- | --- |
| Repository instructions | `.github/copilot-instructions.md` | Applied automatically when this repository is open |
| `getkan-ai` agent | `~/.copilot/agents/getkan-ai.agent.md` | Answers setup, workflow, and task-status questions from repository markdown |
| `control-ai` agent | `~/.copilot/agents/control-ai.agent.md` | Configuration and control tasks |
| `plan`, `build`, `reviewer` agents | `~/.copilot/agents/<name>.agent.md` | The plan, implement, review loop with tool-level limits |
| Skills | `~/.copilot/skills/<name>/SKILL.md` | Reusable workflows shared with Codex and OpenCode |

`plan` and `reviewer` only have `read`, `search`, and `todo` tools, so they
cannot edit files or run commands. `build` adds `edit`, `execute`, and
`agent`. This is enforced by VS Code, not just by instructions, which makes
Copilot the strictest client for the planning and review steps.

After changing a skill or `agent-config/subagents/<name>.config.json`, rerun
`./scripts/install.sh` and restart VS Code. Do not hand-edit files in
`~/.copilot/agents/`; the installer overwrites them.

## Getting started

1. Sign in to GitHub in VS Code and confirm Copilot is active in the status
   bar.
2. Follow the [editor workflow](EDITOR_WORKFLOW.md) to install the shared
   configuration, then restart VS Code.
3. Open Copilot Chat and confirm `plan`, `build`,
   `reviewer`, `getkan-ai`, and `control-ai` are listed.
4. Select `getkan-ai` and ask: "What is the current phase and the next open
   task?" A working install answers from `docs/TASKS.md` and
   `docs/ROADMAP.md` and names those files.

## Tips for getting the best results

### Pick the right surface

- Typing code you already understand: inline suggestions. Accept word by word
  when a suggestion is only partly right instead of accepting and editing.
- A question: chat. Do not use agent mode to answer questions; it costs more
  and may edit files.
- For changes and review procedures, follow the
  [editor workflow](EDITOR_WORKFLOW.md).

### Give chat the right context

- Open or reference the files that matter. Attach files, folders, symbols, or
  selections with `#` references or the attach-context button instead of
  pasting code.
- Use workspace-wide search context only when you do not know where the code
  lives; targeted files give better answers.
- Paste the exact error text or failing test name rather than describing it.

### Steer inline suggestions with code

Inline suggestions read the surrounding file and open tabs. Improve them by:

- Writing a clear function name and signature, or a short comment stating
  intent, before the body.
- Keeping related files open in other tabs, for example the interface you are
  implementing or an existing test to mirror.
- Closing unrelated tabs that may pull suggestions in the wrong direction.

### Use the plan, build, reviewer loop for real changes

Use the [editor workflow](EDITOR_WORKFLOW.md) for the plan/build/reviewer
procedure and review gates.

### Review agent-mode tool calls

Agent mode asks before running terminal commands unless you have approved
them automatically. Read each command before allowing it, especially anything
that deletes files, changes Git history, or reaches the network. Keep
auto-approval narrow.

### Use checkpoints and Git

Commit or stash a known-good state before a large agent-mode task. If the
agent goes in the wrong direction, use the chat's undo or checkpoint restore,
or `git diff` and `git restore` specific files. Do not rely on memory of what
changed.

### Choose the model deliberately

The chat model picker offers several models. Faster models suit explanation
and small edits; stronger reasoning models suit planning, debugging, and
review. Some models consume premium requests from your plan's monthly
allowance, so use them where they matter.

### Keep instructions short and scoped

`.github/copilot-instructions.md` is added to every chat request in this
repository. Keep it to rules that apply to every task and point to `AGENTS.md`
and the docs for detail. For rules that apply only to some files, VS Code
supports `*.instructions.md` files with an `applyTo` glob, and reusable
prompts in `*.prompt.md` files. Add those only when a real repeated need
exists.

### Start new chats for new tasks

Long chats carry stale context and cost more per turn. Start a new chat when
the task changes, and restate the goal and acceptance criteria.

## Copilot compared with Codex and OpenCode

| Need | Best choice |
| --- | --- |
| Inline completions while typing | Copilot |
| Visual diff review and hard no-edit `plan` / `reviewer` | Copilot |
| Browser-based UI verification inside the editor | Copilot |
| OpenRouter models or a specific non-Copilot model | Codex or OpenCode |
| Built-in uncommitted-change review gate | Codex (`codex review --uncommitted`) |
| Terminal-only work in tmux and Neovim | Codex or OpenCode |

The workflows share source material but retain client-specific instruction
discovery, tools, and permissions. See
[EDITOR_WORKFLOW.md](EDITOR_WORKFLOW.md) for how to combine them.

## Security and privacy

- Code and context you send to Copilot are processed by GitHub's service under
  your account's Copilot policies. Review those settings if your code has
  confidentiality requirements.
- Do not attach or paste `.env`, credentials, or private keys into chat.
- Treat suggestions that add dependencies, network calls, or shell commands
  with the same review you would give a pull request from a stranger.
- Public-code matching and other policy settings are managed in your GitHub
  Copilot settings, not in this repository.

## Common problems

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Custom agents missing from the picker | Installer not run or VS Code not restarted | Run `./scripts/install.sh`, restart VS Code |
| `plan` cannot edit a file | Working as intended | Switch to `build` for edits |
| Agent ignores repository rules | Instructions too long or not referenced | Keep `.github/copilot-instructions.md` short and point to `AGENTS.md` |
| Suggestions do not match project style | Missing context | Open a representative file in another tab or add a short intent comment |
| Agent edited a rendered agent file and it reverted | Installer regenerates `~/.copilot/agents/` | Edit the source skill or subagent config, then reinstall |

## Checklist

- The right surface was used: inline, chat, agent, or a custom agent.
- Context came from attached files or symbols, not long pasted blocks.
- Larger changes went through `plan`, `build`, and `reviewer`.
- Follow the validation and review gates in the
  [editor workflow](EDITOR_WORKFLOW.md).
- No secrets were attached to chat or entered tracked files.
