from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
README_PATH = PROJECT_ROOT / "README.md"


def test_readme_mentions_models_flag():
    content = README_PATH.read_text(encoding="utf-8")
    assert "--models /root/.ollama" in content, "README should document the explicit models directory"


def test_readme_curl_example_uses_correct_port():
    content = README_PATH.read_text(encoding="utf-8")
    assert "http://localhost:11434/api/generate" in content
