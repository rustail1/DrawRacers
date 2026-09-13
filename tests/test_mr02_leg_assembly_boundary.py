from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_mr02_leg_assembly_is_one_persistent_side_owner() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")

    for required in [
        "function LegAssembly.new",
        "function LegAssembly:ReplaceGeometry",
        "function LegAssembly:SetReshapeProgress",
        "function LegAssembly:CompleteReshape",
        "function LegAssembly:Destroy",
        'WaitForChild("LegReshapeMath")',
        "LegReshapeMath.Evaluate",
        '"AxleWeld"',
        '"Segments"',
        '"Visual"',
    ]:
        assert required in leg, f"missing MR-02 boundary token: {required}"

    for forbidden in [
        "staged",
        "function LegAssembly:Commit",
        "function LegAssembly:IsCommitted",
        "function LegAssembly:SetRetiring",
        "_Retiring",
        'Instance.new("HingeConstraint")',
        "ActuatorType",
    ]:
        assert forbidden not in leg, f"legacy/non-owner behavior remains in LegAssembly: {forbidden}"


def test_mr02_future_geometry_is_not_prebuilt_and_hidden() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    constructor = leg[leg.index("function LegAssembly.new"):leg.index("function LegAssembly:GetModel")]

    assert "shapeSpec.segmentPlan" not in constructor
    assert "params.shapeSpec" not in constructor
    assert "materializeCompleteSegment" in leg
    assert "clearGeometry" in leg
    assert "partialEndpoint" in leg


def test_mr02_direct_consumer_no_longer_calls_retired_side_api() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")

    for forbidden in [
        "leftLeg:Commit()",
        "rightLeg:Commit()",
        "leftLeg:IsCommitted()",
        "rightLeg:IsCommitted()",
        "leftLeg:SetRetiring(",
        "rightLeg:SetRetiring(",
        "oldLeft:SetRetiring(",
        "oldRight:SetRetiring(",
        "buildStagedSides",
    ]:
        assert forbidden not in pair, f"LegPairAssembly still calls retired LegAssembly API: {forbidden}"

    assert "self.leftLeg:ReplaceGeometry(shapeSpec)" in pair
    assert "self.rightLeg:ReplaceGeometry(shapeSpec)" in pair
