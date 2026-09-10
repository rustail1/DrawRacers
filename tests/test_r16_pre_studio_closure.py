from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_p0_implementation_plan_matches_r16_3a_and_current_upright_basis() -> None:
    plan = read("docs/superpowers/plans/2026-09-10-r16-draw-climber-reference-parity.md")

    assert "R16.3A — Reference Shape Centering" in plan
    assert "server translates the cleaned bounds center to `(0,0)`" in plan
    assert "raw DrawInputRect placement is not gameplay input" in plan
    assert "orientationAttachment.Axis = Vector3.xAxis" in plan
    assert "orientationAttachment.SecondaryAxis = Vector3.yAxis" in plan

    assert "DrawInputRect `(0,0)` remains the physical hub pivot; no mirror/recenter/auto-spoke." not in plan
    assert "no mirror/recenter/auto-spoke" not in plan
    assert "orientationAttachment.Axis = Vector3.zAxis" not in plan

    assert "Stage B implementation authorized by Product Owner" in plan
    assert "Stage C implementation authorized by Product Owner" in plan
    assert "Studio Gate A remains HUMAN STUDIO PENDING" in plan
    assert "Studio Gate B remains HUMAN STUDIO PENDING" in plan
    assert "Studio Gate C remains HUMAN STUDIO PENDING" in plan


def test_p1_b10_uses_real_elapsed_quarter_second_recovery_window() -> None:
    b10 = read("src/server/Tests/B10StabilizationSpec.lua")

    assert "local recoveryElapsed = 0" in b10
    assert "while recoveryElapsed < 0.25" in b10
    assert "recoveryElapsed += RunService.Heartbeat:Wait()" in b10
    assert "upright recovery exceeded 0.25 s" in b10
    assert "for _ = 1, 15 do" not in b10


def test_p2_flat_speed_uses_isolated_studio_benchmark_not_canonical_course() -> None:
    config = read("src/shared/Config/M0SceneConfig.lua")
    scene = read("src/server/M0TestScene.lua")
    stage_b = read("src/server/Tests/R16StageBHarness.lua")

    assert "ReferenceBenchmark = {" in config
    assert 'Name = "R16FlatBenchmark"' in config
    assert "CenterZ = 16" in config
    assert "Length = 60" in config
    assert "buildReferenceBenchmark" in scene
    assert 'benchmark.Name' in scene
    assert 'benchmark.CenterZ' in scene
    assert "CollectionService:AddTag(part, \"RecoverySurface\")" not in scene.split("local function buildReferenceBenchmark", 1)[1].split("end", 1)[0]

    assert "local benchmark = M0SceneConfig.ReferenceBenchmark" in stage_b
    assert "benchmark.SpawnX" in stage_b
    assert "laneCenterZ = benchmark.CenterZ" in stage_b
    assert "waitForContinuousTrackContact" in stage_b
    assert "result.valid = false" in stage_b
    assert "M0SceneConfig.Spawn.X" not in stage_b.split("local function runFlatSpeedTrial", 1)[1].split("local function runProgressTrial", 1)[0]


def test_p3_g0_recovery_records_real_below_threshold_trigger() -> None:
    harness = read("src/server/Tests/M0HumanHarness.lua")

    assert 'model:SetAttribute("RecoveryCount", 0)' in harness
    assert "local triggerY = racer:GetBody().Position.Y" in harness
    assert "triggerY < M0SceneConfig.RecoveryKillY" in harness
    assert 'model:SetAttribute("RecoveryCount", recoveryCount)' in harness
    assert "[DrawRacers][R16.6][G0] recovery triggerY=" in harness
    assert "ShapeSpec" in harness and "ShapeVersion" in harness
    assert "body.Position.Y < M0SceneConfig.RecoveryKillY" in harness


def test_p4_full_matrix_uses_shared_trial_runner_and_real_winner_intersection() -> None:
    runner_path = ROOT / "src/server/Tests/R16TrialRunner.lua"
    assert runner_path.exists(), "P4 requires a shared Studio-only R16TrialRunner"
    runner = runner_path.read_text(encoding="utf-8")
    stage_b = read("src/server/Tests/R16StageBHarness.lua")

    assert "function R16TrialRunner.RunFlat" in runner
    assert "function R16TrialRunner.RunPiece" in runner
    assert "function R16TrialRunner.DestroyActive" in runner
    assert "R16ReferenceShapes.Get(shapeId)" in runner
    assert "M0SceneConfig.ReferenceBenchmark" in runner

    assert "local ALL_SHAPES = {" in stage_b
    for shape_id in [
        "ROUND_01",
        "LONG_BAR_01",
        "SMALL_ROUND_01",
        "HOOK_01",
        "ASYM_01",
        "SUBOPTIMAL_01",
    ]:
        assert f'"{shape_id}"' in stage_b

    assert "R16TrialRunner.RunFlat" in stage_b
    assert "R16TrialRunner.RunPiece" in stage_b
    assert "local winnerSets =" in stage_b
    assert "local function intersectWinnerSets" in stage_b
    assert "local noUniversalWinner = #universalWinners == 0" in stage_b
    assert "suboptimalFlatPassed or suboptimalStepsPassed" in stage_b
    assert "stepsNichePassed and gapNichePassed and tunnelNichePassed and suboptimalPassed" not in stage_b
