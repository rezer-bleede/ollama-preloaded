# 🧠 Ollama Preloaded (Llama 3)

Pre-built Docker image containing **Ollama** and a **pre-cached Llama 3 model**, ready for instant startup — no downloads, no TLS issues, no waiting.

---

## 🚀 Overview

This image is optimized for developers and data engineers who need:
- **Offline or air‑gapped** Ollama deployments  
- **Fast container startup** without model pulls  
- **Stable builds** that work in CI/CD pipelines  
- **Automatic publishing** to Docker Hub + GitHub Container Registry

The container is built via a two‑stage Dockerfile using the official [`ollama/ollama:latest`](https://hub.docker.com/r/ollama/ollama) base image.

---

## 🧱 Build Pipeline

Each push or manual run of the GitHub Action will:

1. Pull the latest `ollama/ollama:latest` base image  
2. Launch a temporary `ollama serve` daemon  
3. Preload the `llama3` model  
4. Copy preloaded models to a clean final image  
5. Push to **Docker Hub** and **GHCR** simultaneously

| Registry | Image |
|-----------|--------|
| GitHub Container Registry | `ghcr.io/rezer-bleede/ollama-preloaded:llama3` |
| Docker Hub | `rezerbleede/ollama-preloaded:llama3` |

---

## 🐳 Usage

### Run directly
```bash
docker run -d -p 11434:11434 ghcr.io/rezer-bleede/ollama-preloaded:llama3
```

### Check available models
```bash
docker exec -it <container_id> ollama list
```

### Generate a response
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Summarize database normalization."
}'
```

---

## ⚙️ Example `docker-compose.yml`

```yaml
services:
  ollama:
    image: ghcr.io/rezer-bleede/ollama-preloaded:llama3
    restart: unless-stopped
    ports:
      - "11434:11434"
    environment:
      OLLAMA_KEEP_ALIVE: 24h
```

---

## 🧩 Why This Image

- ✅ **Instant startup** – no model downloads  
- 🔒 **Offline‑ready** – ships with `llama3` included  
- 🧰 **CI/CD compatible** – builds cleanly in GitHub Actions  
- ⚡ **Dual‑registry support** – GHCR + Docker Hub auto‑publish  
- 🧱 **Two‑stage build** – no leftover files or temp daemons  

---

## 🧰 Local Build (Optional)

If you prefer to build locally instead of GitHub Actions:

```bash
git clone https://github.com/rezer-bleede/ollama-preloaded.git
cd ollama-preloaded
docker build -t ollama-preloaded:llama3 .
```

---

## 🪪 License

Licensed under **Apache 2.0**.  
Ollama and Llama 3 are trademarks of their respective owners.

---

## 👤 Author

**Remis Bobby Haroon**  
Data Engineer • AI Infrastructure Builder  
[GitHub @rezer‑bleede](https://github.com/rezer-bleede)

---

> ⚠️ Community-maintained image — not affiliated with the Ollama team.
