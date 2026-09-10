from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r13_status_docs_record_r10_r12_without_passing_g0() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")

    for text in (session, features):
        assert "R01–R12" in text
        assert "R10" in text
        assert "R11" in text
        assert "R12" in text
        assert "88 passed, 0 failed" in text
        assert "e2bedd34696bb99da43878c19d7984c9134c8bef" in text
        assert "34363706915" in text
        assert "B17" in text and "G0" in text and "HUMAN_GATE" in text

    assert "B17 — G0 HUMAN_GATE — Studio PASS PENDING" in session
    assert "BACKLOG / HUMAN_GATE — B17/G0" in features
    assert "ACCEPTED — B17" not in features


def test_r13_decision_record_keeps_bug_sweep_inside_existing_core_scope() -> None:
    decision = read("docs/DECISION_LOG_PRE_G0_BUG_SWEEP_R10_R12_2026-09-09.md")

    for token in [
        "R10",
        "R11",
        "R12",
        "88 passed, 0 failed",
        "e2bedd34696bb99da43878c19d7984c9134c8bef",
        "34363706915",
        "B17/G0",
        "C01",
        "no new WHAT/WHY",
    ]:
        assert token in decision, f"missing R13 decision evidence: {token}"

    assert "B17/G0 remains pending" in decision
