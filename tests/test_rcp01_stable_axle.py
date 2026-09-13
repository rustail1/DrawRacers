from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _function_body(source: str, signature: str) -> str:
    start = source.index(signature)
    tail = source[start:]
    marker = "\nend\n\nfunction "
    end = tail.find(marker)
    return tail if end < 0 else tail[: end + len("\nend")]


def test_rcp01_redraw_reuses_existing_axle_and_joint() -> None:
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    apply_body = _function_body(runtime, "function RacerRuntime:_ApplyShapeSpec")

    assert "BeginGeometryReshape" in pair
    assert "self.legPair:BeginGeometryReshape" in apply_body
    assert "LegPairAssembly.new" not in apply_body


def test_rcp01_redraw_reuses_existing_side_owners() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    body = _function_body(pair, "function LegPairAssembly:BeginGeometryReshape")

    assert "self.leftLeg:ReplaceGeometry(shapeSpec)" in body
    assert "self.rightLeg:ReplaceGeometry(shapeSpec)" in body
    assert "self.leftLeg:SetReshapeProgress(0)" in body
    assert "self.rightLeg:SetReshapeProgress(0)" in body
    assert "LegAssembly.new" not in body
    assert "stagedLeft" not in body and "stagedRight" not in body
    assert "oldLeft" not in body and "oldRight" not in body


def test_rcp01_stable_motor_remains_single_owner() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src/server/Runtime/LegAssembly.lua").read_text(encoding="utf-8")
    reshape_body = _function_body(pair, "function LegPairAssembly:BeginGeometryReshape")

    assert pair.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in leg
    assert 'Instance.new("HingeConstraint")' not in reshape_body
    assert "LegAssembly.new" not in reshape_body
    assert "buildStagedSides" not in pair
