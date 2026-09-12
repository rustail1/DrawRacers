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


def test_r17_11_phase_lock_correction_config_is_removed_in_favor_of_structural_opposition() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
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


def test_r17_14_redraw_replaces_only_geometry_and_preserves_one_axle_phase() -> None:
    racer = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    apply = racer.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]
    replace = pair.split("function LegPairAssembly:ReplaceGeometry", 1)[1].split(
        "function LegPairAssembly:SetEnabled", 1
    )[0]

    assert "self.legPair:ReplaceGeometry(shapeSpec)" in apply
    assert "LegPairAssembly.new" not in apply
    assert "self.legPair:SetEnabled" in apply

    for token in [
        "stagedLeft",
        "stagedRight",
        "oldLeft",
        "oldRight",
        "stagedLeft:Commit()",
        "stagedRight:Commit()",
        "oldLeft:Destroy()",
        "oldRight:Destroy()",
        "self.axleRoot",
    ]:
        assert token in replace, f"missing stable-axle geometry replacement token: {token}"

    assert 'Instance.new("HingeConstraint")' not in replace
    assert replace.index("stagedLeft:Commit()") < replace.index("oldLeft:Destroy()")
    assert replace.index("stagedRight:Commit()") < replace.index("oldRight:Destroy()")


def test_r17_contract_docs_record_shared_axle_opposed_phase_and_unbounded_yaw_without_passing_human_gate() -> None:
    decision = read("docs/DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md")
    camera_decision = read("docs/DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md")
    architecture = read("docs/21_SYSTEM_CLASS_ARCHITECTURE.md")
    qa = read("docs/24_TESTING_QA_MATRIX.md")

    for token in ["shared axle", "one hinge", "one motor", "180", "HUMAN STUDIO PENDING"]:
        assert token.lower() in decision.lower(), f"opposed-phase decision missing token: {token}"
    assert "RightPhaseOffsetDegrees = 180" in decision
    assert "superseded" in decision.lower() and "co-phase" in decision.lower()
    assert "360" in camera_decision
    assert "LegPairAssembly" in architecture
    assert "R17.9" in qa and "R17.14" in qa


def test_r17_navigation_map_routes_current_shared_axle_and_full_yaw_owners() -> None:
    navigation = read("docs/ARCHITECTURE_MAP.md")
    decision = read("docs/DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md")

    for token in [
        "LegPairAssembly.lua",
        "AxleJoint",
        "one shared axle",
        "full 360",
        "R17FINAL",
    ]:
        assert token.lower() in navigation.lower(), f"navigation map missing current R17 token: {token}"

    assert "RightPhaseOffsetDegrees = 180" in decision
    assert "one HingeConstraint motor per leg" not in navigation
    assert "RMB/touch bounded orbit" not in navigation


def test_r17_exact_geometry_and_instance_docs_keep_shared_axle_contract_under_latest_phase_override() -> None:
    geometry = read("docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md")
    studio = read("docs/65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md")
    decision = read("docs/DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md")

    for doc_name, doc in [("73", geometry), ("65", studio)]:
        for token in [
            "LegPairAssembly",
            "AxleRoot",
            "AxleJoint",
            "AxleMotorAttachment",
            "LegSocketZAbs = 1.5",
            "one motor",
            "HUMAN STUDIO PENDING",
        ]:
            assert token.lower() in doc.lower(), f"doc {doc_name} missing current R17 shared-axle token: {token}"

        assert "HubJoint" not in doc, f"doc {doc_name} still specifies obsolete per-side HubJoint"
        assert "Hinge motor rotates LegRoot" not in doc, f"doc {doc_name} still gives a side LegRoot its own motor"

    assert "RightPhaseOffsetDegrees = 180" in decision
    assert "co-phase" in decision.lower() and "superseded" in decision.lower()
    assert "R17" in geometry
    assert "R17" in studio
    assert "Beginning only at E03" not in studio
    assert "no rider object is required before E03" not in studio


def test_r17_core_tuning_and_technical_docs_match_current_axle_and_camera_under_latest_phase_override() -> None:
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    tuning = read("docs/16_BALANCE_TUNING.md")
    tech = read("docs/11_TECH_DESIGN_ROBLOX.md")
    decision = read("docs/DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md")

    for doc_name, doc in [("03", core), ("16", tuning), ("11", tech)]:
        assert "LegPairAssembly" in doc, f"doc {doc_name} must route current rotation to LegPairAssembly"
        assert "shared axle" in doc.lower(), f"doc {doc_name} must describe the shared axle"

    assert "Один motor/hinge на leg." not in core
    assert "Use one motorized hinge per leg" not in tuning
    assert "one motor" in core.lower()
    assert "one motor" in tuning.lower()
    assert "RightPhaseOffsetDegrees = 180" in decision
    assert "superseded" in decision.lower()

    assert "Free-look yaw limit | **±40°**" not in tuning
    assert "full 360" in tuning.lower()
    assert "70°" in tuning or "70" in tuning

    assert "one `AxleJoint`" in tech or "one AxleJoint" in tech
    assert "attach at current hubs/phase" not in tech
