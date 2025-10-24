# ===========================
# Stage 1 — Builder
# ===========================
FROM --platform=$BUILDPLATFORM ollama/ollama:latest AS builder

ARG MODEL_NAME=phi3:mini
ENV OLLAMA_SKIP_VERIFY=true \
    OLLAMA_HOME=/root/.ollama \
    OLLAMA_MODELS=/root/.ollama/models

# Wait until ollama serve is ready before pulling the model
RUN nohup ollama serve --models "$OLLAMA_HOME" >/tmp/ollama.log 2>&1 & \
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

# Ensure a dash based alias exists for colon based model names (e.g. phi3:mini -> phi3-mini)
RUN set -euo pipefail; \
    MODEL_ALIAS=$(printf '%s' "$MODEL_NAME" | tr ':' '-') && \
    if [ "$MODEL_ALIAS" != "$MODEL_NAME" ]; then \
        echo "🔁 Creating alias $MODEL_ALIAS for $MODEL_NAME"; \
        if ollama cp "$MODEL_NAME" "$MODEL_ALIAS" 2>/tmp/ollama-cp.log; then \
            echo "✅ Alias created using 'ollama cp'"; \
        else \
            echo "⚠️  Falling back to manifest copy"; \
            cat /tmp/ollama-cp.log || true; \
            mkdir -p "$OLLAMA_HOME/models/manifests/library"; \
            NORMALISED_NAME=$(printf '%s' "$MODEL_NAME" | sed 's/:/_/g'); \
            SRC_MANIFEST=$(find "$OLLAMA_HOME/models/manifests" -type f -name "*${NORMALISED_NAME}*" | head -n1); \
            if [ -n "$SRC_MANIFEST" ]; then \
                DEST_DIR="$OLLAMA_HOME/models/manifests/library/$MODEL_ALIAS"; \
                mkdir -p "$DEST_DIR"; \
                cp "$SRC_MANIFEST" "$DEST_DIR/manifest"; \
            fi; \
        fi; \
    fi

# ===========================
# Stage 2 — Runtime
# ===========================
FROM --platform=$TARGETPLATFORM ollama/ollama:latest

ARG MODEL_NAME=phi3:mini
ENV OLLAMA_HOME=/root/.ollama \
    OLLAMA_MODELS=/root/.ollama/models
COPY --from=builder /root/.ollama /root/.ollama

ENV OLLAMA_DEFAULT_MODEL=$MODEL_NAME \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_SKIP_VERIFY=true

EXPOSE 11434
ENTRYPOINT ["ollama", "serve", "--models", "/root/.ollama"]
