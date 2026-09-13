from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_bg04_reshape_has_bounded_gravity_support_on_stable_pair() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")

    assert "GravityCompensationFraction = 1.0" in config
    assert 'ReshapeSupportAttachment' in pair
    assert 'ReshapeSupportForce' in pair
    assert 'Instance.new("VectorForce")' in pair
    assert "ApplyAtCenterOfMass = true" in pair
    assert "Enum.ActuatorRelativeTo.World" in pair
    assert "AssemblyMass * Workspace.Gravity" in pair
    assert "_SetReshapeSupportEnabled(true)" in pair
    assert "_SetReshapeSupportEnabled(false)" in pair
    begin = pair.split("function LegPairAssembly:BeginGeometryReshape", 1)[1].split(
        "function LegPairAssembly:SetReshapeProgress", 1
    )[0]
    assert begin.index("_SetReshapeSupportEnabled(true)") < begin.index("oldLeft:Destroy()")


def test_bg05_recovery_finishes_transient_reshape_before_teleport() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    harness = read("src/server/Tests/M0HumanHarness.lua")
    config = read("src/shared/Config/M0SceneConfig.lua")

    assert "function LegPairAssembly:CompleteReshapeForRecovery" in pair
    complete = pair.split("function LegPairAssembly:CompleteReshapeForRecovery", 1)[1].split(
        "function LegPairAssembly:", 1
    )[0]
    assert "self.reshapeForcedComplete = true" in complete
    assert "self:SetReshapeProgress(1)" in complete
    assert "pair:CompleteReshapeForRecovery()" in harness
    assert harness.index("pair:CompleteReshapeForRecovery()") < harness.index("model:PivotTo")
    assert "RecoveryKillY = -12" in config


def test_bg06_g0_entry_floor_covers_max_leg_reach_behind_spawn() -> None:
    scene = read("src/server/M0TestScene.lua")

    assert 'WaitForChild("PhysicsConfig")' in scene
    assert "MaxLegExtentFromHub" in scene
    assert "local entryStartX" in scene
    assert "config.Spawn.X" in scene
    assert 'makeTrackPart("EntryFloor", entryStartX, config.Pieces[1].StartX' in scene
    assert 'makeTrackPart("EntryFloor", 0, config.Pieces[1].StartX' not in scene
