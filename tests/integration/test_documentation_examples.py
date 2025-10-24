from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
README_PATH = PROJECT_ROOT / "README.md"


def test_readme_documents_models_environment_variable():
    content = README_PATH.read_text(encoding="utf-8")
    assert "OLLAMA_MODELS" in content, "README should reference the environment-based configuration"


def test_readme_curl_example_uses_correct_port():
    content = README_PATH.read_text(encoding="utf-8")
    assert "http://localhost:11434/api/generate" in content


def test_readme_lists_data_modeling_variants():
    content = README_PATH.read_text(encoding="utf-8")
    assert "sqlcoder" in content
    assert "deepseek-coder-6.7b" in content
    assert "llama3.1-8b-instruct" in content


def test_readme_documents_multi_model_build_flow():
    content = README_PATH.read_text(encoding="utf-8")
    assert "--build-arg MODEL_NAMES" in content
    assert "--build-arg DEFAULT_MODEL" in content
    assert "OLLAMA_PRELOADED_MODELS" in content
