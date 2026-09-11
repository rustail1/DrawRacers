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


def test_r16_3b_g0_proxy_uses_production_side_camera_owner() -> None:
    presentation = read("src/client/Dev/M0G0PresentationHarness.lua")
    camera = read("src/client/Controllers/RaceCameraController.lua")

    assert "local FIELD_OF_VIEW = 60" in camera
    assert "local LOOK_AHEAD = 11" in camera
    assert "local CAMERA_HEIGHT = 10" in camera
    assert "local SIDE_DISTANCE = 23" in camera
    assert "camera.CameraType = Enum.CameraType.Scriptable" in camera
    assert "camera.FieldOfView = FIELD_OF_VIEW" in camera
    assert "camera.CFrame = CFrame.lookAt" in camera
    assert "_previousFieldOfView" in camera
    assert "camera.FieldOfView = self._previousFieldOfView" in camera

    assert "camera.CameraType" not in presentation
    assert "camera.FieldOfView" not in presentation
    assert "camera.CFrame" not in presentation
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


def test_r16_3b_preserves_shape_and_core_physics_tuning_under_r17_shared_axle() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")

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

    assert "LegPairAssembly.new" in runtime
    assert "shapeSpec = shapeSpec" in runtime
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "shapeSpec = params.shapeSpec" in pair
    assert "RightPhaseOffsetDegrees" in pair
    assert pair.count('Instance.new("HingeConstraint")') == 1


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


def test_r16_3b_followup_uses_graphite_presentation_and_refreshes_navigation_map() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    architecture_map = read("docs/ARCHITECTURE_MAP.md")

    assert "local DEFAULT_GRAPHITE_COLOR = Color3.fromRGB(23, 32, 51)" in drawing
    assert "local DRAW_SURFACE_COLOR = Color3.fromRGB(243, 240, 232)" in drawing
    assert "segment.BackgroundColor3 = DEFAULT_GRAPHITE_COLOR" in drawing
    assert "drawInputRect.BackgroundColor3 = DRAW_SURFACE_COLOR" in drawing
    assert "acceptedShapeThumbnail.BackgroundColor3 = DRAW_SURFACE_COLOR" in drawing
    assert "emptyGhost.TextColor3 = DEFAULT_GRAPHITE_COLOR" in drawing
    assert "Color3.fromRGB(55, 190, 255)" not in drawing

    assert "local FRONT_VISUAL_COLOR = Color3.fromRGB(23, 32, 51)" in leg
    assert "local BACK_VISUAL_COLOR = Color3.fromRGB(57, 68, 84)" in leg
    assert 'local visualColor = if side == "Left" then BACK_VISUAL_COLOR else FRONT_VISUAL_COLOR' in leg
    assert "Color3.fromRGB(45, 155, 205)" not in leg
    assert "Color3.fromRGB(70, 215, 245)" not in leg
    assert "segment.Transparency = 1" in leg
    assert "visual.CanCollide = false" in leg
    assert "visual.CanTouch = false" in leg
    assert "visual.CanQuery = false" in leg
    assert "visual.Massless = true" in leg

    assert "NAVIGATION CACHE — NOT SOURCE OF TRUTH" in architecture_map
    assert "VisualSegment" in architecture_map
    assert "VisualJoint" in architecture_map
    assert "R16FinalHarness" in architecture_map
    assert "R16FINAL" in architecture_map
    assert "visible leg/stroke visual" in architecture_map
    assert "R16FINAL ordering/evidence" in architecture_map
