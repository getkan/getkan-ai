# Token Optimization for AI Coding Agents

Token optimization is the practice of reducing unnecessary model input and output while preserving the information needed to produce a correct result. It is useful for both cost and quality: shorter, more relevant context leaves more room for the code, errors, tests, and requirements that actually matter.

This guide applies to AI coding agents such as Codex and GitHub Copilot. The exact billing rules, context limits, model behavior, and caching features vary by product and plan, so treat provider dashboards and current product documentation as the source of truth for measured usage.

## The Basic Model

A coding-agent request usually contains several kinds of tokens:

- **Instruction tokens**: system rules, repository instructions, custom-agent instructions, and skills.
- **User-prompt tokens**: the task, constraints, examples, and requested output.
- **Context tokens**: source files, search results, diagnostics, diffs, logs, and tool output.
- **Output tokens**: the agent's explanation, proposed patch, code, and test report.
- **Tool-loop tokens**: repeated context sent across multiple rounds while the agent searches, edits, and validates.

A simplified request cost model is:

$$
C \approx \sum_{r=1}^{R} \left(I_r + P_r + X_r + O_r\right) \times p_r
$$

where $R$ is the number of model rounds, $I_r$ is instruction context, $P_r$ is the user prompt, $X_r$ is attached or retrieved context, $O_r$ is output, and $p_r$ is the applicable provider price for that round.

The model is simplified. Providers may price cached input, uncached input, output, reasoning, tool calls, or subscription usage differently. The practical lesson remains: reduce repeated and irrelevant context, reduce unnecessary rounds, and choose a model appropriate to the task.

## The Highest-Value Principle

Send the smallest context that can support a correct decision.

Too little context causes guessing, rework, and failed tests. Too much context increases cost, slows the agent, and makes the important details harder to notice. Optimization is therefore not blind compression. It is relevance filtering.

A useful test for every piece of context is:

> What decision could the agent make incorrectly if this information were omitted?

Keep the context when the answer is concrete. Omit, summarize, or load on demand when the answer is speculative or negligible.

## First Measure the Baseline

Do not optimize by intuition alone. Record a small baseline before changing the workflow.

Choose representative tasks from different categories:

- A short explanation request.
- A focused bug fix with a nearby test.
- A multi-file feature.
- A review of an existing diff.
- A documentation change.
- A command-heavy debugging task.

For each task, record:

- Model and client.
- Input tokens, if exposed.
- Output tokens, if exposed.
- Number of model turns.
- Number and size of tool results.
- Elapsed time.
- Tests or checks run.
- Whether the result was accepted, revised, or abandoned.
- Any quality failure caused by missing context.

A rough measurement table is enough:

| Task | Model | Input | Output | Rounds | Result | Rework |
| --- | --- | ---: | ---: | ---: | --- | --- |
| Explain one function | model-a |  |  |  | accepted/revised | none |
| Fix one failing test | model-a |  |  |  | accepted/revised |  |
| Review a diff | model-a |  |  |  | accepted/revised |  |

Measure successful outcomes, not just low token counts. A cheap attempt that requires a second full implementation may cost more than one well-contextualized attempt.

## Instruction Optimization

Instructions are often the easiest source of recurring overhead because they may be attached to many requests.

### Keep global instructions short

Global instructions should contain only rules that apply broadly. Good global rules include:

- Preserve unrelated user changes.
- Do not expose secrets.
- Validate before reporting success.
- Keep edits focused.
- State uncertainty when evidence is missing.

Move detailed procedures into skills or reference documents. A long instruction that applies to every request can cost tokens even when the current task is unrelated.

### Use file-scoped instructions

Apply language, framework, or directory-specific guidance only where it is relevant. A Python testing rule does not need to be attached to a CSS-only request.

Use a narrow file pattern when the client supports file-scoped instruction metadata. Prefer a specific scope such as a language or directory over a universal pattern.

### Use skills on demand

