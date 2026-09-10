from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_core_lab_dod_requires_exact_upright_acceptance() -> None:
    dod = read("docs/15_DEFINITION_OF_DONE.md")
    core_lab = dod.split("## Core Lab DoD", 1)[1].split("## Adaptation Acceptance DoD", 1)[0]

    assert "R16.1 upright-body acceptance" in core_lab
    assert "normal angular deviation <= 1.0 degree" in core_lab
    assert "strong-contact disturbance <= 3.0 degrees" in core_lab
    assert "return to <= 1.0 degree within 0.25 s" in core_lab
    assert "X/Y translation remains physical/free" in core_lab
