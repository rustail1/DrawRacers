from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_redraw_has_pure_bounded_phase_selector() -> None:
    math_path = ROOT / "src" / "shared" / "Math" / "RedrawSafetyMath.lua"
    assert math_path.is_file(), "safe redraw requires pure RedrawSafetyMath"
    text = math_path.read_text(encoding="utf-8")

    for token in [
        "function RedrawSafetyMath.BuildCandidatePhases",
        "function RedrawSafetyMath.ChooseBestCandidate",
        "function RedrawSafetyMath.AngularDistanceDegrees",
        "0, 15, -15, 30, -30, 45, -45, 60, -60, 75, -75, 90, -90",
    ]:
        assert token in text, f"missing redraw safety math token: {token}"

    for forbidden in ["Workspace", "GetPartBoundsInBox", "Instance.new", "RunService"]:
        assert forbidden not in text, f"pure redraw safety math must not depend on runtime: {forbidden}"


def test_redraw_scores_staged_segments_against_track_before_commit() -> None:
    safety_path = ROOT / "src" / "server" / "Runtime" / "RedrawSpawnSafety.lua"
    assert safety_path.is_file(), "safe redraw requires server overlap scorer"
    safety = safety_path.read_text(encoding="utf-8")
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    for token in [
        "RedrawSafetyMath",
        "Workspace:GetPartBoundsInBox",
        "OverlapParams.new()",
        "Runtime",
        "Tracks",
        "GetLeftLeg",
        "GetRightLeg",
        "GetSegments",
        "SHRINK_INSETS",
        "function RedrawSpawnSafety.ChoosePhase",
    ]:
        assert token in safety, f"missing redraw overlap safety token: {token}"

    for token in [
        'require(script.Parent:WaitForChild("RedrawSpawnSafety"))',
        "RedrawSpawnSafety.ChoosePhase",
        "selectedPhaseDegrees",
        "redrawSafetyFallback",
        "stagedLegPair:Commit()",
        "oldLegPair:SetRetiring(true)",
    ]:
        assert token in runtime, f"runtime missing safe redraw token: {token}"

    choose_index = runtime.index("RedrawSpawnSafety.ChoosePhase")
    retire_index = runtime.index("oldLegPair:SetRetiring(true)")
    commit_index = runtime.index("stagedLegPair:Commit()")
    assert choose_index < retire_index < commit_index, "phase safety must run while old pair is still active"

    apply_body = runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]
    for forbidden in [
        "self.body.CFrame =",
        "body.CFrame =",
        "AssemblyLinearVelocity =",
        "AssemblyAngularVelocity =",
        "body:PivotTo(",
    ]:
        assert forbidden not in apply_body, f"safe redraw must not teleport/reset body: {forbidden}"


def test_b13_covers_safe_phase_selection_and_rollback() -> None:
    spec = read("src/server/Tests/B13AtomicRedrawSpec.lua")
    assert "RedrawSpawnSafety" in spec
    assert "ChoosePhase" in spec
    assert "safe phase" in spec.lower()
    assert "old pair changed after failed redraw" in spec
