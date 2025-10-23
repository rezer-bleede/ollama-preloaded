FROM ollama/ollama:latest

# Preload the model at build time
RUN ollama pull llama3

# Optional: set default model
ENV OLLAMA_DEFAULT_MODEL=llama3

# Expose API port
EXPOSE 11434

# Run Ollama server
ENTRYPOINT ["ollama", "serve"]
