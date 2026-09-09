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

    assert "X/Y are the physical gameplay plane" in core
    assert "Z translation is locked" in core
    assert "rotation around world Z remains physical and free" in core

    for token in [
        "LaneNormalError = 0.03",
        "LaneHardBound = 0.08",
        "LaneMaxForceZ = 60000",
        "LaneResponsiveness = 40",
        "LaneMaxVelocity = 30",
        "OrientationResponsiveness = 40",
        "OrientationMaxTorque = 60000",
        "OrientationMaxAngularVelocity = 30",
    ]:
        assert token in balance

    assert "soft correction begins at `|Z error| > 0.15 stud`" not in balance
    assert "normal allowed error <=`0.35 stud`; hard safety bound `0.75 stud`" not in balance
    assert "R15" in session and "HUMAN STUDIO PENDING" in session
    assert "B17/G0" in session and "PENDING" in session
    assert "R15" in features and "HUMAN STUDIO PENDING" in features
    assert decision_path.is_file(), "missing R15 planar physics decision record"

    decision = decision_path.read_text(encoding="utf-8")
    assert "laneDeviation 0.418" in decision
    assert "R15 IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING" in decision
    assert "B17/G0: PENDING" in decision
