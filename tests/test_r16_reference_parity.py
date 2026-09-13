from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def current_cr2() -> str:
    return read("docs/CR2_CURRENT_SOURCE_OF_TRUTH.md")


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


def test_r16_2_current_source_records_cr2_twin_drive_layout() -> None:
    current = current_cr2()
    assert "CORE REPAIR v2" in current
    assert "LeftDrive" in current
    assert "RightDrive" in current
    assert "DriveJoint" in current
    section = current.split("Twin-pivot / twin-drive topology", 1)[1]
    assert "AxleRoot" in section and "no current" in section


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


def test_cr2_current_source_supersedes_r16_first_point_translation_and_shared_axle() -> None:
    current = current_cr2()
    design = read("docs/superpowers/specs/2026-09-14-core-repair-v2-twin-pivot-design.md")
    assert "CORE REPAIR v2" in current
    assert "fixed pivot" in current.lower()
    assert "LegDriveAssembly" in current
    assert "twin" in current.lower()
    assert "shared axle" in current.lower() and "retired" in current.lower()
    assert "fixed pivot" in design.lower()


def test_cr2_network_contract_returns_fixed_pivot_authoritative_points() -> None:
    current = current_cr2()
    assert "StrokeResult.acceptedPoints" in current
    assert "fixed-pivot" in current.lower() or "fixed pivot" in current.lower()
    assert "client renders" in current.lower()
    assert "payload schema unchanged" in current.lower()


def test_cr2_status_keeps_human_g0_pending() -> None:
    current = current_cr2()
    assert "CORE REPAIR v2" in current
    assert "G0" in current
    assert "HUMAN STUDIO PENDING" in current
    assert "B17/G0 HUMAN_GATE PENDING" in current


def test_cr2_owner_contract_matches_upright_fixed_pivot_and_current_tuning() -> None:
    current = current_cr2()
    assert "fixed pivot" in current.lower()
    assert "twin" in current.lower()
    assert "upright" in current.lower()
    assert "LegCanvasHalfSpan = 3.2" in current
    assert "MaxLegExtentFromHub = 4.5" in current
    assert "TargetTipSpeed = 10.5" in current


def test_r16_technical_contract_does_not_reintroduce_free_body_roll() -> None:
    current = current_cr2()
    assert "upright" in current.lower()
    assert "RigidityEnabled = true" in current
    assert "no intentional" in current.lower() or "adds no intentional" in current.lower()


def test_r16_readme_entrypoint_tracks_cr2_and_human_pending() -> None:
    readme = read("README.md")
    current = current_cr2()
    assert "CR2_CURRENT_SOURCE_OF_TRUTH.md" in readme
    assert "CORE REPAIR v2" in current
    assert "G0" in current
    assert "HUMAN" in current.upper()


def test_r16_qa_contract_keeps_upright_and_cr2_redraw_acceptance() -> None:
    current = current_cr2()
    assert "upright" in current.lower()
    assert "twin" in current.lower() or "DriveJoint" in current
    assert "old physical" in current.lower()
    assert "commit" in current.lower()


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
