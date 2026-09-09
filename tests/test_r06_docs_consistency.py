from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r06_status_docs_point_to_g0_without_promoting_studio_acceptance():
    session = read("docs/SESSION.md")
    feature = read("docs/FEATURE_LIST.md")
    readme = read("README.md")

    for text in [session, feature, readme]:
        # Preserve historical R01-R06 evidence while recording the current R08/R09 state.
        assert "R01" in text and "R05" in text
        assert "B17" in text and "G0" in text
        assert "66 passed, 0 failed" in text
        assert "R08" in text and "R09" in text
        assert "80 passed, 0 failed" in text

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

    r09_path = ROOT / "docs/DECISION_LOG_PRE_G0_REVIEW_R07_R09_2026-09-09.md"
    assert r09_path.is_file(), "status sync requires the bounded R07-R09 review record"
    r09 = r09_path.read_text(encoding="utf-8")
    for token in [
        "R07",
        "R08",
        "R09",
        "77 passed, 3 failed",
        "80 passed, 0 failed",
        "B17/G0 HUMAN_GATE",
        "six-external-tester",
    ]:
        assert token in r09, f"missing R09 decision-log token: {token}"
