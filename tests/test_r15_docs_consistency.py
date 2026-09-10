from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r15_owner_docs_define_planar_locomotion_without_passing_g0() -> None:
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    balance = read("docs/16_BALANCE_TUNING.md")
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    decision_path = ROOT / "docs" / "DECISION_LOG_R15_PLANAR_RACER_PHYSICS_2026-09-10.md"

    # R15 remains the historical owner of the mechanical X/Y plane + Z lane lock.
    # R16 supersedes only the body-rotation semantics in current owner docs.
    assert "X/Y are the physical gameplay plane" in core
    assert "Z translation is locked" in core
    assert "rotation about world Z is locked/corrected" in core

    for token in [
        "PlaneConstraint",
        "LaneNormalError = 0.03",
        "LaneHardBound = 0.08",
        "OrientationResponsiveness = 40",
        "OrientationMaxTorque = 60000",
        "OrientationMaxAngularVelocity = 30",
    ]:
        assert token in balance

    for obsolete in [
        "LaneMaxForceZ = 60000",
        "LaneResponsiveness = 40",
        "LaneMaxVelocity = 30",
        "Z-only `AlignPosition`",
    ]:
        assert obsolete not in balance

    assert "soft correction begins at `|Z error| > 0.15 stud`" not in balance
    assert "normal allowed error <=`0.35 stud`; hard safety bound `0.75 stud`" not in balance

    evidence_sha = "be44304bf00391e05c7d7750609730a7368ebc87"
    evidence_run = "34394991926"
    for text in (session, features):
        assert "R15.1" in text
        assert "laneDeviation 5.199" in text
        assert evidence_sha in text
        assert evidence_run in text
        assert "125 passed, 0 failed" in text
        assert "HUMAN STUDIO PENDING" in text

    assert decision_path.is_file(), "missing R15 planar physics decision record"
    decision = decision_path.read_text(encoding="utf-8")
    assert "R15.1" in decision
    assert "laneDeviation 5.199" in decision
    assert "PlaneConstraint" in decision
    assert "rotation around world Z = physical/free in-plane tumble" in decision
    assert "8574b918988b8e26551140f2e0d3005caded8fe8" in decision
    assert "34394769781" in decision
    assert "123 passed, 2 failed" in decision
    assert evidence_sha in decision
    assert evidence_run in decision
    assert "125 passed, 0 failed" in decision
    assert "R15.1 IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING" in decision
    assert "B17/G0: PENDING" in decision
