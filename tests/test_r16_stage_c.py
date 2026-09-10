from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_8_moving_redraw_parity_is_stress_verified() -> None:
    b13 = read("src/server/Tests/B13AtomicRedrawSpec.lua")
    b14 = read("src/server/Tests/B14RedrawStressSpec.lua")

    # B13 remains the atomic/rollback owner and must continue to prove phase + body state.
    assert "angularDistanceDegrees(leftPhaseAfter, leftPhaseBefore)" in b13
    assert "angularDistanceDegrees(rightPhaseAfter, rightPhaseBefore)" in b13
    assert "successful redraw teleported body CFrame" in b13
    assert "successful redraw reset AssemblyLinearVelocity" in b13
    assert "successful redraw reset AssemblyAngularVelocity" in b13

    # R16.8 requires repeated redraws while the body has non-zero motion state, not only
    # anchored abuse/stress replacement checks.
    assert "runMovingRedrawParity" in b14
    assert "for redrawIndex = 1, 10 do" in b14
    assert "movingBody.AssemblyLinearVelocity" in b14
    assert "movingBody.AssemblyAngularVelocity" in b14
    assert "bodyCFrameBeforeRedraw" in b14
    assert "linearBeforeRedraw" in b14
    assert "angularBeforeRedraw" in b14
    assert "leftPhaseBeforeRedraw" in b14
    assert "rightPhaseBeforeRedraw" in b14
    assert "angularDistanceDegrees(leftPhaseAfterRedraw, leftPhaseBeforeRedraw) <= 5.0" in b14
    assert "angularDistanceDegrees(rightPhaseAfterRedraw, rightPhaseBeforeRedraw) <= 5.0" in b14
    assert "moving redraw must leave exactly two leg models" in b14
    assert "moving redraw leaked retiring LeftLeg" in b14
    assert "moving redraw leaked retiring RightLeg" in b14
