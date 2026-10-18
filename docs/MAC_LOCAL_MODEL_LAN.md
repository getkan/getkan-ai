# Run a Mac local model on the local network

This guide explains how to run a local model on a Mac, expose it to trusted
devices on the same local network, and use it from Codex or VS Code on another
computer.

GitHub Copilot itself cannot be pointed at a local model endpoint. Copilot is a
hosted GitHub service. For VS Code local-model use, choose an extension that
supports Ollama or OpenAI-compatible endpoints, such as Continue, Cline/Roo
Code, CodeGPT, or another local-model client.

## Recommended shape

- Host machine: Mac running Ollama and the model.
- Client machine: another computer running Codex or VS Code.
- Network: trusted local network or VPN only.
- API endpoint: Ollama's HTTP API on port `11434`.

Do not expose Ollama's port to the public internet. Treat the endpoint as an
unauthenticated local service unless you add a reverse proxy or network-level
access controls.

## 1. Install Ollama on the Mac

Install Ollama with Homebrew:

```bash
brew install --cask ollama
open -a Ollama
```

Pull a coding model. Start with a 7B model before moving to larger models:

```bash
ollama pull qwen2.5-coder:7b
```

Other reasonable options:

```bash
ollama pull qwen2.5-coder:14b
ollama pull llama3.1:8b
ollama pull deepseek-coder-v2:16b
```

Test the model locally on the Mac:

```bash
ollama run qwen2.5-coder:7b "Reply with: model is working"
```

## 2. Bind Ollama to the local network

By default, Ollama listens only on localhost. To make it reachable from other
devices on the local network, set `OLLAMA_HOST` to listen on all interfaces:

```bash
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
```

Restart Ollama:

```bash
osascript -e 'quit app "Ollama"'
open -a Ollama
```

Confirm the API responds on the Mac:

```bash
curl http://127.0.0.1:11434/api/tags
curl http://127.0.0.1:11434/v1/models
```

Find the Mac's local IP address:

```bash
ipconfig getifaddr en0
```

`en0` is usually Wi-Fi. The result should look like `192.168.1.25` or another
private LAN address.

From the client computer, verify network reachability:

```bash
curl http://MAC_IP:11434/api/tags
```

Then test generation from the client computer:

```bash
curl http://MAC_IP:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "prompt": "Reply with only: hello from the Mac model",
    "stream": false
  }'
```

Replace `MAC_IP` with the Mac's local IP address.

If the request fails, check that Ollama is running, both machines are on the
same network, and macOS Firewall allows Ollama to accept incoming connections.

## 3. Use the Mac model from Codex

The Codex CLI supports local providers. On the client computer, point Codex at
the Mac's Ollama server with `OLLAMA_HOST`:

```bash
OLLAMA_HOST="http://MAC_IP:11434" \
  codex --oss --local-provider ollama --model qwen2.5-coder:7b
```

For a single non-interactive command:

```bash
OLLAMA_HOST="http://MAC_IP:11434" \
  codex exec --oss --local-provider ollama --model qwen2.5-coder:7b \
  "Summarize this repository"
```

To make this persistent for the current shell session:

```bash
export OLLAMA_HOST="http://MAC_IP:11434"
codex --oss --local-provider ollama --model qwen2.5-coder:7b
```

Try Codex's native Ollama provider first. If a tool requires an
OpenAI-compatible endpoint instead, use Ollama's `/v1` API endpoint:

```text
Base URL: http://MAC_IP:11434/v1
API key: ollama
Model: qwen2.5-coder:7b
```

## 4. Use the Mac model from VS Code

Use a VS Code extension that supports Ollama or OpenAI-compatible local model
providers. GitHub Copilot Chat cannot be reconfigured to use this endpoint.

For Continue, an example model entry is:

```json
{
  "models": [
    {
      "title": "Mac Ollama Qwen Coder",
      "provider": "ollama",
      "model": "qwen2.5-coder:7b",
      "apiBase": "http://MAC_IP:11434"
    }
  ]
}
```

For extensions that expect an OpenAI-compatible service, use:

```text
Base URL: http://MAC_IP:11434/v1
API key: ollama
Model: qwen2.5-coder:7b
```

## 5. Model sizing guidance

Start with the smallest model that can do the job. Larger models can be much
slower, especially on Macs with limited unified memory.

| Mac memory | Practical starting point |
| --- | --- |
| 8 GB | 3B to 7B quantized models |
| 16 GB | 7B models, some 14B quantized models |
| 32 GB or more | 14B to 32B quantized models, depending on speed tolerance |

For coding, start with:

```bash
ollama pull qwen2.5-coder:7b
```

Move up only if quality is too weak:

```bash
ollama pull qwen2.5-coder:14b
```

## 6. Minimal checklist

On the Mac:

```bash
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
open -a Ollama
ollama pull qwen2.5-coder:7b
ipconfig getifaddr en0
```

On the client computer:

```bash
curl http://MAC_IP:11434/api/tags

OLLAMA_HOST="http://MAC_IP:11434" \
  codex --oss --local-provider ollama --model qwen2.5-coder:7b
```

## Security notes

- Do not port-forward port `11434` from your router to the public internet.
- Prefer a trusted LAN or VPN.
- Reserve the Mac's LAN IP in the router so client configuration stays stable.
- Use macOS Firewall or router rules to limit which devices can reach the Mac.
- Keep secrets out of prompts sent to any model, including local models.