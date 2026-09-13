from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_b13_transactional_redraw_preserves_body_and_drive_identity() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    apply_shape = section(runtime, "function RacerRuntime:_ApplyShapeSpec", "function RacerRuntime:ApplyShape")
    for token in ["self.legPair:StageRedraw(shapeSpec)", "self.legPair:SetStageProgress", "self.legPair:CommitStagedRedraw()", "return self.legPair:GetLeftLeg(), self.legPair:GetRightLeg(), nil"]:
        assert token in apply_shape
    assert "LegPairAssembly.new" not in apply_shape
    for forbidden in ["self.body.CFrame =", "body.CFrame =", "AssemblyLinearVelocity =", "AssemblyAngularVelocity =", "body:PivotTo("]:
        assert forbidden not in apply_shape
    stage = section(pair, "function LegPairAssembly:StageRedraw", "function LegPairAssembly:SetStageProgress")
    assert "LegDriveAssembly.new" not in stage
    assert "self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)" in stage
    assert "self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)" in stage
    assert "function LegAssembly:CommitStagedGeometry" in leg
    assert "ReshapeTipCollider" not in leg


def test_b13_old_physics_survives_visual_stage_until_commit() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    stage = section(leg, "function LegAssembly:SetStageProgress", "function LegAssembly:CommitStagedGeometry")
    commit = section(leg, "function LegAssembly:CommitStagedGeometry", "function LegAssembly:CancelStagedGeometry")
    assert "self.segmentsFolder:Destroy()" not in stage
    assert "setPhysicalEnabled(self.segments, self.segmentPlan, false)" in commit
    assert "setPhysicalEnabled(pendingParts, pendingPlan, true)" in commit
    assert commit.index("setPhysicalEnabled(self.segments, self.segmentPlan, false)") < commit.index("self.segmentsFolder:Destroy()")


def test_b13_studio_spec_is_wired() -> None:
    assert (ROOT / "src/server/Tests/B13AtomicRedrawSpec.lua").is_file()
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "B13AtomicRedrawSpec" in bootstrap
    assert "B13AtomicRedrawSpec.run()" in bootstrap
