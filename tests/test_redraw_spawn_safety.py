from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_redraw_collision_safety_is_bounded_track_only_and_non_mutating() -> None:
    safety = read("src/server/Runtime/LegCollisionSafety.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "CandidateCount" in config
    assert "CandidateStepDegrees" in config
    assert 'runtime:FindFirstChild("Tracks")' in safety
    assert "Enum.RaycastFilterType.Include" in safety
    assert "FilterDescendantsInstances = { tracks }" in safety
    assert "Workspace:GetPartBoundsInBox" in safety
    assert "FindSafeMountOffset" in safety
    assert 'return nil, "NO_SAFE_REDRAW_PHASE"' in safety
    for forbidden in [".CFrame =", "PivotTo(", "AssemblyLinearVelocity =", "AssemblyAngularVelocity =", "Instance.new("]:
        assert forbidden not in safety


def test_collision_safety_is_used_for_initial_install_and_each_redraw_commit() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert pair.count("LegCollisionSafety.FindSafeMountOffset") >= 3
    assert "params.shapeSpec" in pair
    stage = pair.split("function LegPairAssembly:StageRedraw", 1)[1].split("function LegPairAssembly:SetStageProgress", 1)[0]
    commit = pair.split("function LegPairAssembly:CommitStagedRedraw", 1)[1].split("function LegPairAssembly:CancelStagedRedraw", 1)[0]
    assert "LegCollisionSafety.FindSafeMountOffset" in stage
    assert "LegCollisionSafety.FindSafeMountOffset" in commit
    assert "SetInitialPhaseDegrees" not in pair


def test_old_redraw_spawn_safety_is_not_a_runtime_dependency() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "RedrawSpawnSafety" not in runtime
    assert "RedrawSpawnSafety" not in pair
