# ===========================
# Stage 1 — Builder
# ===========================
FROM --platform=$BUILDPLATFORM ollama/ollama:latest AS builder

ARG MODEL_NAME=phi3:mini
ENV OLLAMA_SKIP_VERIFY=true

# Wait until ollama serve is ready before pulling the model
RUN nohup ollama serve >/tmp/ollama.log 2>&1 & \
    echo "Starting Ollama..." && \
    for i in $(seq 1 30); do \
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then \
            echo "✅ Ollama is ready"; break; \
        fi; \
        echo "⏳ Waiting for Ollama ($i/30)..."; sleep 2; \
    done && \
    ollama pull $MODEL_NAME || (echo "❌ Model pull failed" && cat /tmp/ollama.log && exit 1) && \
    ollama list && \
    pkill ollama || echo "ℹ️ Ollama already stopped"

# Optional: add alias so both names work
RUN mkdir -p /root/.ollama/models/manifests && \
    ln -s /root/.ollama/models/manifests/phi3:mini /root/.ollama/models/manifests/phi3-mini || true

# ===========================
# Stage 2 — Runtime
# ===========================
FROM --platform=$TARGETPLATFORM ollama/ollama:latest

ARG MODEL_NAME=phi3:mini
COPY --from=builder /root/.ollama /root/.ollama

ENV OLLAMA_DEFAULT_MODEL=$MODEL_NAME \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_SKIP_VERIFY=true

EXPOSE 11434
ENTRYPOINT ["ollama", "serve"]
