from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_3b_history_is_superseded_by_cr2_fixed_visible_pivot() -> None:
    decision = read("docs/DECISION_LOG_R16_3B_STROKE_ORIGIN_REFERENCE_PARITY_2026-09-10.md")
    cr2 = read("docs/superpowers/specs/2026-09-14-core-repair-v2-twin-pivot-design.md")
    shape = read("docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md")
    assert "R16.3B" in decision
    assert "supersed" in cr2.lower()
    assert "fixed pivot" in cr2.lower()
    assert "CORE REPAIR v2" in shape
    assert "fixed pivot" in shape.lower()


def test_r16_3b_shared_math_keeps_wide_isotropic_surface_but_no_longer_translates_shape() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    stroke_math = read("src/shared/Math/StrokeMath.lua")
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    geometry = read("src/shared/Math/GeometryMath.lua")
    assert "RawSemanticHalfWidth = 1.75" in config
    assert "RawSemanticHalfHeight = 1.0" in config
    assert "PivotStartRadiusNormalized" in config
    assert "function StrokeMath.ClampToRect" in stroke_math
    assert "local unit = canvasSize.Y * 0.5" in stroke_math
    assert "START_OFF_PIVOT" in builder
    assert "AnchorToFirstPoint" not in builder
    assert "presentationAnchor" not in builder
    assert "Vector2.zero" in builder
    map_point = geometry.split("function GeometryMath.MapPoint", 1)[1].split("function GeometryMath.BuildSegmentPlan", 1)[0]
    assert "MaxLegExtentFromHub" in map_point


def test_r16_3b_authoritative_shape_uses_fixed_pivot_without_network_schema_expansion() -> None:
    service = read("src/server/Services/LegShapeService.lua")
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    types = read("src/shared/Types/StrokeTypes.lua")
    network = read("docs/22_NETWORK_DATA_CONTRACTS.md")
    assert "CanonicalLegShape.Build" in service
    assert "START_OFF_PIVOT" in builder
    assert "GeometryMath.BuildSegmentPlan" in builder
    assert "mapped / geometryConfig.LegCanvasHalfSpan" in builder
    assert "AnchorToFirstPoint" not in builder
    submit = types.split("export type SubmitStrokePayload", 1)[1].split("export type StrokeResultPayload", 1)[0]
    assert "sequence" in submit and "points" in submit
    assert "pivot" not in submit.lower()
    assert "CORE REPAIR v2" in network
    assert "payload schema unchanged" in network.lower()


def test_r16_3b_draw_ui_uses_full_wide_surface_and_visible_fixed_pivot() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "SemanticSquareConstraint" not in drawing
    assert "R16WideDrawSurfaceConstraint" in drawing
    assert 'pivotMarker.Name = "PivotMarker"' in drawing
    assert "START FROM THE DOT" in drawing
    assert "PivotStartRadiusNormalized" in drawing
    assert "_presentationAnchors" not in drawing
    assert "presentationAnchor" not in drawing
    assert "inputController:Bind(drawInputRect)" in drawing


def test_r16_3b_leg_visual_is_nonphysical_and_physical_colliders_are_hidden() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "VisualSegment_" in leg
    assert "VisualJoint_" in leg
    assert "visual.CanCollide = false" in leg
    assert "visual.CanTouch = false" in leg
    assert "visual.CanQuery = false" in leg
    assert "visual.Massless = true" in leg
    assert "part.Transparency = 1" in leg


def test_r16_3b_g0_proxy_uses_production_side_camera_owner() -> None:
    presentation = read("src/client/Dev/M0G0PresentationHarness.lua")
    camera = read("src/client/Controllers/RaceCameraController.lua")
    assert "local FIELD_OF_VIEW = 60" in camera
    assert "camera.CameraType = Enum.CameraType.Scriptable" in camera
    assert "camera.CFrame = CFrame.lookAt" in camera
    assert "camera.CameraType" not in presentation
    assert "camera.CFrame" not in presentation


def test_r16_3b_debug_panel_is_hidden_by_default_and_f3_only_toggles_presentation() -> None:
    panel = read("src/client/Controllers/DebugTuningPanel.lua")
    assert "gui.Enabled = false" in panel
    assert "Enum.KeyCode.F3" in panel
    assert "gui.Enabled = not gui.Enabled" in panel


def test_r16_3b_r16final_orders_automated_evidence_before_human_ready() -> None:
    modes = read("src/shared/Config/StudioHarnessConfig.lua")
    final = read("src/server/Tests/R16FinalHarness.lua")
    assert 'R16FINAL = "R16FINAL"' in modes
    assert 'Mode = "G0"' in modes
    assert "R16StageCHarness.RunEvidence()" in final
    assert "M0HumanHarness.start()" in final
    assert final.index("R16StageCHarness.RunEvidence()") < final.index("M0HumanHarness.start()")


def test_r16_3b_cr2_shape_and_motor_tuning_supersedes_failed_g0_values() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    for token in [
        "TargetTipSpeed = 10.5", "MinAngularVelocity = 1.5", "MaxAngularVelocity = 6.0",
        "RightPhaseOffsetDegrees = 180", "LegCanvasHalfSpan = 3.2", "MaxLegExtentFromHub = 4.5",
        "PhysicalLegSegmentThickness = 0.54", "VisualLegSegmentThickness = 0.78",
        "MaxColliderSegmentsPerLeg = 14", "InnerHubNoCollisionRadius = 0.65", "SegmentOverlapAllowance = 0.06",
    ]:
        assert token in config
    assert "geometry.VisualLegSegmentThickness" in leg
    assert pair.count("LegDriveAssembly.new") == 2
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in pair


def test_r16_3b_b14_separates_physical_and_visual_part_accounting() -> None:
    b14 = read("src/server/Tests/B14RedrawStressSpec.lua")
    assert "local function countPhysicalLegParts" in b14
    assert "local function countVisualLegParts" in b14
    assert "MAX_PHYSICAL_LEG_PARTS" in b14
    assert "MAX_VISUAL_LEG_PARTS" in b14


def test_r16_3b_graphite_presentation_survives_cr2() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "local DEFAULT_GRAPHITE_COLOR = Color3.fromRGB(23, 32, 51)" in drawing
    assert "local DRAW_SURFACE_COLOR = Color3.fromRGB(243, 240, 232)" in drawing
    assert "local FRONT_VISUAL_COLOR = Color3.fromRGB(23, 32, 51)" in leg
    assert "local BACK_VISUAL_COLOR = Color3.fromRGB(57, 68, 84)" in leg
    assert 'visualColor = if params.side == "Left" then BACK_VISUAL_COLOR else FRONT_VISUAL_COLOR' in leg
    assert "part.Transparency = 1" in leg
    assert "visual.CanCollide = false" in leg