A skill should be loaded when a task needs its workflow, not merely because the repository contains the skill. Keep each skill focused and avoid repeating the same global rules in every skill.

A good skill contains:

- A precise trigger description.
- The minimum required workflow.
- References loaded only when needed.
- Explicit validation.
- No duplicated general safety policy unless the skill has a special risk.

### Avoid policy duplication

Repeated instructions are expensive and can conflict. Choose one authoritative location for each rule:

- Global behavior in global instructions.
- Technology behavior in a language or framework skill.
- Project requirements in the project specification.
- Detailed background in reference docs.
- Deterministic command blocking in a command policy or hook.

If the same paragraph appears in several files, shorten it in the global file and link or reference the detailed version.

## Prompt Optimization

A clear prompt reduces clarification rounds and prevents broad, unfocused searches.

Include:

- The desired outcome.
- The concrete anchor: file, symbol, command, test, or error.
- Relevant constraints and non-goals.
- Acceptance criteria.
- The first validation command.
- The requested mode: explain, inspect, review, plan, or implement.

Example:

```text
Fix the parser error for quoted CSV fields.
Start at src/csv/parser.ts and the nearest parser tests.
Preserve the public API and add a regression test for escaped quotes.
Run the focused parser test first, then the full CSV test suite.
Do not refactor unrelated parsing code.
```

This is more efficient than a vague request because it narrows discovery and gives the agent a testable stopping point.

### Put the important constraint first

Models may pay more attention to salient instructions near the beginning and end of a prompt. Put the outcome, dangerous constraints, and acceptance criteria where they are easy to find. Do not bury a critical non-goal in a long story.

### Avoid unnecessary narration

Include facts that affect a decision. Remove:

- Repeated greetings or conclusions.
- Long histories that do not affect the current state.
- Commentary copied from several previous attempts.
- Duplicate explanations of the same requirement.
- Large pasted logs when the error and relevant stack are sufficient.

### Use structured task blocks

A compact structure helps both the agent and the human reviewer:

```text
Outcome:
Context:
Constraints:
Acceptance:
Validation:
Mode:
```

The labels are not magic. Their value is that they expose missing information and make a request easy to scan.

## Repository Context Optimization

### Start from an anchor

Do not attach the whole repository for a local bug. Start with one of:

- The named file.
- The failing test.
- The error message.
- The function or class.
- The API route.
- The configuration key.
- The recent diff.

Then follow the nearest dependency or caller only when needed.

### Search before reading broadly

A targeted search usually costs less than loading large directory trees or many unrelated files. Search for:

- A symbol definition and call sites.
- An error message.
- A configuration key.
- A route or event name.
- A test describing the expected behavior.

Prefer bounded searches that exclude generated and dependency directories.

### Read slices, not whole files

Large files often contain only a few relevant sections. Read the definition, nearby helpers, and related tests first. Expand the range when the local evidence is insufficient.

Useful exclusions include:

- Dependency directories.
- Build and distribution output.
- Generated files.
- Coverage reports.
- Vendor trees.
- Binary assets.
- Large lockfiles unless dependency behavior is the task.

### Summarize stable context

If a large architecture or API description is needed repeatedly, maintain a concise, accurate reference document rather than pasting the same explanation into every prompt. The summary should link to authoritative code and state when it was last verified.

Do not summarize unstable behavior too aggressively. A stale summary can cause more rework than the tokens it saves.

### Use diffs for review

For a code review, send the relevant diff and the requirements it must satisfy. Do not include the entire repository unless the change depends on broad architecture. Add specific files only when the diff alone cannot establish correctness.

## Tool Output Optimization

Tool output can dominate a coding-agent session because every command result may become model context.

### Filter large output

For repetitive output, use a filter that preserves the signal:

- Show failing tests and their summaries.
- Select relevant log levels.
- Limit search results to the owning directory.
- Print only changed files and focused diff sections.
- Summarize repeated stack frames.
- Use `rtk` or an equivalent output filter when it preserves the information needed for the decision.

