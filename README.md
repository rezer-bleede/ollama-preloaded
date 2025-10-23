# 🧠 Ollama Preloaded (Llama 3)

Pre-built Docker image containing **Ollama** and a **locally cached Llama 3 model** — ready to run instantly, without needing to download the model from Ollama’s registry.

---

## 🚀 Overview

This image is designed for developers and data engineers who want to:
- Run **Ollama** offline or in air-gapped environments  
- Avoid TLS / CA certificate issues during model pulls  
- Deploy self-contained inference containers for **Llama 3**

It uses the official [`ollama/ollama:latest`](https://hub.docker.com/r/ollama/ollama) base image, with `llama3` pre-fetched into `/root/.ollama/models`.

---

## 🧱 Build Process (via GitHub Actions)

Each push to this repo triggers an automated **GitHub Actions workflow** that:
1. Pulls the latest Ollama base image  
2. Runs `ollama pull llama3` inside the build stage  
3. Publishes the resulting image to **GitHub Container Registry (GHCR)**

Image tag example:
```
ghcr.io/rezer-bleede/ollama-preloaded:llama3
```

---

## 🐳 Usage

### Run the container directly
```bash
docker run -d -p 11434:11434 ghcr.io/rezer-bleede/ollama-preloaded:llama3
```

### Check available models
```bash
docker exec -it <container_id> ollama list
```

### Generate text
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Explain data normalization in simple terms."
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

## 🧩 Why Preloaded?

- ✅ **Instant startup** – model already downloaded  
- 🔒 **Offline-friendly** – no external network calls  
- 🧰 **Consistent builds** – same model across all environments  
- ⚡ **CI/CD-ready** – just pull and deploy  

---

## 📦 Model Info

| Model | Size | Parameters | Context | License |
|--------|------|-------------|----------|-----------|
| `llama3` | ~4–8 GB | 8B | 4K tokens | Meta Llama 3 Community License |

---

## 🧰 Local Build (optional)

If you prefer to build manually:

```bash
git clone https://github.com/rezer-bleede/ollama-preloaded.git
cd ollama-preloaded
docker build -t ollama-preloaded:llama3 .
```

---

## 🪪 License

Licensed under the **Apache 2.0 License**.  
Ollama and Llama 3 are trademarks of their respective owners.

---

## 👤 Author

**Remis Bobby Haroon**  
Data Engineer • AI Infrastructure Builder  
[GitHub @rezer-bleede](https://github.com/rezer-bleede)

---

> ⚠️ This project is community-maintained and not affiliated with the Ollama team.
