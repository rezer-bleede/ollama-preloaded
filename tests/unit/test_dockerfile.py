from pathlib import Path


DOCKERFILE_PATH = Path(__file__).resolve().parents[2] / "Dockerfile"


def read_dockerfile() -> str:
    return DOCKERFILE_PATH.read_text(encoding="utf-8")


def test_models_directory_is_explicitly_configured():
    content = read_dockerfile()
    assert "OLLAMA_HOME=/root/.ollama" in content
    assert "OLLAMA_MODELS=/root/.ollama/models" in content


def test_entrypoint_uses_models_flag():
    content = read_dockerfile()
    assert 'ENTRYPOINT ["ollama", "serve", "--models", "/root/.ollama"]' in content


def test_multi_model_build_arguments_are_available():
    content = read_dockerfile()
    assert "ARG MODEL_NAMES" in content
    assert "ARG DEFAULT_MODEL" in content


def test_runtime_exports_preloaded_model_list():
    content = read_dockerfile()
    assert 'OLLAMA_PRELOADED_MODELS="$MODEL_NAMES"' in content


def test_builder_verifies_models_after_pull():
    content = read_dockerfile()
    assert "ollama pull \"$MODEL_NAME\"" in content
    assert "ollama show \"$MODEL_NAME\"" in content
    assert "ollama list" in content


def test_builder_waits_for_server_readiness():
    content = read_dockerfile()
    assert "Ollama did not become ready" in content
