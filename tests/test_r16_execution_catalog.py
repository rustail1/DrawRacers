from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_b10_execution_catalog_requires_full_upright_body_contract() -> None:
    catalog = read("docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md")
    b10_row = next(line for line in catalog.splitlines() if line.startswith("| B10 |"))

    assert "world X/Y/Z" in b10_row
    assert "upright" in b10_row.lower()
    assert "Z/pitch/roll bounds" not in b10_row
