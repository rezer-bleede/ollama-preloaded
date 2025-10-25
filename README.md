# 🧠 Ollama Preloaded

A lightweight preloaded container image for **Ollama**, designed to run models like **Llama 3** and **Phi-3 Mini** instantly — no download delay.

## 🚀 Overview

This image builds upon `ollama/ollama:latest` and preloads one or more models directly into the container at build time.  
It’s ideal for use in air‑gapped environments, CI/CD pipelines, or rapid prototyping setups where model pulls are impractical or slow.

## 🧩 Preloaded Variants

| Tag | Preloaded Model | Size (Approx.) | Notes |
|-----|------------------|----------------|-------|
| `llama3` | Meta Llama 3 | ~4.7 GB | High‑performance general‑purpose LLM |
| `phi3-mini` | Microsoft Phi‑3 Mini | ~2.2 GB | Compact model optimized for efficiency |
| `sqlcoder` | Defog SQLCoder 7B | ~7.7 GB | Purpose-built for SQL generation, data modeling, and relational reasoning |
| `deepseek-coder-6.7b` | DeepSeek Coder 6.7B | ~14 GB | Alias for `deepseek-coder:6.7b` — great for ERD prompts |
| `llama3.1-8b-instruct` | Meta Llama 3.1 8B Instruct | ~8.1 GB | Alias for `llama3.1:8b-instruct` with strong schema design skills |

## 🧠 Data Modeling Playbook

Need to generate entity‑relationship diagrams (ERDs), infer table joins, or reason about dataset relationships? Preload a combination of the models above using the new multi-model build flow and route prompts to the best fit for each task.

## 🧱 Usage

Run any variant directly:
```bash
docker run -d -p 11434:11434 rezerbleede/ollama-preloaded:llama3
# or
docker run -d -p 11434:11434 rezerbleede/ollama-preloaded:phi3-mini
```

Once running, you can interact with Ollama’s local API:
```bash
curl http://localhost:11434/api/generate -d '{"model":"llama3","prompt":"Hello"}'
```

### ✅ Verifying the preload

Each image now starts the Ollama server with the models directory configured via the `OLLAMA_MODELS` environment variable:

```bash
docker logs <container> | grep "Loaded"
curl http://localhost:11434/api/tags
```

You should see the preloaded model (for example `llama3` or `phi3:mini`) listed in the response. The container relies on the built-in environment configuration (`OLLAMA_HOME=/root/.ollama`, `OLLAMA_MODELS=/root/.ollama/models`) so it stays compatible with newer Ollama releases that no longer accept the `--models` flag.

> [!IMPORTANT]
> The build pipeline now gives the embedded Ollama daemon up to five minutes to advertise its readiness, probing `localhost`, `127.0.0.1`, and the IPv6 loopback `[::1]` before pulling models. This extended window prevents flaky CI jobs on slower builders and mirrors the runtime health-check expectations.

## 🧰 Environment Variables

| Variable | Description | Default |
|-----------|-------------|----------|
| `OLLAMA_DEFAULT_MODEL` | Default model to serve | `llama3` |
| `OLLAMA_KEEP_ALIVE` | Keep model in memory duration | `24h` |
| `OLLAMA_SKIP_VERIFY` | Skip TLS verification (useful in air‑gapped environments) | `true` |
| `OLLAMA_HOME` | Home directory used by Ollama | `/root/.ollama` |
| `OLLAMA_MODELS` | Location of model blobs and manifests | `/root/.ollama/models` |

## 🏗️ Building Locally

You can now preload **multiple models at once** using the build arguments:
```bash
docker build \
  -t ollama-preloaded:data-stack \
  --build-arg MODEL_NAMES="sqlcoder deepseek-coder:6.7b llama3.1:8b-instruct" \
  --build-arg DEFAULT_MODEL=sqlcoder \
  .
```

* `MODEL_NAMES` accepts a space-separated list of Ollama model identifiers. Each entry is downloaded, validated with `ollama show`, and made available inside the image.
* `DEFAULT_MODEL` controls the model served on container start (defaults to the first entry). When omitted it falls back to `phi3:mini` for backwards compatibility.

> [!TIP]
> Identifiers that contain a colon (for example `deepseek-coder:6.7b`) are automatically duplicated with a dash-based alias (`deepseek-coder-6.7b`) so you can choose whichever tag is most convenient inside the container.

> [!NOTE]
> The Dockerfile uses POSIX-compliant `set -eu` guards instead of `set -o pipefail` so multi-architecture builds work on Debian's dash shell as well as bash. This keeps the builder stage portable across the official Ollama images used on both AMD64 and ARM64.

The runtime image now exposes the `OLLAMA_PRELOADED_MODELS` environment variable so downstream automation can confirm which artifacts are bundled.

## ⚙️ GitHub Actions CI/CD

The project includes a fully automated workflow that:
- Cleans disk space for large model layers
- Builds and pushes preloaded variants (`llama3`, `phi3-mini`)
- Publishes images to Docker Hub

View `.github/workflows/build.yml` for the latest automation steps.

## 📄 License
Apache 2.0 © 2025 Rezer Bleede
