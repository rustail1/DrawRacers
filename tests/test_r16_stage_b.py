from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_5_tuning_has_single_leg_material_owner_and_flat_measurement_harness() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    scene = read("src/shared/Config/M0SceneConfig.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    harness_config = read("src/shared/Config/StudioHarnessConfig.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    session = read("docs/SESSION.md")

    harness_path = ROOT / "src/server/Tests/R16StageBHarness.lua"
    shapes_path = ROOT / "src/server/Tests/R16ReferenceShapes.lua"
    assert harness_path.exists(), "R16.5 requires a Studio-only Stage B measurement harness"
    assert shapes_path.exists(), "R16.5 requires canonical executable reference shapes"
    harness = harness_path.read_text(encoding="utf-8")
    shapes = shapes_path.read_text(encoding="utf-8")

    assert "PhysicalMaterials = {" in config
    assert "LegSegment = {" in config
    assert "PhysicsConfig.PhysicalMaterials.LegSegment" in leg

    for token in [
        "FlatIgnoreSeconds = 2.0",
        "FlatMeasureSeconds = 3.0",
        "FlatSpeedMin = 4.0",
        "FlatSpeedMax = 7.0",
    ]:
        assert token in scene

    assert 'R16B = "R16B"' in harness_config
    assert 'harnessMode == "R16B"' in bootstrap
    assert 'WaitForChild("R16StageBHarness")' in bootstrap

    assert "ROUND_01" in shapes
    assert "waitForTrackContact" in harness
    assert "FlatIgnoreSeconds" in harness
    assert "FlatMeasureSeconds" in harness
    assert "FlatSpeedMin" in harness
    assert "FlatSpeedMax" in harness
    assert 'GetAttribute("AntiStallActive")' in harness
    assert "R16.5" in harness

    assert "Stage B implementation authorized by Product Owner" in session
    assert "Studio Gate A remains HUMAN STUDIO PENDING" in session


def test_r16_6_vertical_motion_is_solver_owned_and_measured_in_studio() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    anti_stall = read("src/server/Runtime/RacerAntiStall.lua")
    scene = read("src/shared/Config/M0SceneConfig.lua")
    harness = read("src/server/Tests/R16StageBHarness.lua")
    shapes = read("src/server/Tests/R16ReferenceShapes.lua")

    stabilizer_step = stabilizer.split("function RacerStabilizer:Step()", 1)[1].split(
        "function RacerStabilizer:GetLaneConstraint", 1
    )[0]
    for forbidden in [
        "body.Position =",
        "body.CFrame =",
        "AssemblyLinearVelocity =",
        "AssemblyAngularVelocity =",
    ]:
        assert forbidden not in stabilizer_step

    assert "Vector3.new(self.body.AssemblyMass * config.MaxAccelerationX, 0, 0)" in anti_stall
    assert "Vector3.new(0," not in anti_stall

    for token in [
        "StepsMeasureSeconds = 10.0",
        "StepsRiseMin = 0.25",
        "GapMeasureSeconds = 6.0",
        "GapFallMin = 1.0",
    ]:
        assert token in scene

    assert "HOOK_01" in shapes
    assert "LONG_BAR_01" in shapes
    assert "runStepsVerticalTrial" in harness
    assert "runGapVerticalTrial" in harness
    assert "maxDeltaY" in harness
    assert "minDeltaY" in harness
    assert "[DrawRacers][R16.6]" in harness


def test_r16_7_reference_matrix_has_all_shapes_and_exact_comparison_rules() -> None:
    scene = read("src/shared/Config/M0SceneConfig.lua")
    harness = read("src/server/Tests/R16StageBHarness.lua")
    shapes = read("src/server/Tests/R16ReferenceShapes.lua")

    for shape_id in [
        "ROUND_01",
        "LONG_BAR_01",
        "SMALL_ROUND_01",
        "HOOK_01",
        "ASYM_01",
        "SUBOPTIMAL_01",
    ]:
        assert shape_id in shapes

    for token in [
        "StepsProgressAdvantage = 4.0",
        "GapProgressAdvantage = 2.0",
        "TunnelMeasureSeconds = 8.0",
        "TunnelProgressAdvantage = 6.0",
        "SuboptimalWorseRatio = 0.20",
    ]:
        assert token in scene

    assert "runProgressTrial" in harness
    assert "runFlatSpeedTrial" in harness
    assert "runShapeMatrix" in harness
    assert "StepsProgressAdvantage" in harness
    assert "GapProgressAdvantage" in harness
    assert "TunnelProgressAdvantage" in harness
    assert "SuboptimalWorseRatio" in harness
    assert "stepsNichePassed" in harness
    assert "gapNichePassed" in harness
    assert "tunnelNichePassed" in harness
    assert "suboptimalPassed" in harness
    assert "noUniversalWinner" in harness
    assert "[DrawRacers][R16.7]" in harness


def test_r16_stage_b_status_records_implementation_without_fabricating_studio_pass() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")

    for doc in [session, features]:
        assert "R16.5–R16.7" in doc
        assert "IMPLEMENTED/AUTOMATED GREEN" in doc
        assert "Studio Gate B" in doc
        assert "HUMAN STUDIO PENDING" in doc
        assert "R16 Stage B PASS" not in doc
        assert "Studio Gate B — PASS" not in doc

    assert "Studio Gate A remains HUMAN STUDIO PENDING" in session
    assert "Stage B implementation authorized by Product Owner" in session
    assert "does not authorize R16.5" not in features
