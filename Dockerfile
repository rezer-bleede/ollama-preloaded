# ===========================
# Stage 1 — Builder
# ===========================
FROM --platform=$BUILDPLATFORM ollama/ollama:latest AS builder

# Space-separated list of models to preload
ARG MODEL_NAMES="llama3 phi3:mini"
ARG STARTUP_WAIT_SECS=300

# Build-time env (works on 0.12.x too)
ENV OLLAMA_HOME=/root/.ollama \
    OLLAMA_MODELS=/root/.ollama/models \
    OLLAMA_HOST=127.0.0.1:11434 \
    OLLAMA_SKIP_VERIFY=true \
    OLLAMA_DEBUG=debug \
    OLLAMA_KEEP_ALIVE=5m \
    OLLAMA_MAX_LOADED_MODELS=0 \
    OLLAMA_NUM_PARALLEL=1 \
    CUDA_VISIBLE_DEVICES= \
    GGML_VK_VISIBLE_DEVICES= \
    HIP_VISIBLE_DEVICES= \
    ROCR_VISIBLE_DEVICES=

# Minimal tools + pre-create SSH key (avoids entropy stalls under emulation)
RUN set -eu; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends curl ca-certificates openssh-client && \
      rm -rf /var/lib/apt/lists/*; \
    fi; \
    mkdir -p "${OLLAMA_HOME}"; \
    if [ ! -f "${OLLAMA_HOME}/id_ed25519" ]; then \
      echo "🔑 Precreating Ed25519 keypair at ${OLLAMA_HOME}"; \
      ssh-keygen -t ed25519 -N "" -f "${OLLAMA_HOME}/id_ed25519"; \
    fi

# Start serve, wait, preload, alias, stop
RUN set -eu; \
    echo ">> Starting ollama serve (background)"; \
    # IMPORTANT: no --host, rely on OLLAMA_HOST for 0.12.x compatibility
    nohup ollama serve >/tmp/ollama.log 2>&1 & \
    pid=$!; \
    echo ">> Waiting for readiness (up to ${STARTUP_WAIT_SECS}s)"; \
    end=$(( $(date +%s) + STARTUP_WAIT_SECS )); \
    ready=0; \
    while [ "$(date +%s)" -lt "$end" ]; do \
      # fail fast if process died
      if ! kill -0 "$pid" 2>/dev/null; then \
        echo "❌ ollama serve exited early"; \
        echo "----- /tmp/ollama.log -----"; tail -n +1 /tmp/ollama.log || true; \
        exit 1; \
      fi; \
      # readiness via log line or HTTP
      if grep -q "Listening on" /tmp/ollama.log 2>/dev/null; then ready=1; break; fi; \
      if command -v curl >/dev/null 2>&1 && curl -fsS http://127.0.0.1:11434/api/version >/dev/null 2>&1; then ready=1; break; fi; \
      sleep 2; \
    done; \
    if [ "$ready" -ne 1 ]; then \
      echo "❌ Ollama did not become ready within ${STARTUP_WAIT_SECS}s"; \
      echo "----- /tmp/ollama.log -----"; tail -n +1 /tmp/ollama.log || true; \
      exit 1; \
    fi; \
    echo "✅ Ollama is ready"; \
    for MODEL in ${MODEL_NAMES}; do \
      echo "⬇️  Pulling ${MODEL}"; \
      if ! ollama pull "${MODEL}"; then \
        echo "❌ pull failed for ${MODEL}"; \
        echo "----- /tmp/ollama.log (tail) -----"; tail -n 200 /tmp/ollama.log || true; \
        exit 1; \
      fi; \
      ollama show "${MODEL}" >/dev/null 2>&1 || { echo "❌ missing manifest for ${MODEL}"; exit 1; }; \
      # colon→dash alias (phi3:mini -> phi3-mini)
      ALIAS="$(printf '%s' "${MODEL}" | tr ':' '-')"; \
      if [ "${ALIAS}" != "${MODEL}" ]; then \
        echo "🔁 Creating alias ${ALIAS} for ${MODEL}"; \
        if ! ollama cp "${MODEL}" "${ALIAS}" 2>/tmp/ollama-cp.log; then \
          echo "⚠️  ollama cp failed, falling back to manifest alias"; \
          cat /tmp/ollama-cp.log || true; \
          mkdir -p "${OLLAMA_HOME}/models/manifests/library/${ALIAS}"; \
          NAME_UNDERSCORED="$(printf '%s' "${MODEL}" | tr ':' '_')"; \
          SRC_MANIFEST="$(find "${OLLAMA_HOME}/models/manifests" -type f -name "*${NAME_UNDERSCORED}*" | head -n1)"; \
          if [ -n "${SRC_MANIFEST:-}" ] && [ -f "${SRC_MANIFEST}" ]; then \
            cp "${SRC_MANIFEST}" "${OLLAMA_HOME}/models/manifests/library/${ALIAS}/manifest"; \
          fi; \
        fi; \
      fi; \
    done; \
    echo ">> Preloaded models:"; ollama list || true; \
    kill "$pid" 2>/dev/null || true; \
    wait "$pid" 2>/dev/null || true

# ===========================
# Stage 2 — Runtime
# ===========================
FROM --platform=$TARGETPLATFORM ollama/ollama:latest

ARG MODEL_NAMES="llama3 phi3:mini"
ARG DEFAULT_MODEL="llama3"

ENV OLLAMA_HOME=/root/.ollama \
    OLLAMA_MODELS=/root/.ollama/models \
    OLLAMA_SKIP_VERIFY=true \
    OLLAMA_KEEP_ALIVE=24h \
    OLLAMA_MAX_LOADED_MODELS=0 \
    OLLAMA_NUM_PARALLEL=1

COPY --from=builder /root/.ollama /root/.ollama

ENV OLLAMA_DEFAULT_MODEL=${DEFAULT_MODEL} \
    OLLAMA_PRELOADED_MODELS="${MODEL_NAMES}"

EXPOSE 11434
ENTRYPOINT ["ollama", "serve"]
