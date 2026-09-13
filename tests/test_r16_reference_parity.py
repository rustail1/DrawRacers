from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_1_body_orientation_is_arcade_upright() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert "Enum.AlignType.AllAxes" in stabilizer
    assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
    assert "orientationAlign.RigidityEnabled = true" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" not in stabilizer


def test_r16_1_upright_attachment_uses_identity_basis_for_all_axes() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert "orientationAttachment.Axis = Vector3.xAxis" in stabilizer
    assert "orientationAttachment.SecondaryAxis = Vector3.yAxis" in stabilizer
    assert "orientationAttachment.Axis = Vector3.zAxis" not in stabilizer


def test_r16_2_cr2_horizontal_drive_pivots_have_one_owner() -> None:
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    assert 'side == "Left" then -body.Size.X / 2 else body.Size.X / 2' in drive
    assert "bodyAttachment.Position = Vector3.new(pivotX, 0, 0)" in drive
    assert "CFrame.new(pivotX, 0, 0)" in drive
    assert "LegSocketZAbs" not in pair
    assert "HubOffsetX" not in pair
    assert "LeftHub" not in runtime and "RightHub" not in runtime


def test_r16_2_studio_instance_contract_is_superseded_by_cr2_twin_drive_layout() -> None:
    studio = read("docs/65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md")
    assert "CORE REPAIR v2" in studio
    assert "LeftDrive" in studio
    assert "RightDrive" in studio
    assert "DriveJoint" in studio
    assert "AxleRoot" not in studio.split("CORE REPAIR v2", 1)[1]


def test_r16_3_one_shape_builds_two_same_xy_legs_about_two_horizontal_pivots() -> None:
    geometry = read("src/shared/Math/GeometryMath.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "local mapped = point * geometry.LegCanvasHalfSpan" in geometry
    assert "MaxLegExtentFromHub" in geometry
    initial = runtime.split("function RacerRuntime:_CreateInitialLegPair", 1)[1].split("function RacerRuntime:_ApplyShapeSpec", 1)[0]
    assert initial.count("LegPairAssembly.new") == 1
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "leftDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert "rightDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert '"DriveWeld"' in leg
    apply_shape_spec = runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
    assert "shapeSpec.normalizedPoints" not in apply_shape_spec


def test_r16_3b_server_validates_fixed_visible_pivot_without_resizing() -> None:
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    service = read("src/server/Services/LegShapeService.lua")
    assert "START_OFF_PIVOT" in builder
    assert "PivotStartRadiusNormalized" in builder
    assert "Vector2.zero" in builder
    assert "AnchorToFirstPoint" not in builder
    assert "CenterOnBounds" not in builder
    assert "CanonicalLegShape.Build" in service


def test_r16_3b_internal_apply_shape_cannot_bypass_fixed_pivot() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    internal_shape = runtime.split("local function makeInternalShapeSpec", 1)[1].split("local function publishValidatedShapeState", 1)[0]
    assert "CanonicalLegShape.Build" in internal_shape
    assert "PhysicsConfig.StrokeProcessing" in internal_shape
    assert "PhysicsConfig.LegGeometry" in internal_shape
    assert "normalizedPoints = canonical.normalizedPoints" in internal_shape
    assert "segmentPlan = canonical.segmentPlan" in internal_shape
    assert "StrokeMath." not in internal_shape
    assert "GeometryMath." not in internal_shape


def test_cr2_docs_supersede_r16_first_point_translation_and_shared_axle() -> None:
    shape_doc = read("docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md")
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    architecture = read("docs/21_SYSTEM_CLASS_ARCHITECTURE.md")
    for doc in [shape_doc, core, architecture]:
        assert "CORE REPAIR v2" in doc
        assert "fixed pivot" in doc.lower()
        assert "LegDriveAssembly" in doc
        assert "twin" in doc.lower() or "two" in doc.lower()


def test_cr2_network_contract_returns_fixed_pivot_authoritative_points() -> None:
    network = read("docs/22_NETWORK_DATA_CONTRACTS.md")
    stroke_result = network.split("### `StrokeResult`", 1)[1].split("### `CosmeticResult`", 1)[0]
    assert "acceptedPoints?" in stroke_result
    assert "fixed pivot" in stroke_result.lower()
    assert "client renders" in stroke_result.lower()
    assert "payload schema unchanged" in network.lower()


def test_cr2_status_docs_keep_human_g0_pending() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    for doc in [session, features]:
        assert "CORE REPAIR v2" in doc
        assert "G0" in doc
        assert "HUMAN" in doc.upper()
        assert "PASS" not in doc.split("CORE REPAIR v2", 1)[-1][:250].upper() or "PENDING" in doc.upper()


def test_cr2_owner_docs_match_upright_and_fixed_pivot_contract() -> None:
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    tuning = read("docs/16_BALANCE_TUNING.md")
    assert "fixed pivot" in core.lower()
    assert "twin" in core.lower() or "two drive" in core.lower()
    assert "upright" in core.lower()
    assert "LegCanvasHalfSpan = 3.2" in tuning
    assert "MaxLegExtentFromHub = 4.5" in tuning
    assert "TargetTipSpeed" in tuning


def test_r16_technical_design_does_not_reintroduce_free_body_roll() -> None:
    tech = read("docs/11_TECH_DESIGN_ROBLOX.md")
    stabilization = tech.split("## 10. Body stabilization", 1)[1].split("## 11. Network model", 1)[0]
    assert "upright" in stabilization.lower()
    assert "RigidityEnabled" in stabilization
    assert "prevent endless roll" not in stabilization


def test_r16_readme_entrypoint_tracks_cr2_and_human_pending() -> None:
    readme = read("README.md")
    assert "CORE REPAIR v2" in readme
    assert "G0" in readme
    assert "HUMAN" in readme.upper()


def test_r16_qa_matrix_keeps_exact_upright_and_cr2_redraw_acceptance() -> None:
    qa = read("docs/24_TESTING_QA_MATRIX.md")
    assert "upright" in qa.lower()
    assert "twin" in qa.lower() or "DriveJoint" in qa
    assert "old physical" in qa.lower()
    assert "commit" in qa.lower()


def test_latest_phase_decision_is_180_with_bounded_twin_drive_correction() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    drive_math = read("src/shared/Math/LegDriveMath.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
    assert "LegDriveMath.PairPhaseErrorDegrees" in pair
    assert "LegDriveMath.ComputePhaseCorrection" in pair
    assert "SignedShortestDeltaDegrees" in drive_math
    assert "SetInitialPhaseDegrees" not in pair
    assert "_StepLegPhaseSync" not in read("src/server/Runtime/RacerRuntime.lua")
