from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


MECHANICAL_CLUSTER = [
    "src/shared/Math/CanonicalLegShape.lua",
    "src/shared/Math/StrokeMath.lua",
    "src/shared/Math/GeometryMath.lua",
    "src/shared/Math/LegReshapeMath.lua",
    "src/server/Services/LegShapeService.lua",
    "src/server/Runtime/LegAssembly.lua",
    "src/server/Runtime/LegPairAssembly.lua",
    "src/server/Runtime/RacerRuntime.lua",
    "src/client/Controllers/DrawingController.lua",
]


def test_mr06_mechanical_cluster_has_no_retired_transition_paths() -> None:
    combined = "\n".join(read(path) for path in MECHANICAL_CLUSTER)

    for retired in [
        "LegShapeMath",
        "stagingContainer",
        "LegPairStaging",
        "function LegPairAssembly:Commit",
        "function LegPairAssembly:IsCommitted",
        "SetRetiring",
        "buildStagedSides",
        "makeCompatibilityHub",
        '"LeftHub"',
        '"RightHub"',
    ]:
        assert retired not in combined, f"retired mechanical transition path remains: {retired}"


def test_mr06_one_canonical_builder_and_one_axle_joint_owner() -> None:
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    service = read("src/server/Services/LegShapeService.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    controller = read("src/client/Controllers/DrawingController.lua")

    assert canonical.count("function CanonicalLegShape.Build") == 1
    assert pair.count('Instance.new("HingeConstraint")') == 1
    for path in [
        "src/server/Runtime/LegAssembly.lua",
        "src/server/Runtime/RacerRuntime.lua",
        "src/server/Services/LegShapeService.lua",
        "src/client/Controllers/DrawingController.lua",
    ]:
        assert 'Instance.new("HingeConstraint")' not in read(path), f"second axle/joint owner in {path}"

    for consumer_name, consumer in [
        ("service", service),
        ("runtime", runtime),
        ("controller", controller),
    ]:
        for duplicate_cleanup in [
            "StrokeMath.ClampToRect",
            "StrokeMath.Dedupe",
            "StrokeMath.SimplifyRDP",
            "StrokeMath.Resample",
            "GeometryMath.BuildSegmentPlan",
        ]:
            assert duplicate_cleanup not in consumer, f"duplicate canonical cleanup in {consumer_name}: {duplicate_cleanup}"

    assert "CanonicalLegShape.Build" in service
    assert "CanonicalLegShape.Build" in runtime
    assert "CanonicalLegShape.Build" in controller


def test_mr06_pair_exposes_one_redraw_geometry_entrypoint() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    assert "function LegPairAssembly:BeginGeometryReshape" in pair
    assert "function LegPairAssembly:ReplaceGeometry" not in pair
    assert "self.legPair:BeginGeometryReshape(shapeSpec)" in runtime
    assert "self.legPair:ReplaceGeometry(shapeSpec)" not in runtime


def test_mr06_template_and_studio_specs_match_persistent_pair_architecture() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    b06 = read("src/server/Tests/B06RacerRuntimeSpec.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")

    for retired_hub in ["LeftHub", "RightHub", "makeCompatibilityHub"]:
        assert retired_hub not in runtime
        assert retired_hub not in b06

    assert "pairAfter == pairBefore" in b09
    assert "pairAfter ~= pairBefore" not in b09
    assert "redraw must preserve shared pair" in b09


def test_mr06_safety_gates_and_fast_g0_remain_intact() -> None:
    trial = read("src/server/Tests/R16TrialRunner.lua")
    stage_b = read("src/server/Tests/R16StageBHarness.lua")
    harness_config = read("src/shared/Config/StudioHarnessConfig.lua")

    assert "M0SceneConfig.RecoveryKillY" in trial
    assert "result.fellBelowRecovery = true" in trial
    assert "result.solverInstability = true" in trial
    assert "result.solverInstability ~= true" in stage_b
    assert "result.fellBelowRecovery ~= true" in stage_b
    assert 'Mode = "G0"' in harness_config
    assert "no automatic B03-B16/R17 evidence startup" in harness_config
