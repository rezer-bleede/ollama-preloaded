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
