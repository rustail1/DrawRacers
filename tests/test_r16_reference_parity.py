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


def test_r16_2_studio_instance_contract_uses_canonical_hub_offsets() -> None:
    studio = read("docs/65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md")
    hub_section = studio.split("Hub Parts:", 1)[1].split("## 4. Runtime leg assembly", 1)[0]

    assert "PhysicsConfig.LegGeometry" in hub_section
    assert "HubOffsetY = -0.35" in hub_section
    assert "HubOffsetZAbs = 1.62" in hub_section
    assert "(0,-0.75,-1.62)" not in hub_section
    assert "(0,-0.75,+1.62)" not in hub_section


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


def test_r16_3a_internal_apply_shape_cannot_bypass_centering() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    internal_shape = runtime.split("local function makeInternalShapeSpec", 1)[1].split(
        "function RacerRuntime.new", 1
    )[0]
    assert "StrokeMath.CenterOnBounds(normalizedPoints)" in internal_shape
    assert "GeometryMath.BuildSegmentPlan(centeredPoints, PhysicsConfig.LegGeometry)" in internal_shape
    assert "normalizedPoints = centeredPoints" in internal_shape
    assert "StrokeMath.ComputeBounds(centeredPoints)" in internal_shape


def test_r16_3a_docs_supersede_raw_canvas_offset_semantics() -> None:
    shape_doc = read("docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md")
    design = read("docs/superpowers/specs/2026-09-10-r16-draw-climber-reference-parity-design.md")

    assert "R16.3A" in shape_doc
    assert "server recenters the cleaned stroke around its own bounds center" in shape_doc
    assert "MUST NOT recenter the stroke around its own bounds" not in shape_doc
    assert "offset shapes remain offset relative to the hub" not in shape_doc
    assert "HubOffsetY = -0.35" in shape_doc
    assert "R16.3A — Reference Shape Centering" in design
    assert "It is not mirrored, recentered to its bounding box" not in design
    assert "no auto-centering by stroke bounds" not in design


def test_r16_3a_network_contract_returns_centered_authoritative_points() -> None:
    network = read("docs/22_NETWORK_DATA_CONTRACTS.md")

    stroke_result = network.split("### `StrokeResult`", 1)[1].split("### `CosmeticResult`", 1)[0]
    assert "acceptedPoints?" in stroke_result
    assert "authoritative centered `ShapeSpec.normalizedPoints`" in stroke_result
    assert "client renders `acceptedPoints`" in stroke_result

    shape_spec = network.split("# 7. ShapeSpec contract", 1)[1].split("# 8. Remote abuse rules", 1)[0]
    assert "centered authoritative normalized points" in shape_spec
    assert "raw DrawInputRect offset" in shape_spec


def test_r16_status_docs_track_current_stage_a_contract_without_passing_human_gate() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")

    for doc in [session, features]:
        assert "R16 Stage A" in doc
        assert "R16.1–R16.4" in doc
        assert "HUMAN STUDIO PENDING" in doc
        assert "rotation about world Z: locked/corrected" in doc
        assert "R16.3A" in doc
        assert "centered authoritative shape" in doc

    current_session = session.split("## Current implementation/evidence cursor", 1)[1]
    assert "R16 Stage A" in current_session
    assert "Studio Gate A" in current_session
    assert "B17 — G0 HUMAN_GATE only" not in current_session

    current_features = features.split("## M0 — Physics Lab", 1)[1].split(
        "### R01–R12 implementation-integrity record", 1
    )[0]
    assert "R16 Stage A" in current_features
    assert "HUMAN STUDIO PENDING" in current_features


def test_r16_owner_docs_match_upright_and_centered_shape_contract() -> None:
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    tuning = read("docs/16_BALANCE_TUNING.md")

    assert "center the cleaned stroke on its own bounds midpoint" in core
    assert "do **not** recenter/resize by stroke bounds" not in core
    assert "rotation about world Z is locked/corrected" in core
    assert "rotation around world Z remains physical and free" not in core

    assert "R16.1 upright-body contract" in tuning
    assert "AlignType.AllAxes" in tuning
    assert "rotation around world Z remains physical/free" not in tuning
    assert "PrimaryAxisParallel" not in tuning


def test_r16_technical_design_does_not_reintroduce_free_body_roll() -> None:
    tech = read("docs/11_TECH_DESIGN_ROBLOX.md")
    stabilization = tech.split("## 10. Body stabilization", 1)[1].split("## 11. Network model", 1)[0]

    assert "R16.1 upright-body contract" in stabilization
    assert "all three body rotation axes" in stabilization
    assert "prevent endless roll" not in stabilization
    assert "tuned softly" not in stabilization


def test_r16_readme_entrypoint_tracks_current_stage_a_contract() -> None:
    readme = read("README.md")

    current_state = readme.split("## Current state", 1)[1].split("## CORE / pre-G0 integrity repair", 1)[0]
    assert "R16 Stage A" in current_state
    assert "Studio Gate A" in current_state
    assert "HUMAN STUDIO PENDING" in current_state
    assert "next permitted item remains B17/G0 HUMAN_GATE" not in current_state

    repair = readme.split("## CORE / pre-G0 integrity repair", 1)[1].split("## Toolchain", 1)[0]
    assert "R16.1" in repair
    assert "R16.3A" in repair
    assert "soft/free-tilt stabilization" not in repair

    locomotion = readme.split("### B06–B10 — Physical locomotion foundation", 1)[1].split(
        "### B11–B12", 1
    )[0]
    assert "upright" in locomotion.lower()


def test_r16_1_qa_matrix_uses_exact_upright_acceptance() -> None:
    qa = read("docs/24_TESTING_QA_MATRIX.md")
    locomotion = qa.split("## Locomotion", 1)[1].split("## Redraw", 1)[0]

    assert "R16.1 upright-body acceptance" in locomotion
    assert "normal angular deviation <= 1.0 degree" in locomotion
    assert "strong-contact disturbance <= 3.0 degrees" in locomotion
    assert "return to <= 1.0 degree within 0.25 s" in locomotion
    assert "X/Y translation remains physical/free" in locomotion
    assert "racer does not endlessly spin from normal contacts" not in locomotion


def test_r16_4_phase_is_180_and_redraw_retains_each_side() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")
    b13 = read("src/server/Tests/B13AtomicRedrawSpec.lua")

    assert "RightPhaseOffsetDegrees = 180" in config
    assert "angularDistanceDegrees" in b09
    assert "phase difference" in b09
    assert "angularDistanceDegrees(leftPhaseAfter, leftPhaseBefore)" in b13
    assert "angularDistanceDegrees(rightPhaseAfter, rightPhaseBefore)" in b13