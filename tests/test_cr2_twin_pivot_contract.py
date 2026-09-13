from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_cr2_fixed_pivot_is_explicitly_superseded_by_cr3_free_draw() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    controller = read("src/client/Controllers/DrawingController.lua")
    current = read("docs/CR3_CURRENT_SOURCE_OF_TRUTH.md")
    assert "PivotStartRadiusNormalized" not in config
    assert "START_OFF_PIVOT" not in canonical
    assert "selectSupportAnchor" in canonical
    assert "presentationAnchor" in canonical
    assert "PivotMarker" not in controller
    assert "START FROM THE DOT" not in controller
    assert "_presentationAnchors" in controller
    assert "fixed center drawing pivot" in current.lower()
    assert "historical" in current.lower()


def test_cr2_twin_drive_infrastructure_survives_but_mounts_move_to_explicit_lower_attachments() -> None:
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
    assert "bodyMount: Attachment" in drive
    assert "body.Size.X / 2" not in drive
    assert '"LeftLegMount"' in pair and '"RightLegMount"' in pair
    assert pair.count("LegDriveAssembly.new") == 2
    assert 'Instance.new("HingeConstraint")' not in pair
    assert 'Instance.new("HingeConstraint")' not in leg
    assert '"AxleRoot"' not in pair
    assert "LegSocketZAbs" not in pair


def test_cr2_extent_aware_speed_survives_but_phase_chasing_is_retired() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive_math = read("src/shared/Math/LegDriveMath.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    for token in ["TargetTipSpeed", "MinimumDriveRadius", "MinAngularVelocity", "MaxAngularVelocity"]:
        assert token in config
    for retired in ["PhaseCorrectionGain", "MaxPhaseCorrection", "PhaseDeadbandDegrees"]:
        assert retired not in config
    assert "targetTipSpeed / radius" in drive_math
    assert "SignedShortestDeltaDegrees" in drive_math
    assert "PairPhaseErrorDegrees" in drive_math
    assert "ComputePhaseCorrection" not in drive_math
    assert "RightPhaseOffsetDegrees = 180" in config
    assert "local baseOmega = LegDriveMath.ComputeAngularVelocity" in pair
    assert "self.leftDrive:SetMotorVelocity(baseOmega)" in pair
    assert "self.rightDrive:SetMotorVelocity(baseOmega)" in pair
    assert "ComputePhaseCorrection" not in pair


def test_cr2_smaller_shape_scale_and_arcade_upright_are_retained() -> None:
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


def test_cr2_old_shared_axle_runtime_contract_remains_retired() -> None:
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
    assert "local plan = transformPlan(shapeSpec, self.stageOffsetDegrees)" in stage
    assert "LegReshapeMath.Evaluate(plan" in stage
    assert "rotatePoint(state.partialEndpoint" not in stage
    assert "buildVisualSegment(self, folder, entry.a, endpoint" in stage
