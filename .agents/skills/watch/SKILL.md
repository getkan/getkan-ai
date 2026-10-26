---
name: watch
description: "G-AI: Run a local development watch command (for example `npm run dev`, `vite`, `cargo watch`, `pytest --watch`) in a dedicated background terminal and monitor its output. Restart the process up to three times if it exits or crashes, then ask the user before continuing. Trigger on requests to start, watch, monitor, or keep a dev server or watcher running."
---

# watch

## Inputs

- `command`: the watch command to run. If the user did not give one, read the
  project manifest (`package.json`, `Makefile`, `Cargo.toml`, `pyproject.toml`)
  and propose the most likely dev/watch script before starting.
- `cwd`: the directory the command must run in. Default to the workspace root
  of the project that owns the manifest.

## Commands

- `/watch stop`: stop the current watch session immediately. Kill the tracked
  terminal id, do not restart the process, and confirm whether it stopped.
- `/watch restart`: stop the current watch session, then start the same command
  and working directory in a new dedicated terminal. Reset the failed-restart
  count and report the new terminal id and startup output.
- If no watch session is active, report that there is nothing to stop or
  restart.

## Workflow

1. Handle `/watch stop` and `/watch restart` before normal start, observation,
  or failure-restart logic. Use only the tracked terminal id for the current
  watch session.
2. Confirm the command and working directory. Do not guess a script name that
   is not defined in the project.
3. Start the command in async mode in a new dedicated terminal so VS Code can
  keep the ongoing process visible while other work continues. Record the
  returned terminal id and use only that id for this watch session.
4. Report the terminal id as the live terminal reference in the conversation,
  along with the command, working directory, and any startup URL or port that
  appears in the initial output.
5. Observe output only when there is a reason to: the user asks about the
   watcher, the terminal reports completion or needing input, or a task depends
   on the watcher's current state. Do not poll on a timer and do not run
   `sleep` to wait.
6. When the process exits or crashes, restart it with the same command, cwd,
   and async mode. Track the restart count for this session.
7. After three failed restarts, stop restarting. Report the exit codes and the
   final error output, then ask the user whether to keep retrying, change the
   command, or stop.
8. When the user is done, kill the terminal for this watch session and confirm
   it is stopped.

## Error handling policy

- Do not continuously read, poll, summarize, or analyze watch output. Consume
  output only when the user requests it or VS Code reports that the terminal
  completed, crashed, or needs input.
- Report that an error occurred, with a one-line summary and the terminal id.
- Do not diagnose, edit files, or attempt fixes for errors printed by the
  watcher unless the user explicitly asks for a specific error to be addressed.
- A compile, type, lint, or test error inside the watcher output is not a
  process failure. Leave the process running and take no action.
- Only the process exiting or failing to start counts toward the restart limit.
- A `/watch stop` request is an intentional shutdown and must never count as a
  failed restart or trigger another start.
- A `/watch restart` request is an intentional restart: kill the tracked
  terminal, reset the failed-restart count, and start exactly one new session.
- When the user asks about a specific error, read the relevant terminal output,
  locate the source, and fix only that issue.

## Safety rules

- Never start a watcher without the user's command or an explicitly confirmed
  proposal.
- Keep the async terminal visible and associated with the conversation for the
  lifetime of the watch session whenever VS Code supports it.
- Never run more than one watch session for the same command and cwd. Reuse or
  kill the existing terminal first.
- Never pipe the watch command through `tail`, `head`, `grep`, or `rtk`; that
  hides prompts and breaks idle detection. Filter output after reading it
  instead.
- Never modify project files as a side effect of starting or restarting the
  watcher.
- Never bypass failing checks (for example `--no-verify` or disabling type
  checks) to make the watcher start.

## Validation

- The watch process is running under a known terminal id, or the user has been
  told exactly why it is not.
- Restart attempts stopped at three and the user was asked before any fourth
  attempt.
- Watch output was not consumed continuously; errors were investigated only at
  the user's request or after a terminal state-change notification.
- No source files were changed except ones the user explicitly asked to fix.
