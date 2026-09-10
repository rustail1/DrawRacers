from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_3b_contract_supersedes_bounds_center_and_square_surface() -> None:
    decision = read("docs/DECISION_LOG_R16_3B_STROKE_ORIGIN_REFERENCE_PARITY_2026-09-10.md")
    shape = read("docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md")
    layout = read("docs/59_UI_LAYOUT_WIREFRAME_SPEC.md")
    hierarchy = read("docs/68_UI_COMPONENT_HIERARCHY_IMPLEMENTATION_SPEC.md")

    for doc in [decision, shape]:
        assert "R16.3B" in doc
        assert "first" in doc.lower() and "point" in doc.lower()
        assert "bounds-center" in doc.lower() or "bounds center" in doc.lower()
        assert "supersed" in doc.lower()

    assert "wide semantic DrawInputRect" in layout
    assert "wide semantic DrawInputRect" in hierarchy
    assert "square semantic DrawInputRect" not in layout
    assert "square semantic DrawInputRect" not in hierarchy


def test_r16_3b_shared_math_uses_wide_isotropic_input_and_first_point_origin() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    math = read("src/shared/Math/StrokeMath.lua")
    geometry = read("src/shared/Math/GeometryMath.lua")

    assert "RawSemanticHalfWidth = 1.75" in config
    assert "RawSemanticHalfHeight = 1.0" in config
    assert "function StrokeMath.ClampToRect" in math
    assert "function StrokeMath.AnchorToFirstPoint" in math
    assert "local unit = canvasSize.Y * 0.5" in math
    assert "point - origin" in math

    map_point = geometry.split("function GeometryMath.MapPoint", 1)[1].split("function GeometryMath.BuildSegmentPlan", 1)[0]
    assert "math.clamp(point.X, -1, 1)" not in map_point
    assert "math.clamp(point.Y, -1, 1)" not in map_point
    assert "MaxLegExtentFromHub" in map_point


def test_r16_3b_authoritative_shape_is_first_point_anchored_without_network_schema_expansion() -> None:
    service = read("src/server/Services/LegShapeService.lua")
    types = read("src/shared/Types/StrokeTypes.lua")
    network = read("docs/22_NETWORK_DATA_CONTRACTS.md")

    assert "StrokeMath.ClampToRect" in service
    assert "StrokeMath.AnchorToFirstPoint(cleaned)" in service
    assert "normalizedPoints = anchored" in service
    assert "GeometryMath.BuildSegmentPlan(anchored" in service
    assert "StrokeMath.CenterOnBounds(cleaned)" not in service

    submit = types.split("export type SubmitStrokePayload", 1)[1].split("export type StrokeResultPayload", 1)[0]
    assert "sequence" in submit and "points" in submit
    assert "canvasAspect" not in submit
    assert "presentationAnchor" not in submit

    assert "R16.3B" in network
    assert "first-point" in network.lower() or "first point" in network.lower()
    assert "payload schema unchanged" in network.lower()


def test_r16_3b_draw_ui_uses_full_wide_surface_and_sequence_scoped_presentation_anchor() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert "SemanticSquareConstraint" not in drawing
    assert "RawSemanticHalfWidth" in drawing
    assert "RawSemanticHalfHeight" in drawing
    assert "_presentationAnchors" in drawing
    assert "presentationAnchor" in drawing
    assert "sequence" in drawing
    assert "StrokeMath.Normalize" in drawing
    # The receiver may be a local alias; the contract is that the visible wide DrawInputRect is bound.
    assert "inputController:Bind(drawInputRect)" in drawing


def test_r16_3b_leg_visual_is_nonphysical_and_physical_colliders_are_hidden() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    b07 = read("src/server/Tests/B07LegAssemblySpec.lua")

    assert "VisualSegment_" in leg
    assert "VisualJoint_" in leg
    assert "visual.CanCollide = false" in leg
    assert "visual.CanTouch = false" in leg
    assert "visual.CanQuery = false" in leg
    assert "visual.Massless = true" in leg
    assert "segment.Transparency = 1" in leg

    assert "visual representation must never collide" in b07
    assert "physical collider count changed by visual layer" in b07


