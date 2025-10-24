# ===========================
# Stage 1 — Builder
# ===========================
FROM --platform=$BUILDPLATFORM ollama/ollama:latest AS builder

# Model argument (default = llama3)
ARG MODEL_NAME=llama3
ENV OLLAMA_SKIP_VERIFY=true

# Start Ollama temporarily, preload the model, then stop
RUN nohup ollama serve >/tmp/ollama.log 2>&1 & \
    sleep 10 && \
    ollama pull $MODEL_NAME || (echo "❌ Model pull failed" && cat /tmp/ollama.log && exit 1) && \
    pkill ollama || echo "ℹ️ Ollama already stopped"

# ===========================
# Stage 2 — Runtime
# ===========================
FROM --platform=$TARGETPLATFORM ollama/ollama:latest

# Copy preloaded model data from builder
COPY --from=builder /root/.ollama /root/.ollama

# Default environment variables
ARG MODEL_NAME=llama3
ENV OLLAMA_DEFAULT_MODEL=$MODEL_NAME \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_SKIP_VERIFY=true

# Expose Ollama server port
EXPOSE 11434

# Start Ollama server
ENTRYPOINT ["ollama", "serve"]
