from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_bg04_redraw_keeps_old_physics_until_safe_commit_without_gravity_force() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "GravityCompensationFraction" not in config
    assert "ReshapeSupportForce" not in pair
    assert 'Instance.new("VectorForce")' not in pair
    stage = leg.split("function LegAssembly:SetStageProgress", 1)[1].split("function LegAssembly:CommitStagedGeometry", 1)[0]
    commit = leg.split("function LegAssembly:CommitStagedGeometry", 1)[1].split("function LegAssembly:CancelStagedGeometry", 1)[0]
    assert "self.segmentsFolder:Destroy()" not in stage
    assert "setPhysicalEnabled(self.segments, self.segmentPlan, false)" in commit
    assert "setPhysicalEnabled(pendingParts, pendingPlan, true)" in commit


def test_bg05_recovery_cancels_pending_redraw_before_harness_teleport() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    harness = read("src/server/Tests/M0HumanHarness.lua")
    config = read("src/shared/Config/M0SceneConfig.lua")
    assert "function LegPairAssembly:PrepareForRecovery" in pair
    prepare_pair = pair.split("function LegPairAssembly:PrepareForRecovery", 1)[1].split("function LegPairAssembly:", 1)[0]
    assert "self:CancelStagedRedraw()" in prepare_pair
    assert "function RacerRuntime:PrepareForRecovery" in runtime
    prepare = runtime.split("function RacerRuntime:PrepareForRecovery", 1)[1].split("function RacerRuntime:", 1)[0]
    assert "self:_CancelReshape()" in prepare
    assert "self.legPair:PrepareForRecovery()" in prepare
    assert "PivotTo" not in prepare
    assert "racer:PrepareForRecovery()" in harness
    assert harness.index("racer:PrepareForRecovery()") < harness.index("model:PivotTo")
    assert "RecoveryKillY = -12" in config


def test_bg06_g0_entry_floor_covers_max_leg_reach_behind_spawn() -> None:
    scene = read("src/server/M0TestScene.lua")
    assert 'WaitForChild("PhysicsConfig")' in scene
    assert "MaxLegExtentFromHub" in scene
    assert "local entryStartX" in scene
    assert "config.Spawn.X" in scene
    assert 'makeTrackPart("EntryFloor", entryStartX, config.Pieces[1].StartX' in scene
    assert 'makeTrackPart("EntryFloor", 0, config.Pieces[1].StartX' not in scene


def test_bg06_trial_runner_marks_falls_below_recovery_as_unsafe() -> None:
    runner = read("src/server/Tests/R16TrialRunner.lua")
    assert "fellBelowRecovery = false" in runner
    assert "result.fellBelowRecovery = true" in runner
    fall_guard = "if position.Y < M0SceneConfig.RecoveryKillY then"
    assert fall_guard in runner
    guard_body = runner.split(fall_guard, 1)[1].split("end", 1)[0]
    assert "result.fellBelowRecovery = true" in guard_body


def test_bg06_stage_b_rejects_unsafe_trials_from_shape_niches() -> None:
    stage_b = read("src/server/Tests/R16StageBHarness.lua")
    assert "local function safeResult" in stage_b
    safe_body = stage_b.split("local function safeResult", 1)[1].split("end", 1)[0]
    assert "result.valid == true" in safe_body
    assert "result.solverInstability ~= true" in safe_body
    assert "result.fellBelowRecovery ~= true" in safe_body
    assert "if not safeResult(result) then" in stage_b
    assert "safeResult(stepsRound)" in stage_b
    assert "safeResult(stepsHook) or safeResult(stepsAsym)" in stage_b
    assert "safeResult(gapLong)" in stage_b
    assert "safeResult(gapSmall)" in stage_b
    assert "safeResult(tunnelSmall)" in stage_b
    assert "safeResult(tunnelLong)" in stage_b


def test_bg06_wall_requires_safe_completion_for_suitable_shapes() -> None:
    stage_c = read("src/server/Tests/R16StageCHarness.lua")
    assert "local function safeTraversalResult" in stage_c
    safe_body = stage_c.split("local function safeTraversalResult", 1)[1].split("end", 1)[0]
    assert "result.valid == true" in safe_body
    assert "result.solverInstability ~= true" in safe_body
    assert "result.fellBelowRecovery ~= true" in safe_body
    assert "safeTraversalResult(hook) and hook.completedPiece" in stage_c
    assert "safeTraversalResult(longBar) and longBar.completedPiece" in stage_c


def test_bg06_moving_redraw_evidence_preserves_pair_and_twin_drive_identity() -> None:
    stage_c = read("src/server/Tests/R16StageCHarness.lua")
    b14 = read("src/server/Tests/B14RedrawStressSpec.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "GetLeftDrive" in pair and "GetRightDrive" in pair
    for source in (stage_c, b14):
        assert "pairAfterRedraw == pairBeforeRedraw" in source