Use raw output when exact text, quoting, ordering, or exit status matters. A filter that hides the error is not an optimization; it is a debugging failure.

### Set explicit limits

Prefer commands that bound output by path, count, line range, or match type. Avoid commands that dump an entire repository or log history by default.

### Do not repeat unchanged output

Once an output has been inspected, do not paste it again unless the agent needs it after a context change. Refer to the stable result briefly.

### Capture failures, not noise

For a failing test, the useful context is usually:

- The command.
- Exit status.
- The first meaningful error.
- The relevant stack trace.
- The nearby source and test.

Preserve enough surrounding output to distinguish multiple independent failures.

## Tool-Loop Optimization

Each extra agent turn can repeat instructions and context. Reduce loops by making the first request precise and giving the agent a validation path.

Efficient loop:

1. Inspect the anchor.
2. State one hypothesis.
3. Make one focused edit.
4. Run one discriminating check.
5. Repair the same slice if needed.
6. Run broader validation.
7. Review and report.

Inefficient loop:

1. Load every document.
2. Ask for a proposal without acceptance criteria.
3. Change many unrelated files.
4. Run a broad suite with noisy output.
5. Discover the original task was ambiguous.
6. Repeat the full context and implementation.

### Batch independent inspection

When multiple files or checks are independent, inspect them in parallel. This reduces waiting and can reduce repeated setup context. Do not parallelize operations that depend on the result of a prior mutation.

### Validate narrowly first

A focused test or direct reproduction is usually cheaper than a complete suite. It also tells you quickly whether the current hypothesis survived the edit.

### Stop when acceptance is met

Do not ask the agent to continue polishing after the requested behavior is correct and validated unless there is a specific reason. Open-ended improvement requests consume tokens and invite scope expansion.

## Output Optimization

Output tokens are useful when they contain decisions, patches, and evidence. They are wasteful when they repeat the prompt or narrate every trivial step.

Ask for:

- A concise summary.
- Files changed.
- Tests and checks run.
- Remaining risks or skipped validation.
- Decisions that need human input.

Avoid requiring long explanations for routine changes. Request detail when the task is educational, risky, or architectural.

For code generation, prefer a patch in the repository over a giant chat transcript. For explanations, ask for the relevant depth and audience.

## Model Selection and Routing

Use the cheapest model that can reliably complete the task.

A practical routing scheme is:

| Task | First choice | Escalate when |
| --- | --- | --- |
| Locate a symbol or summarize a small file | Small/fast model | The result is ambiguous |
| Draft a narrow test or simple edit | Small/fast model | The change touches shared behavior |
| Debug a local failure | Capable coding model | The local hypothesis is disproven |
| Design a cross-module feature | Strong reasoning model | Requirements or tradeoffs are unclear |
| Security-sensitive or production change | Strong model plus human review | Always keep human approval |
| Final review | Independent capable model | Findings conflict or scope is broad |

A local model can help classify a prompt, rank candidate files, or summarize repetitive output before a premium model sees it. Measure quality and total latency; preprocessing is not a saving if it adds a full extra request without reducing premium context or rework.

Do not route secrets or sensitive source code to a model merely to save tokens. Data-handling requirements take priority over cost.

## Caching and Reuse

Some clients and providers cache repeated instruction prefixes or conversation context. When caching is available:

- Keep stable instructions at the beginning of requests.
- Avoid changing boilerplate on every turn.
- Separate stable policy from task-specific details.
- Use a persistent session when the same task genuinely continues across turns.
- Start a fresh session when old context is no longer relevant.

Caching behavior is provider-specific. Do not assume repeated text is free; inspect usage reporting where available.

Reuse is beneficial when it avoids re-explaining stable facts. It becomes harmful when the session accumulates stale files, failed approaches, or obsolete requirements. Context hygiene matters more than session length.

