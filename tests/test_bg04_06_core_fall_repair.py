from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_bg04_reshape_has_bounded_gravity_support_and_runs_before_physics() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    assert "GravityCompensationFraction = 1.0" in config
    assert 'ReshapeSupportAttachment' in runtime
    assert 'ReshapeSupportForce' in runtime
    assert 'Instance.new("VectorForce")' in runtime
    assert "ApplyAtCenterOfMass = true" in runtime
    assert "Enum.ActuatorRelativeTo.World" in runtime
    assert "AssemblyMass * Workspace.Gravity" in runtime
    assert "RunService.PreSimulation:Connect" in runtime
    assert "_SetReshapeSupportEnabled(true)" in runtime
    assert "_SetReshapeSupportEnabled(false)" in runtime


def test_bg05_recovery_finishes_transient_reshape_before_teleport() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    harness = read("src/server/Tests/M0HumanHarness.lua")
    config = read("src/shared/Config/M0SceneConfig.lua")

    assert "function RacerRuntime:PrepareForRecovery" in runtime
    prepare = runtime.split("function RacerRuntime:PrepareForRecovery", 1)[1].split("function RacerRuntime:", 1)[0]
    assert "self:_CancelReshape()" in prepare
    assert "self.legPair:SetReshapeProgress(1)" in prepare
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
