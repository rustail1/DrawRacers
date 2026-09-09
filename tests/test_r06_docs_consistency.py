from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r06_status_docs_point_to_g0_without_promoting_studio_acceptance():
    session = read("docs/SESSION.md")
    feature = read("docs/FEATURE_LIST.md")
    readme = read("README.md")

    for text in [session, feature, readme]:
        assert "R01" in text and "R05" in text
        assert "B17" in text and "G0" in text
        assert "66 passed, 0 failed" in text

    assert "B17 — G0 HUMAN_GATE" in session
    assert "Studio PASS PENDING" in session
    assert "B17/G0" in feature
    assert "B17/G0" in readme
    assert "Current implementation item\n**B14" not in readme


def test_r06_core_audit_decision_log_records_no_scope_expansion():
    path = ROOT / "docs/DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md"
    assert path.is_file(), "R06 requires the CORE audit repair decision log"
    text = path.read_text(encoding="utf-8")
    for token in [
        "GeometryMath",
        "square semantic DrawInputRect",
        "D05 RacerService",
        "R01",
        "R05",
        "no new WHAT/WHY",
        "Studio evidence pending",
    ]:
        assert token in text, f"missing R06 decision-log token: {token}"