## Session Hygiene

At the start of a task:

- State the current outcome.
- Identify what has already been verified.
- Separate facts from assumptions.
- Name the next check.

During the task:

- Keep one problem per session when practical.
- Do not retain irrelevant logs.
- Correct stale assumptions explicitly.
- Summarize stable discoveries instead of repeating raw output.
- Stop or restart when the context becomes noisy.

At the end:

- Record the final state and validation evidence.
- Preserve a short decision record for work that will continue later.
- Do not carry a large exploratory transcript into an unrelated task.

## Common Anti-Patterns

### The universal instruction dump

A large instruction file is applied to every request. It increases baseline usage and distracts from the active task.

Better: keep global rules short and move detailed procedures to scoped skills or references.

### The whole-repository attachment

Every request includes the entire source tree. It increases cost and makes relevant code harder to identify.

Better: start from the controlling file or failing test and expand deliberately.

### The unfiltered command dump

A test suite or log is pasted in full even though most lines repeat the same status.

Better: preserve failure details, counts, and exit status while filtering repetitive noise.

### The giant prompt history

Every previous attempt is copied into the next request. Old assumptions and failed approaches compete with the current task.

Better: summarize the current state and keep only decisions that still matter.

### Premature local-model preprocessing

A local model summarizes context, but the premium model still receives the same full context and an additional request is added.

Better: define what the local stage removes or improves, then measure total usage and quality.

### Optimizing away necessary context

The agent is given too little information and makes a wrong change, causing retries.

Better: preserve requirements, constraints, owning code, relevant tests, and security context even when trimming everything else.

## A Staged Optimization Plan

### Stage 1: Low-risk cleanup

1. Measure representative task usage.
2. Remove duplicated global instructions.
3. Narrow universal instruction patterns.
4. Add bounded search and log commands.
5. Ask for concise evidence-based reports.
6. Rerun the same baseline tasks.

### Stage 2: Context routing

1. Add file- or directory-scoped instructions.
2. Convert repeatable workflows into on-demand skills.
3. Create concise architecture references for stable concepts.
4. Use separate sessions for unrelated tasks.
5. Add a focused review step before broad validation.

### Stage 3: Model routing

1. Classify tasks by complexity and risk.
2. Use a small model for low-risk classification or summarization.
3. Escalate ambiguous or high-impact work.
4. Compare total tokens, latency, rework, and quality.
5. Keep human approval for external and destructive actions.

### Stage 4: Continuous measurement

1. Track usage by task category.
2. Watch for quality regressions and increased retries.
3. Review instructions and skills when costs rise.
4. Retire stale context and unused workflows.
5. Re-measure after each meaningful configuration change.

## Measurement Worksheet

Use this worksheet for a before-and-after experiment:

```text
Experiment:
Date:
Client and version:
Model and plan:
Task set:

Baseline input tokens:
Baseline output tokens:
Baseline model rounds:
Baseline tool output size:
Baseline elapsed time:
Baseline accepted-result rate:
Baseline rework:

Change tested:

After-change input tokens:
After-change output tokens:
After-change model rounds:
After-change tool output size:
After-change elapsed time:
After-change accepted-result rate:
After-change rework:

Decision:
Quality notes:
Residual risks:
```

A useful optimization should improve one or more cost measures without causing unacceptable quality, latency, security, or maintainability regressions.

## Final Checklist

Before adopting a token-saving change, confirm:

- The baseline was measured on representative tasks.
- The change removes irrelevant or repeated context.
- Necessary requirements and safety constraints remain present.
- The instruction scope is no broader than needed.
- Tool output is bounded without hiding meaningful failures.
- Skills and references are loaded on demand.
- Model routing reflects task complexity and risk.
- Total cost includes preprocessing, retries, and rework.
- Quality and validation results did not regress.
- Sensitive data handling was not weakened.
- The new behavior is documented and can be measured again.
