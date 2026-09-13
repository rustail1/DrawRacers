from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_bg01_redraw_counter_rotates_new_geometry_against_live_axle_phase() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")

    assert "local currentAxlePhaseDegrees = self:GetPhaseDegrees()" in pair
    assert "local redrawBasePhaseDegrees = -currentAxlePhaseDegrees" in pair
    assert "phaseDegrees = redrawBasePhaseDegrees" in pair
    assert "phaseDegrees = redrawBasePhaseDegrees + motor.RightPhaseOffsetDegrees" in pair


def test_bg01_redraw_keeps_axle_and_motor_while_realigning_only_new_geometry() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")

    assert "BeginGeometryReshape" in pair
    assert "self.axleRoot" in pair
    assert "self.joint" in pair
    assert "self.legPair:BeginGeometryReshape(shapeSpec)" in runtime
    assert "initialPhaseDegrees" not in runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
