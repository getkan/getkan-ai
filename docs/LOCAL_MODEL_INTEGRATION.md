# Local model integration

This is the beginner-friendly guide for [ROADMAP.md](../ROADMAP.md) Phase 4 of
the shared Codex and GitHub Copilot agent base: using small local models to
pre-process prompts and context before a premium model is invoked, to reduce
premium token usage. Read this document before starting any Phase 4 work; it is
not loaded automatically.

## Goal, in one sentence

Before spending premium-model tokens, let a small model running on your own
hardware do the cheap, high-volume work first: understanding what the prompt
is really asking, gathering relevant context, and trimming or restructuring
that context down to what matters.

## Glossary (read this first if you are new to local LLMs)

- **Local model**: A language model that runs on hardware you control
  (your desktop, a home server) instead of a hosted API. You download the
  model's weights once and run them with a local runtime.
- **Model runtime**: The program that loads model weights and serves
  requests. Examples: [Ollama](https://ollama.com) (simplest to start with)
  and [llama.cpp](https://github.com/ggml-org/llama.cpp) (more control, more
  setup).
- **Parameter count (e.g., "3B", "12B")**: Roughly, how large and capable a
  model is. Bigger numbers need more RAM/VRAM and are slower, but tend to
  produce better output. "3B" = 3 billion parameters.
- **Quantization**: A way to shrink a model's memory footprint by storing its
  numbers with less precision (e.g., 4-bit instead of 16-bit). Smaller
  footprint and faster inference, at some cost to output quality. Quantized
  model files are usually labeled like `Q4_K_M` or `Q8_0`; lower bit counts
  are smaller and faster but lower quality.
- **Context window**: The maximum amount of text (measured in tokens) a model
  can consider at once. Small local models typically have smaller context
  windows than premium hosted models, which is one reason their job here is
  to shrink and focus context, not carry the whole conversation.
- **Token**: Roughly, a word or word-fragment. Both local and premium model
  usage and cost are measured in tokens. "Token optimization" means reducing
  how many tokens the premium model has to read and generate.
- **Routing**: Deciding which model handles a given request. In this phase,
  routing means: local model first, premium model second, with the local
  model's output feeding into what the premium model sees.
- **Prompt evaluation**: Having a model look at a request and summarize,
  classify, or clarify it before the "real" work happens.
- **Context search**: Having a model help find the specific files, functions,
  or docs relevant to a request, instead of loading everything.

## The models

| Model | Size | Role in this phase | Typical hardware need |
| --- | --- | --- | --- |
| SmolLM3 | 3B | Fast, cheap first pass: prompt classification, short summarization | Runs comfortably on most modern CPUs; a small/no GPU is fine |
| Gemma 4 | 12B | Heavier context search and pre-filtering where 3B quality is not enough | Benefits from a GPU with meaningful VRAM (8GB+); CPU-only will be slow |
| Qwen 3.6 | check exact size when selecting a build | General-purpose second opinion between the 3B and 12B tiers | Depends on the exact release picked; verify before committing hardware |

Start with SmolLM3 3B only. Add Gemma 4 12B and Qwen 3.6 once the pipeline
with one model is working end to end; running three models before the
pipeline itself works makes debugging much harder.

## Stage 1: local models on the host

1. Install a model runtime on the host. Ollama is the easiest starting point:
   it handles downloading, quantization selection, and serving a local HTTP
   API with one command per model.
2. Pull SmolLM3 3B and confirm it responds to a plain prompt through the
   runtime's own CLI or API before wiring anything else to it. This isolates
   "is the model working" from "is the integration working."
3. Decide what "basic prompt evaluation, context search, and token
   optimization" concretely means for the first version. Suggested minimal
   scope:
   - Prompt evaluation: the local model restates the user's request in a
     short, structured form (what is being asked, what files/areas are
     likely relevant).
   - Context search: the local model is given a list of candidate files or
     search results and asked to rank or filter them, rather than searching
     itself.
   - Token optimization: the local model's structured output replaces a
     longer raw context blob before it reaches the premium model.
4. Wire this into the Codex/OpenRouter flow as a pre-processing step, not a
   replacement step. The premium model must still receive enough information
   to complete the task; the local model's job is to reduce volume and
   improve focus, not to withhold necessary context.
5. Measure token usage before and after: run the same set of representative
   tasks with and without the local pre-processing step, and record premium
   input/output token counts for both. Do not consider this stage successful
   until there is a measured reduction with no observed quality regression.

## Stage 2: containerize with Docker

Only move to this stage once Stage 1 is measured and working.

1. Write a minimal Dockerfile (or use the runtime's official image, if one
   exists) that runs the chosen model runtime and exposes its API port.
2. Run the container locally and repoint the Stage 1 integration at the
   container's address instead of the bare-host process. Confirm behavior is
   identical to the host-run version before changing anything else.
3. Keep model weights on a persistent volume rather than baking them into the
   image, so updating a model does not require rebuilding the image.

## Stage 3: move to a separate machine on the local network

Only move to this stage once Stage 2 is validated.

1. Run the container on the target machine and confirm it is reachable from
   the machine running Codex over the local network (plain `curl` against
   its API is a good first check).
2. Do not expose the model's API port beyond the local network. Bind it to
   the local network interface only, and use your router/firewall to block
   external access; treat this the same as any other unauthenticated local
   service.
3. Add basic authentication or network-level restriction (for example, an
   allowlist of the Codex host's IP) if the local network includes untrusted
   devices.
4. Re-run the Stage 1 token-usage measurement after the move to confirm added
   network latency has not made the local pre-processing step slower than
   the token savings justify.

## Stage 4: first-pass implementation (later, quality-gated)

Do not attempt this stage until Stages 1-3 are stable and the local models'
output has been reliable in the narrower pre-processing role.

1. Expand the local model's task from pre-processing to attempting a first
   draft implementation for well-scoped, low-risk changes.
2. The premium model's role shifts to review: checking the local model's
   draft for correctness, security issues, and adherence to project
   conventions, and correcting it rather than starting from scratch.
3. Keep a fallback path: if the local model's draft is clearly unusable, fall
   back to having the premium model implement directly, the same as today.
4. Track how often the premium model has to substantially rewrite versus
   lightly edit the local model's draft. This ratio is the signal for
   whether local models are ready for a larger share of first-pass work.

## Security notes

- Treat any locally-hosted model endpoint as a service that needs the same
  care as any other local network service: least-privilege network
  exposure, no default/blank credentials, and no exposure to the public
  internet.
- Local models can still be prompted with sensitive repository content.
  Applying the same data-handling care used for premium model providers
  (credentials, tokens, secrets never included) applies to local models too.

## Suggested background reading

- Ollama's own documentation for model pulling, quantization tags, and the
  local API: <https://github.com/ollama/ollama/blob/main/docs/api.md>
- llama.cpp's README for a lower-level understanding of what a model runtime
  actually does: <https://github.com/ggml-org/llama.cpp>
- Each model's own model card on Hugging Face (search by name) for exact
  parameter counts, context window size, and license terms before relying on
  it.
