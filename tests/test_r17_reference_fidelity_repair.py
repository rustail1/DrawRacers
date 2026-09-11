from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r17_9_camera_uses_full_yaw_target_and_smoothed_rendered_orbit() -> None:
    camera = read("src/client/Controllers/RaceCameraController.lua")
    math = read("src/shared/Math/CameraMath.lua")

    assert "ORBIT_YAW_LIMIT" not in camera, "R17.9 removes the artificial +/-40 degree yaw wall"
    assert "ORBIT_PITCH_LIMIT = 70" in camera
    for token in [
        "_targetOrbitYaw",
        "_targetOrbitPitch",
        "_orbitYaw",
        "_orbitPitch",
        "ORBIT_INPUT_DAMPING_TIME",
    ]:
        assert token in camera, f"missing R17.9 camera token: {token}"
    assert "SmoothAngleDegrees" in math
    assert "ClampPitch" in math


def test_r17_10_production_uses_one_shared_axle_motor_for_both_rigid_sides() -> None:
    pair_path = ROOT / "src/server/Runtime/LegPairAssembly.lua"
    assert pair_path.is_file(), "R17.10 requires LegPairAssembly"
    pair = pair_path.read_text(encoding="utf-8")
    racer = read("src/server/Runtime/RacerRuntime.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")

    for token in [
        'joint.Name = "AxleJoint"',
        "Enum.ActuatorType.Motor",
        "PhysicsConfig.Motor.AngularVelocity",
        'side = "Left"',
        'side = "Right"',
        "RightPhaseOffsetDegrees",
        "function LegPairAssembly:GetJoint()",
        "function LegPairAssembly:GetPhaseDegrees()",
    ]:
        assert token in pair, f"missing shared-axle token: {token}"

    assert 'require(script.Parent:WaitForChild("LegPairAssembly"))' in racer
    assert "self.legPair" in racer
    assert "phaseSyncConnection" not in racer
    assert "_StepLegPhaseSync" not in racer
    assert "leftJoint.AngularVelocity" not in racer
    assert "rightJoint.AngularVelocity" not in racer

    assert 'Instance.new("HingeConstraint")' not in leg
    assert "ActuatorType" not in leg


def test_r17_11_phase_lock_correction_config_is_removed_in_favor_of_structural_cophase() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "RightPhaseOffsetDegrees = 0" in config
    for obsolete in [
        "PhaseLockToleranceDegrees",
        "PhaseLockRecoveryTime",
        "PhaseLockMaxRelativeCorrection",
    ]:
        assert obsolete not in config


def test_r17_12_socket_and_collision_contract_remain_reference_safe() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    collision = read("src/server/Runtime/CollisionGroups.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")

    assert "LegSocketZAbs = 1.5" in config
    assert "geometry.LegSocketZAbs" in pair
    assert 'CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Track, true)' in collision
    assert 'CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.RacerLeg, false)' in collision
    assert 'CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.RacerLeg, false)' in collision


def test_r17_14_redraw_swaps_one_pair_atomically_and_preserves_one_axle_phase() -> None:
    racer = read("src/server/Runtime/RacerRuntime.lua")
    apply = racer.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]

    for token in [
        "oldLegPair",
        "stagedLegPair",
        "stagedLegPair:Commit()",
        "stagedLegPair:SetEnabled",
        "oldLegPair:Destroy()",
        "initialPhaseDegrees",
    ]:
        assert token in apply, f"missing atomic shared-pair redraw token: {token}"

    assert "stagedLeftLeg" not in apply
    assert "stagedRightLeg" not in apply


def test_r17_contract_docs_record_shared_axle_and_unbounded_yaw_without_passing_human_gate() -> None:
    decision = read("docs/DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md")
    architecture = read("docs/21_SYSTEM_CLASS_ARCHITECTURE.md")
    qa = read("docs/24_TESTING_QA_MATRIX.md")

    for token in ["shared axle", "one hinge", "one motor", "360", "HUMAN STUDIO PENDING"]:
        assert token.lower() in decision.lower(), f"decision missing token: {token}"
    assert "co-phase" in decision.lower(), "R17 decision must record the human-video co-phase correction"
    assert "LegPairAssembly" in architecture
    assert "R17.9" in qa and "R17.14" in qa


def test_r17_navigation_map_routes_current_shared_axle_and_full_yaw_owners() -> None:
    navigation = read("docs/ARCHITECTURE_MAP.md")

    for token in [
        "LegPairAssembly.lua",
        "AxleJoint",
        "one shared axle",
        "co-phase",
        "full 360",
        "R17FINAL",
    ]:
        assert token.lower() in navigation.lower(), f"navigation map missing current R17 token: {token}"

    assert "one HingeConstraint motor per leg" not in navigation
    assert "RMB/touch bounded orbit" not in navigation


def test_r17_exact_geometry_and_instance_docs_use_shared_axle_contract() -> None:
    geometry = read("docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md")
    studio = read("docs/65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md")

    for doc_name, doc in [("73", geometry), ("65", studio)]:
        for token in [
            "LegPairAssembly",
            "AxleRoot",
            "AxleJoint",
            "AxleMotorAttachment",
            "LegSocketZAbs = 1.5",
            "co-phase",
            "one motor",
            "HUMAN STUDIO PENDING",
        ]:
            assert token.lower() in doc.lower(), f"doc {doc_name} missing current R17 token: {token}"

        assert "HubJoint" not in doc, f"doc {doc_name} still specifies obsolete per-side HubJoint"
        assert "Hinge motor rotates LegRoot" not in doc, f"doc {doc_name} still gives a side LegRoot its own motor"

    assert "R17" in geometry
    assert "R17" in studio
    assert "Beginning only at E03" not in studio
    assert "no rider object is required before E03" not in studio


def test_r17_core_tuning_and_technical_docs_match_current_axle_and_camera() -> None:
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    tuning = read("docs/16_BALANCE_TUNING.md")
    tech = read("docs/11_TECH_DESIGN_ROBLOX.md")

    for doc_name, doc in [("03", core), ("16", tuning), ("11", tech)]:
        assert "LegPairAssembly" in doc, f"doc {doc_name} must route current rotation to LegPairAssembly"
        assert "shared axle" in doc.lower(), f"doc {doc_name} must describe the shared axle"

    assert "Один motor/hinge на leg." not in core
    assert "Use one motorized hinge per leg" not in tuning
    assert "one motor" in core.lower()
    assert "one motor" in tuning.lower()
    assert "co-phase" in core.lower()
    assert "co-phase" in tuning.lower()

    assert "Free-look yaw limit | **±40°**" not in tuning
    assert "full 360" in tuning.lower()
    assert "70°" in tuning or "70" in tuning

    assert "one `AxleJoint`" in tech or "one AxleJoint" in tech
    assert "attach at current hubs/phase" not in tech
