# Local AI Model Setup

Default OpenCode/OpenClaw model: `ollama/qwen2.5-coder:7b`.

This is a free local-only setup through Ollama. Paid/unavailable Z.ai cloud model wiring has been removed from the active shell and OpenCode configs.

## Local Runner

Ollama is installed and started with Homebrew.

Installed local models:

```zsh
qwen2.5-coder:7b
qwen2.5-coder:14b
```

`qwen2.5-coder:7b` is the practical default on this 16GB Mac. `qwen2.5-coder:14b` is installed and selectable for harder prompts, but a medium Dart coding prompt took about 118 seconds versus about 61 seconds for 7B. The local GLM models were removed to keep only the best two practical coding models.

Check local runner:

```zsh
ollama list
ollama ps
curl http://localhost:11434/api/version
```

Run the local model directly:

```zsh
localai "explain this project in 5 bullets"
localai14 "solve a harder coding prompt"
ollama run qwen2.5-coder:7b "explain this project in 5 bullets"
ollama run qwen2.5-coder:14b "solve a harder coding prompt"
```

If `opencode run` fails with `Session not found` while `OPENCODE_SERVER_PASSWORD` is set, use the local wrapper added to `~/.zshrc`:

```zsh
opencode-local run "inspect this project"
```

Z.ai GLM-5/GLM-5.1 Ollama entries were cloud-only and required a subscription here, so they are not configured. No new models should be downloaded unless one of these two local models is intentionally replaced.

## OpenCode

OpenCode CLI is installed globally with `npm install -g opencode-ai`.

Global config is at:

```zsh
~/.config/opencode/opencode.json
```

Configured default model:

```zsh
ollama/qwen2.5-coder:7b
```

Selectable stronger/slower model:

```zsh
ollama/qwen2.5-coder:14b
```

Run locally:

```zsh
source ~/.zshrc
opencode-local run "inspect this project"
opencode run -m ollama/qwen2.5-coder:7b "inspect this project"
opencode run -m ollama/qwen2.5-coder:14b "inspect this project with the stronger local model"
opencode models ollama
```
