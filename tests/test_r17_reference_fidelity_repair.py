from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def current_cr3() -> str:
    return read("docs/CR3_CURRENT_SOURCE_OF_TRUTH.md")


def test_r17_9_camera_uses_full_yaw_target_and_smoothed_rendered_orbit() -> None:
    camera = read("src/client/Controllers/RaceCameraController.lua")
    math = read("src/shared/Math/CameraMath.lua")
    assert "ORBIT_YAW_LIMIT" not in camera
    assert "ORBIT_PITCH_LIMIT = 70" in camera
    for token in ["_targetOrbitYaw", "_targetOrbitPitch", "_orbitYaw", "_orbitPitch", "ORBIT_INPUT_DAMPING_TIME"]:
        assert token in camera
    assert "SmoothAngleDegrees" in math
    assert "ClampPitch" in math


def test_r17_10_production_uses_two_persistent_drive_motors_under_one_pair_command_owner() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    racer = read("src/server/Runtime/RacerRuntime.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    for token in ['joint.Name = "DriveJoint"', "Enum.ActuatorType.Motor", "joint.AngularVelocity", "joint.MotorMaxTorque", "joint.MotorMaxAcceleration"]:
        assert token in drive
    assert pair.count("LegDriveAssembly.new") == 2
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "RightPhaseOffsetDegrees" in pair
    assert "function LegPairAssembly:GetLeftDrive" in pair
    assert "function LegPairAssembly:GetRightDrive" in pair
    assert "self.leftDrive:SetMotorVelocity(baseOmega)" in pair
    assert "self.rightDrive:SetMotorVelocity(baseOmega)" in pair
    assert "ComputePhaseCorrection" not in pair
    assert 'require(script.Parent:WaitForChild("LegPairAssembly"))' in racer
    assert "phaseSyncConnection" not in racer
    assert 'Instance.new("HingeConstraint")' not in leg
    assert "ActuatorType" not in leg


def test_r17_11_phase_correction_controller_is_retired_for_single_pair_command() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive_math = read("src/shared/Math/LegDriveMath.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
    for retired in [
        "PhaseCorrectionGain", "MaxPhaseCorrection", "PhaseDeadbandDegrees",
        "PhaseLockToleranceDegrees", "PhaseLockRecoveryTime", "PhaseLockMaxRelativeCorrection",
    ]:
        assert retired not in config
    assert "ComputePhaseCorrection" not in drive_math
    assert "PairPhaseErrorDegrees" in drive_math


def test_r17_12_lower_mount_and_collision_contract_are_reference_safe() -> None:
    collision = read("src/server/Runtime/CollisionGroups.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "body.Size.X / 2" not in drive
    assert "bodyMount: Attachment" in drive
    assert '"LeftLegMount"' in pair and '"RightLegMount"' in pair
    assert "LegMountHorizontalFraction = 0.78" in config
    assert "LegMountVerticalFraction = -0.72" in config
    assert "LegSocketZAbs" not in pair
    assert 'CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Track, true)' in collision
    assert 'CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.RacerLeg, false)' in collision
    assert 'CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.RacerLeg, false)' in collision


def test_r17_14_redraw_replaces_only_geometry_and_preserves_twin_drive_identity() -> None:
    racer = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    apply = racer.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
    stage = pair.split("function LegPairAssembly:StageRedraw", 1)[1].split("function LegPairAssembly:SetStageProgress", 1)[0]
    assert "self.legPair:StageRedraw(shapeSpec)" in apply
    assert "self.legPair:CommitStagedRedraw()" in apply
    assert "LegPairAssembly.new" not in apply
    assert "self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)" in stage
    assert "self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)" in stage
    for obsolete in ["buildStagedSides", "oldLeft", "oldRight", "SetRetiring", "LegDriveAssembly.new", "LegAssembly.new", 'Instance.new("HingeConstraint")']:
        assert obsolete not in stage


def test_r17_contract_is_superseded_by_cr3_without_passing_human_gate() -> None:
    current = current_cr3()
    design = read("docs/superpowers/specs/2026-09-14-core-repair-v3-free-draw-single-phase-design.md")
    assert "No current `AxleRoot` / `AxleJoint`" in current
    assert "LegDriveAssembly" in current and "DriveJoint" in current
    assert "G0 / HUMAN STUDIO: PENDING" in current
    assert "free draw" in design.lower()


def test_r17_current_source_routes_drive_mount_and_full_yaw_owners() -> None:
    current = current_cr3()
    for token in ["LegDriveAssembly", "LegPairAssembly", "DriveJoint", "LeftLegMount", "RightLegMount", "G0"]:
        assert token.lower() in current.lower()
    assert "No current `AxleRoot` / `AxleJoint`" in current


def test_r17_exact_geometry_and_instance_contract_uses_cr3_drive_layout() -> None:
    current = current_cr3()
    for token in ["CR3", "LeftLegMount", "RightLegMount", "DriveJoint", "support anchor", "HUMAN"]:
        assert token.lower() in current.lower()


def test_r17_core_tuning_and_camera_contract_match_current_drive_model() -> None:
    current = current_cr3()
    for token in ["CR3", "LegDriveAssembly", "TargetTipSpeed", "RightPhaseOffsetDegrees = 180"]:
        assert token.lower() in current.lower()
