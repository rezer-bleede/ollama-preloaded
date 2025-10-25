# ===========================
# Stage 1 — Builder
# ===========================
FROM --platform=$BUILDPLATFORM ollama/ollama:latest AS builder

# Space-separated list of models to preload (e.g. "llama3 phi3:mini")
ARG MODEL_NAMES="phi3:mini"
# Readiness timeout (seconds)
ARG STARTUP_WAIT_SECS=1200

# Build-time env hardening
ENV OLLAMA_SKIP_VERIFY=true \
    OLLAMA_HOME=/root/.ollama \
    OLLAMA_MODELS=/root/.ollama/models \
    OLLAMA_HOST=127.0.0.1:11434 \
    OLLAMA_LOAD_TIMEOUT=20m \
    OLLAMA_MAX_LOADED_MODELS=0 \
    OLLAMA_NUM_PARALLEL=1 \
    CUDA_VISIBLE_DEVICES= \
    GGML_VK_VISIBLE_DEVICES= \
    HIP_VISIBLE_DEVICES= \
    ROCR_VISIBLE_DEVICES=

# 1) Ensure tools + precreate Ed25519 keypair to avoid entropy stalls under QEMU
#    (openssh-client provides ssh-keygen; sed/grep already present)
RUN set -euo pipefail; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends openssh-client ca-certificates && \
      rm -rf /var/lib/apt/lists/*; \
    fi; \
    mkdir -p "${OLLAMA_HOME}"; \
    if [ ! -f "${OLLAMA_HOME}/id_ed25519" ]; then \
      echo "🔑 Precreating Ed25519 keypair at ${OLLAMA_HOME}"; \
      ssh-keygen -t ed25519 -N "" -f "${OLLAMA_HOME}/id_ed25519"; \
    fi

# 2) Start serve (IPv4), wait robustly (log OR HTTP), then pull models
RUN set -euo pipefail; \
    echo ">> Starting ollama serve (background)"; \
    nohup ollama serve --host 127.0.0.1 >/tmp/ollama.log 2>&1 & \
    pid=$!; \
    echo ">> Waiting for readiness (up to ${STARTUP_WAIT_SECS}s)"; \
    end=$(( $(date +%s) + STARTUP_WAIT_SECS )); \
    ready=0; \
    while [ "$(date +%s)" -lt "$end" ]; do \
      # accept either the server log cue or the HTTP endpoint
      if grep -q "Listening on" /tmp/ollama.log 2>/dev/null; then ready=1; break; fi; \
      if curl -fsS http://127.0.0.1:11434/api/version >/dev/null 2>&1; then ready=1; break; fi; \
      sleep 2; \
    done; \
    if [ "$ready" -ne 1 ]; then \
      echo "❌ Ollama did not become ready within ${STARTUP_WAIT_SECS}s"; \
      echo "----- /tmp/ollama.log (tail) -----"; tail -n +1 /tmp/ollama.log || true; \
      exit 1; \
    fi; \
    echo "✅ Ollama is ready"; \
    for MODEL in ${MODEL_NAMES}; do \
      echo "⬇️  Pulling ${MODEL}"; \
      ollama pull "${MODEL}" || { echo "❌ pull failed for ${MODEL}"; tail -n +200 /tmp/ollama.log || true; exit 1; }; \
      # verify manifest presence
      ollama show "${MODEL}" >/dev/null 2>&1 || { echo "❌ missing manifest for ${MODEL}"; exit 1; }; \
      # optional alias: colon → dash (phi3:mini -> phi3-mini)
      ALIAS="$(printf '%s' "${MODEL}" | tr ':' '-')"; \
      if [ "${ALIAS}" != "${MODEL}" ]; then \
        echo "🔁 Creating alias ${ALIAS} for ${MODEL}"; \
        if ! ollama cp "${MODEL}" "${ALIAS}" 2>/tmp/ollama-cp.log; then \
          echo "⚠️  ollama cp failed, falling back to manifest alias"; \
          cat /tmp/ollama-cp.log || true; \
          mkdir -p "${OLLAMA_HOME}/models/manifests/library/${ALIAS}"; \
          SRC_MANIFEST="$(find "${OLLAMA_HOME}/models/manifests" -type f -name '*'"$(printf '%s' "${MODEL}" | tr ':' '_')" '*'" | head -n1)"; \
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

ARG MODEL_NAMES="phi3:mini"
ARG DEFAULT_MODEL="phi3:mini"

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
