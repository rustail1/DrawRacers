from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_cr2_fixed_pivot_replaces_hidden_first_point_translation() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    controller = read("src/client/Controllers/DrawingController.lua")
    assert "PivotStartRadiusNormalized" in config
    assert "AnchorToFirstPoint" not in canonical
    assert "presentationAnchor" not in canonical
    assert "PivotMarker" in controller
    assert "START FROM THE DOT" in controller
    assert "_presentationAnchors" not in controller
    assert "_acceptedPresentationAnchor" not in controller


def test_cr2_twin_drive_modules_exist_and_own_two_hinges() -> None:
    drive_path = ROOT / "src/server/Runtime/LegDriveAssembly.lua"
    math_path = ROOT / "src/shared/Math/LegDriveMath.lua"
    safety_path = ROOT / "src/server/Runtime/LegCollisionSafety.lua"
    assert drive_path.exists()
    assert math_path.exists()
    assert safety_path.exists()
    drive = drive_path.read_text(encoding="utf-8")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert "body.Size.X / 2" in drive
    assert "Vector3.new(pivotX, 0, 0)" in drive
    assert pair.count("LegDriveAssembly.new") == 2
    assert 'Instance.new("HingeConstraint")' not in pair
    assert 'Instance.new("HingeConstraint")' not in leg
    assert '"AxleRoot"' not in pair
    assert "LegSocketZAbs" not in pair


def test_cr2_drive_speed_is_extent_aware_and_pair_target_is_180() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive_math = read("src/shared/Math/LegDriveMath.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    for token in [
        "TargetTipSpeed", "MinimumDriveRadius", "MinAngularVelocity", "MaxAngularVelocity",
        "PhaseCorrectionGain", "MaxPhaseCorrection", "PhaseDeadbandDegrees",
    ]:
        assert token in config
    assert "targetTipSpeed / radius" in drive_math
    assert "SignedShortestDeltaDegrees" in drive_math
    assert "PairPhaseErrorDegrees" in drive_math
    assert "RightPhaseOffsetDegrees = 180" in config
    assert "LegDriveMath.ComputeAngularVelocity" in pair
    assert "LegDriveMath.PairPhaseErrorDegrees" in pair


def test_cr2_smaller_shape_scale_and_arcade_upright_are_explicit() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert "LegCanvasHalfSpan = 3.2" in config
    assert "MaxLegExtentFromHub = 4.5" in config
    assert "orientationAlign.RigidityEnabled = true" in stabilizer


def test_cr2_redraw_keeps_old_physics_until_atomic_commit() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    for token in [
        "function LegAssembly:InstallGeometry", "function LegAssembly:StageGeometry",
        "function LegAssembly:SetStageProgress", "function LegAssembly:CommitStagedGeometry",
        "function LegAssembly:CancelStagedGeometry",
    ]:
        assert token in leg
    assert "ReshapeTipCollider" not in leg
    assert "ReshapeSupportForce" not in pair
    assert "GravityCompensationFraction" not in read("src/shared/Config/PhysicsConfig.lua")
    assert "LegCollisionSafety" in pair
    assert "NO_SAFE_REDRAW_PHASE" in pair
    assert "function LegPairAssembly:StageRedraw" in pair
    assert "function LegPairAssembly:CommitStagedRedraw" in pair
    assert "REDRAW_PENDING" in runtime


def test_cr2_shape_version_is_published_only_after_mechanical_commit() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    service = read("src/server/Services/LegShapeService.lua")
    apply = section(runtime, "function RacerRuntime:_ApplyShapeSpec", "function RacerRuntime:ApplyShape")
    assert apply.index("CommitStagedRedraw") < apply.index("return self.legPair:GetLeftLeg()")
    validated = section(runtime, "function RacerRuntime:ApplyValidatedShape", "function RacerRuntime:IsDestroyed")
    assert validated.index("self:_ApplyShapeSpec(shapeSpec, motorEnabled)") < validated.index("publishValidatedShapeState(self, shapeSpec)")
    assert "applyResult.accepted" in service
    assert "applyResult.rejectReasonCode" in service


def test_cr2_old_shared_axle_runtime_contract_is_retired() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")
    for retired in [
        '"AxleRoot"', '"AxleJoint"', "AxleMotorAttachment", "LegSocketZAbs",
        "reshapeSupportForce", "BeginGeometryReshape", "SetReshapeProgress", "CompleteReshapeForRecovery",
    ]:
        assert retired not in pair
    for retired in ["axleRoot", "socketZ", "phaseDegrees", '"AxleWeld"']:
        assert retired not in leg
    assert "LegSocketZAbs" not in config


def test_cr2_staged_partial_visual_uses_one_mount_transform_only() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    stage = section(leg, "function LegAssembly:SetStageProgress", "function LegAssembly:CommitStagedGeometry")
    assert "local plan = transformedPlan" in stage
    assert "rotatePoint(state.partialEndpoint" not in stage
