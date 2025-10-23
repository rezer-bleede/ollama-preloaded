# ---------- Stage 1: Builder ----------
FROM ollama/ollama:latest AS builder

# Disable TLS verification (prevents cert issues during build)
ENV OLLAMA_SKIP_VERIFY=true

# Preload the Llama 3 model during build (robust kill + log handling)
RUN nohup ollama serve >/tmp/ollama.log 2>&1 & \
    sleep 10 && \
    ollama pull llama3 || (echo "❌ Model pull failed" && cat /tmp/ollama.log && exit 1) && \
    pkill ollama || echo "ℹ️ Ollama already stopped or not running"

# ---------- Stage 2: Final Runtime ----------
FROM ollama/ollama:latest

# Copy preloaded model cache from builder
COPY --from=builder /root/.ollama /root/.ollama

# Environment settings for runtime
ENV OLLAMA_DEFAULT_MODEL=llama3 \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_SKIP_VERIFY=true

# Expose Ollama API port
EXPOSE 11434

# Start Ollama server
ENTRYPOINT ["ollama", "serve"]
