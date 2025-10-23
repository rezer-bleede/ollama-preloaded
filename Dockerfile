# ---------- Stage 1: Builder ----------
FROM ollama/ollama:latest AS builder

# Disable TLS verification (avoids registry cert issues)
ENV OLLAMA_SKIP_VERIFY=true

# Preload the Llama 3 model during build
RUN nohup ollama serve >/tmp/ollama.log 2>&1 & \
    sleep 8 && \
    ollama pull llama3 && \
    pkill ollama

# ---------- Stage 2: Final Runtime ----------
FROM ollama/ollama:latest

# Copy preloaded models from builder
COPY --from=builder /root/.ollama /root/.ollama

# Set default model and server behaviour
ENV OLLAMA_DEFAULT_MODEL=llama3 \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_SKIP_VERIFY=true

EXPOSE 11434

ENTRYPOINT ["ollama", "serve"]
