FROM ollama/ollama:latest AS builder

ARG MODEL_NAME=llama3
ENV OLLAMA_SKIP_VERIFY=true

RUN nohup ollama serve >/tmp/ollama.log 2>&1 & \
    sleep 10 && \
    ollama pull $MODEL_NAME || (echo "❌ Model pull failed" && cat /tmp/ollama.log && exit 1) && \
    pkill ollama || echo "ℹ️ Ollama already stopped"

FROM ollama/ollama:latest
COPY --from=builder /root/.ollama /root/.ollama

ENV OLLAMA_DEFAULT_MODEL=$MODEL_NAME \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_SKIP_VERIFY=true

EXPOSE 11434
ENTRYPOINT ["ollama", "serve"]
