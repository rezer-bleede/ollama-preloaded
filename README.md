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

## 🧰 Environment Variables

| Variable | Description | Default |
|-----------|-------------|----------|
| `OLLAMA_DEFAULT_MODEL` | Default model to serve | `llama3` |
| `OLLAMA_KEEP_ALIVE` | Keep model in memory duration | `24h` |
| `OLLAMA_SKIP_VERIFY` | Skip TLS verification (useful in air‑gapped environments) | `true` |

## 🏗️ Building Locally

You can build and preload any model via build‑args:
```bash
docker build -t ollama-preloaded:custom --build-arg MODEL_NAME=llama3 .
```

## ⚙️ GitHub Actions CI/CD

The project includes a fully automated workflow that:
- Cleans disk space for large model layers
- Builds and pushes preloaded variants (`llama3`, `phi3-mini`)
- Publishes images to Docker Hub

View `.github/workflows/build.yml` for the latest automation steps.

## 📄 License
Apache 2.0 © 2025 Rezer Bleede
