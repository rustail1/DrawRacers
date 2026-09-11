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

    assert "local RECOVERY_WINDOW = 0.25" in b10
    assert "local MAX_RECOVERY_ATTEMPTS = 3" in b10
    assert "for attempt = 1, MAX_RECOVERY_ATTEMPTS do" in b10
    assert "local dt = RunService.Heartbeat:Wait()" in b10
    assert "local sampleEnd = recoveryElapsed + dt" in b10
    assert "if sampleEnd > RECOVERY_WINDOW then" in b10
    assert "recoveryElapsed = sampleEnd" in b10
    assert "recovered and recoveryElapsed <= RECOVERY_WINDOW" in b10
    assert "upright recovery evidence invalidated because Heartbeat crossed the 0.25 s window" in b10
    assert "upright recovery exceeded 0.25 s" in b10
    assert "MAX_RECOVERY_SAMPLE_DT" not in b10
    assert "recoveryElapsed += RunService.Heartbeat:Wait()" not in b10
    assert "for _ = 1, 15 do" not in b10


def test_p2_flat_speed_uses_isolated_studio_benchmark_not_canonical_course() -> None:
    config = read("src/shared/Config/M0SceneConfig.lua")
    scene = read("src/server/M0TestScene.lua")
    runner = read("src/server/Tests/R16TrialRunner.lua")
    stage_b = read("src/server/Tests/R16StageBHarness.lua")

    assert "ReferenceBenchmark = {" in config
    assert 'Name = "R16FlatBenchmark"' in config
    assert "CenterZ = 16" in config
    assert "Length = 60" in config
    assert "buildReferenceBenchmark" in scene
    assert 'benchmark.Name' in scene
    assert "CollectionService:AddTag(part, \"RecoverySurface\")" not in scene.split("local function buildReferenceBenchmark", 1)[1].split("end", 1)[0]

    assert "local benchmark = M0SceneConfig.ReferenceBenchmark" in runner
    assert "benchmark.SpawnX" in runner
    assert "laneCenterZ = benchmark.CenterZ" in runner
    assert "settleElapsed" in runner
    assert "result.valid = false" in runner
    assert "contactName = benchmark.Name" in runner
    assert "R16TrialRunner.RunFlat(shapeId)" in stage_b
    assert "M0SceneConfig.Spawn.X" not in runner.split("function R16TrialRunner.RunFlat", 1)[1].split("function R16TrialRunner.RunPiece", 1)[0]


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


def test_p5_wall_requires_suitable_success_and_suboptimal_failure() -> None:
    stage_c = read("src/server/Tests/R16StageCHarness.lua")

    assert 'R16TrialRunner = require(script.Parent:WaitForChild("R16TrialRunner"))' in stage_c
    assert 'R16TrialRunner.RunPiece("SingleWallLow", "HOOK_01"' in stage_c
    assert 'R16TrialRunner.RunPiece("SingleWallLow", "LONG_BAR_01"' in stage_c
    assert 'R16TrialRunner.RunPiece("SingleWallLow", "SUBOPTIMAL_01"' in stage_c
    assert "local wallGoodPassed = hook.completedPiece or longBar.completedPiece" in stage_c
    assert "local wallBadPassed = suboptimal.valid and not suboptimal.completedPiece" in stage_c
    assert "local wallPassed = wallGoodPassed and wallBadPassed" in stage_c
    assert "wallBadPassed" in stage_c


def test_p5_1_wall_preserves_dedicated_contact_timeout_through_trial_runner() -> None:
    runner = read("src/server/Tests/R16TrialRunner.lua")
    stage_c = read("src/server/Tests/R16StageCHarness.lua")

    assert "local contactTimeout = if options ~= nil and options.contactTimeout ~= nil" in runner
    assert "options.contactTimeout" in runner
    assert "else acceptance.TrackContactTimeout" in runner
    assert "waitForTrackContact(racer, contactTimeout, options)" in runner
    assert "contactTimeout = acceptance.WallContactTimeout" in stage_c


def test_p6_status_records_pre_studio_closure_without_passing_human_gates() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    decision_path = ROOT / "docs/DECISION_LOG_R16_PRE_STUDIO_CLOSURE_2026-09-10.md"
    assert decision_path.exists(), "P6 requires a dedicated pre-Studio closure decision log"
    decision = decision_path.read_text(encoding="utf-8")

    for doc in [session, features, decision]:
        assert "R16 PRE-STUDIO CLOSURE P0–P6" in doc
        assert "P0" in doc and "P1" in doc and "P2" in doc
        assert "P3" in doc and "P4" in doc and "P5" in doc and "P6" in doc
        assert "Studio Gate A — HUMAN STUDIO PENDING" in doc
        assert "Studio Gate B — HUMAN STUDIO PENDING" in doc
        assert "Studio Gate C — HUMAN STUDIO PENDING" in doc
        assert "B17/G0" in doc and "HUMAN_GATE" in doc

    assert "AUTOMATED GREEN" in session
    assert "AUTOMATED GREEN" in features
    assert "R16.11" in decision and "must not freeze" in decision
    assert "Studio Gate A — PASS" not in decision
    assert "Studio Gate B — PASS" not in decision
    assert "Studio Gate C — PASS" not in decision
