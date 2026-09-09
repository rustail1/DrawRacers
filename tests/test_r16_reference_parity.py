from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_1_body_orientation_is_upright_not_free_about_z() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    b10 = read("src/server/Tests/B10StabilizationSpec.lua")

    assert "Enum.AlignType.AllAxes" in stabilizer
    assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" not in stabilizer
    assert "upright body angular deviation" in b10
    assert "x/y translation must remain physically free" in b10
    assert "in-plane rotation around Z must remain unconstrained" not in b10


def test_r16_1_upright_attachment_uses_identity_basis_for_all_axes() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    b10 = read("src/server/Tests/B10StabilizationSpec.lua")

    assert "orientationAttachment.Axis = Vector3.xAxis" in stabilizer
    assert "orientationAttachment.SecondaryAxis = Vector3.yAxis" in stabilizer
    assert "orientationAttachment.Axis = Vector3.zAxis" not in stabilizer
    assert "orientation attachment X axis must stay canonical" in b10
    assert "orientation attachment Y axis must stay canonical" in b10


def test_r16_2_hub_offsets_have_one_numeric_owner() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    b06 = read("src/server/Tests/B06RacerRuntimeSpec.lua")

    for token in [
        "HubOffsetX = 0.0",
        "HubOffsetY = -0.35",
        "HubOffsetZAbs = 1.62",
    ]:
        assert token in config

    assert "local geometry = PhysicsConfig.LegGeometry" in runtime
    assert "geometry.HubOffsetX" in runtime
    assert "geometry.HubOffsetY" in runtime
    assert "geometry.HubOffsetZAbs" in runtime
    assert "Vector3.new(0, -0.75, -1.62)" not in runtime
    assert "Vector3.new(0, -0.75, 1.62)" not in runtime
    assert "local geometry = PhysicsConfig.LegGeometry" in b06
    assert "geometry.HubOffsetY" in b06


def test_r16_3_one_shape_builds_two_same_xy_legs_about_fixed_pivot() -> None:
    geometry = read("src/shared/Math/GeometryMath.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")

    assert "local mapped = clamped * geometry.LegCanvasHalfSpan" in geometry
    assert "stagedLeftLeg = LegAssembly.new" in runtime
    assert "stagedRightLeg = LegAssembly.new" in runtime
    assert runtime.count("shapeSpec = shapeSpec") >= 2
    assert "root.CFrame = hub.CFrame" in leg
    assert "assertSamePoints(leftLeg:GetMappedPoints(), rightLeg:GetMappedPoints())" in b09

    apply_shape_spec = runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]
    assert "shapeSpec.normalizedPoints" not in apply_shape_spec


def test_r16_3a_server_centers_shape_by_bounds_without_resizing() -> None:
    stroke_math = read("src/shared/Math/StrokeMath.lua")
    service = read("src/server/Services/LegShapeService.lua")
    b11 = read("src/server/Tests/B11LegShapeServiceSpec.lua")

    assert "function StrokeMath.CenterOnBounds" in stroke_math
    assert "local center = (bounds.min + bounds.max) * 0.5" in stroke_math
    assert "point - center" in stroke_math
    assert "local centered = StrokeMath.CenterOnBounds(cleaned)" in service
    assert "GeometryMath.BuildSegmentPlan(centered, PhysicsConfig.LegGeometry)" in service
    assert "normalizedPoints = centered" in service
    assert "shifted shape must center to same normalized geometry" in b11
    assert "centering must preserve shape width" in b11
    assert "centering must preserve shape height" in b11


def test_r16_4_phase_is_180_and_redraw_retains_each_side() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")
    b13 = read("src/server/Tests/B13AtomicRedrawSpec.lua")

    assert "RightPhaseOffsetDegrees = 180" in config
    assert "angularDistanceDegrees" in b09
    assert "phase difference" in b09
    assert "angularDistanceDegrees(leftPhaseAfter, leftPhaseBefore)" in b13
    assert "angularDistanceDegrees(rightPhaseAfter, rightPhaseBefore)" in b13
