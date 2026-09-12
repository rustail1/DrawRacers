from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_redraw_has_pure_bounded_phase_selector() -> None:
    math_path = ROOT / "src" / "shared" / "Math" / "RedrawSafetyMath.lua"
    assert math_path.is_file(), "safe initial placement requires pure RedrawSafetyMath"
    text = math_path.read_text(encoding="utf-8")

    for token in [
        "function RedrawSafetyMath.BuildCandidatePhases",
        "function RedrawSafetyMath.ChooseBestCandidate",
        "function RedrawSafetyMath.AngularDistanceDegrees",
        "0, 15, -15, 30, -30, 45, -45, 60, -60, 75, -75, 90, -90",
    ]:
        assert token in text, f"missing placement safety math token: {token}"

    for forbidden in ["Workspace", "GetPartBoundsInBox", "Instance.new", "RunService"]:
        assert forbidden not in text, f"pure placement safety math must not depend on runtime: {forbidden}"


def test_phase_safety_is_used_for_initial_pair_but_redraw_preserves_stable_axle_phase() -> None:
    safety_path = ROOT / "src" / "server" / "Runtime" / "RedrawSpawnSafety.lua"
    assert safety_path.is_file(), "initial placement safety requires server overlap scorer"
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
        assert token in safety, f"missing overlap safety token: {token}"

    initial = runtime.split("function RacerRuntime:_CreateInitialLegPair", 1)[1].split(
        "function RacerRuntime:_ApplyShapeSpec", 1
    )[0]
    for token in [
        'require(script.Parent:WaitForChild("RedrawSpawnSafety"))',
        "RedrawSpawnSafety.ChoosePhase",
        "selectedPhaseDegrees",
        "redrawSafetyFallback",
        "stagedLegPair:Commit()",
    ]:
        assert token in runtime if token.startswith("require") else token in initial

    apply_body = runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]
    assert "self.legPair:BeginGeometryReshape(shapeSpec)" in apply_body
    assert "RedrawSpawnSafety.ChoosePhase" not in apply_body
    assert "LegPairAssembly.new" not in apply_body

    for forbidden in [
        "self.body.CFrame =",
        "body.CFrame =",
        "AssemblyLinearVelocity =",
        "AssemblyAngularVelocity =",
        "body:PivotTo(",
    ]:
        assert forbidden not in apply_body, f"stable-axle redraw must not teleport/reset body: {forbidden}"


def test_b13_keeps_legacy_phase_safety_spec_available_for_initial_placement_evidence() -> None:
    spec = read("src/server/Tests/B13AtomicRedrawSpec.lua")
    assert "RedrawSpawnSafety" in spec
    assert "ChoosePhase" in spec
    assert "safe phase" in spec.lower()
