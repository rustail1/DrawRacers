from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_mr02_leg_assembly_is_one_persistent_geometry_owner() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    for token in [
        "function LegAssembly.new", "function LegAssembly:InstallGeometry",
        "function LegAssembly:StageGeometry", "function LegAssembly:SetStageProgress",
        "function LegAssembly:CommitStagedGeometry", "function LegAssembly:CancelStagedGeometry",
        "function LegAssembly:Destroy",
    ]:
        assert token in leg
    for forbidden in ["HingeConstraint", "RemoteEvent", "LegShapeService", "RacerRuntime", "otherDrive", "socketZ", "axleRoot"]:
        assert forbidden not in leg


def test_mr02_staging_is_visual_only_until_commit() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    stage = leg.split("function LegAssembly:SetStageProgress", 1)[1].split("function LegAssembly:CommitStagedGeometry", 1)[0]
    commit = leg.split("function LegAssembly:CommitStagedGeometry", 1)[1].split("function LegAssembly:CancelStagedGeometry", 1)[0]
    assert 'makeFolder("StageVisual"' in stage
    assert "self.segmentsFolder:Destroy()" not in stage
    assert "setPhysicalEnabled(self.segments, self.segmentPlan, false)" in commit
    assert "setPhysicalEnabled(pendingParts, pendingPlan, true)" in commit
    assert "ReshapeTipCollider" not in leg


def test_mr02_pair_is_the_only_direct_consumer_of_side_geometry() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "leftDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert "rightDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert "self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)" in pair
    assert "self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)" in pair
