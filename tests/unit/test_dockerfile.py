from pathlib import Path


DOCKERFILE_PATH = Path(__file__).resolve().parents[2] / "Dockerfile"


def read_dockerfile() -> str:
    return DOCKERFILE_PATH.read_text(encoding="utf-8")


def test_models_directory_is_explicitly_configured():
    content = read_dockerfile()
    assert "OLLAMA_HOME=/root/.ollama" in content
    assert "OLLAMA_MODELS=/root/.ollama/models" in content


def test_entrypoint_relies_on_environment_configuration():
    content = read_dockerfile()
    assert 'ENTRYPOINT ["ollama", "serve"]' in content
    assert '--models' not in content


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


def test_builder_uses_extended_startup_window():
    content = read_dockerfile()
    assert "seq 1 150" in content
    assert "($i/150)" in content


def test_builder_checks_localhost_loopback_and_ipv6():
    content = read_dockerfile()
    assert 'for URL in \\' in content
    assert '"http://localhost:11434/api/tags"' in content
    assert '"http://127.0.0.1:11434/api/tags"' in content
    assert '"http://[::1]:11434/api/tags"' in content


def test_builder_logs_success_with_url_context():
    content = read_dockerfile()
    assert '✅ Ollama is ready via $URL' in content


def test_builder_uses_posix_compliant_shell_flags():
    content = read_dockerfile()
    assert "set -eu;" in content
    assert "pipefail" not in content
