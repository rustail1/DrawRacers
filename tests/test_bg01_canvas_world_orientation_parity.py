from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_bg01_redraw_reuses_persistent_side_geometry_owners() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    begin = pair[pair.index("function LegPairAssembly:BeginGeometryReshape"):pair.index("function LegPairAssembly:SetReshapeProgress")]

    assert "self.leftLeg:ReplaceGeometry(shapeSpec)" in begin
    assert "self.rightLeg:ReplaceGeometry(shapeSpec)" in begin
    assert "buildStagedSides" not in pair
    assert "redrawBasePhaseDegrees" not in pair


def test_bg01_structural_phase_stays_owned_by_pair_not_redraw_handoff() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")

    assert "phaseDegrees = 0" in pair
    assert "phaseDegrees = motor.RightPhaseOffsetDegrees" in pair
    assert "self.axleRoot" in pair
    assert "self.joint" in pair
    assert "self.legPair:BeginGeometryReshape(shapeSpec)" in runtime
    assert "initialPhaseDegrees" not in runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