def test_r16_3b_g0_presentation_uses_side_camera_and_restores_fov() -> None:
    presentation = read("src/client/Dev/M0G0PresentationHarness.lua")

    assert "local CAMERA_OFFSET = Vector3.new(0, 4, 22)" in presentation
    assert "local CAMERA_LOOK_AHEAD = Vector3.new(6, 0.8, 0)" in presentation
    assert "local CAMERA_FIELD_OF_VIEW = 40" in presentation
    assert "previousFieldOfView" in presentation
    assert "camera.FieldOfView = CAMERA_FIELD_OF_VIEW" in presentation
    assert "camera.FieldOfView = previousFieldOfView" in presentation
    assert "proxy.Transparency = 0" in presentation
    assert "proxy.Material = Enum.Material.SmoothPlastic" in presentation


def test_r16_3b_debug_panel_is_hidden_by_default_and_f3_only_toggles_presentation() -> None:
    panel = read("src/client/Controllers/DebugTuningPanel.lua")

    assert "gui.Enabled = false" in panel
    assert "Enum.KeyCode.F3" in panel
    assert "InputBegan" in panel
    assert "gui.Enabled = not gui.Enabled" in panel


def test_r16_3b_r16final_orders_automated_evidence_before_human_ready() -> None:
    modes = read("src/shared/Config/StudioHarnessConfig.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    client_bootstrap = read("src/client/Bootstrap.client.lua")
    final_path = ROOT / "src/server/Tests/R16FinalHarness.lua"
    assert final_path.exists(), "R16.3B requires unified R16FinalHarness"
    final = final_path.read_text(encoding="utf-8")
    stage_c = read("src/server/Tests/R16StageCHarness.lua")

    assert 'R16FINAL = "R16FINAL"' in modes
    assert 'Mode = "G0"' in modes
    assert 'harnessMode == "R16FINAL"' in bootstrap
    assert "R16StageCHarness.RunEvidence()" in final
    assert "M0HumanHarness.start()" in final
    assert "[DrawRacers][R16FINAL] HUMAN G0 READY" in final
    assert final.index("R16StageCHarness.RunEvidence()") < final.index("M0HumanHarness.start()")
    assert final.index("M0HumanHarness.start()") < final.index("HUMAN G0 READY")
    assert "task.spawn" not in final
    assert "function R16StageCHarness.RunEvidence(): boolean" in stage_c
    assert 'StudioHarnessConfig.Mode == "R16FINAL"' in client_bootstrap


def test_r16_3b_preserves_two_leg_phase_and_core_physics_tuning() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    for token in [
        "AngularVelocity = -8.0",
        "MotorMaxTorque = 35000",
        "MotorMaxAcceleration = 120",
        "RightPhaseOffsetDegrees = 180",
        "PhysicalLegSegmentThickness = 0.45",
        "MaxColliderSegmentsPerLeg = 14",
        "InnerHubNoCollisionRadius = 0.65",
        "SegmentOverlapAllowance = 0.06",
        "MaxLegExtentFromHub = 4.5",
    ]:
        assert token in config

    assert runtime.count("shapeSpec = shapeSpec") >= 2
    assert "initialPhaseDegrees = leftPhaseDegrees" in runtime
    assert "initialPhaseDegrees = rightPhaseDegrees" in runtime


def test_r16_3b_b14_separates_physical_and_visual_part_accounting() -> None:
    b14 = read("src/server/Tests/B14RedrawStressSpec.lua")

    assert "local function countPhysicalLegParts" in b14
    assert "local function countVisualLegParts" in b14
    assert "MAX_PHYSICAL_LEG_PARTS" in b14
    assert "MAX_VISUAL_LEG_PARTS" in b14
    assert "physicalPartsBeforeBurst" in b14
    assert "visualPartsBeforeBurst" in b14
    assert "leaked physical parts" in b14
    assert "leaked visual parts" in b14
    assert "countLegParts(" not in b14
