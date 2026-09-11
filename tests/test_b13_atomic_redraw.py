from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b13_atomic_redraw_contract() -> None:
    runtime = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")
    pair = (ROOT / "src" / "server" / "Runtime" / "LegPairAssembly.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")

    for token in [
        "oldLegPair",
        "initialPhaseDegrees",
        "oldLegPair:GetPhaseDegrees()",
        "stagedLegPair",
        "staged = true",
        "RedrawSpawnSafety.ChoosePhase",
        "selectedPhaseDegrees",
        "redrawSafetyFallback",
        "stagedLegPair:Commit()",
        "stagedLegPair:SetEnabled",
        "oldLegPair:SetRetiring(true)",
        "oldLegPair:SetRetiring(false)",
        "oldLegPair:Destroy()",
    ]:
        assert token in runtime, f"missing safe atomic pair redraw token: {token}"

    stage_index = runtime.index("stagedLegPair = LegPairAssembly.new")
    safety_index = runtime.index("RedrawSpawnSafety.ChoosePhase")
    retire_index = runtime.index("oldLegPair:SetRetiring(true)")
    commit_index = runtime.index("stagedLegPair:Commit()")
    old_destroy_index = runtime.index("oldLegPair:Destroy()")
    assert stage_index < safety_index < retire_index < commit_index < old_destroy_index

    apply_shape = runtime[runtime.index("function RacerRuntime:_ApplyShapeSpec"):runtime.index("function RacerRuntime:ApplyShape")]
    for forbidden in [
        "self.body.CFrame =",
        "body.CFrame =",
        "AssemblyLinearVelocity =",
        "AssemblyAngularVelocity =",
        "body:PivotTo(",
    ]:
        assert forbidden not in apply_shape, f"B13 redraw must not teleport/reset body state: {forbidden}"

    for token in [
        "function LegPairAssembly:Commit()",
        "self.axleRoot.Parent = self.legsFolder",
        "self.leftLeg:Commit()",
        "self.rightLeg:Commit()",
        "function LegPairAssembly:IsCommitted()",
        "function LegPairAssembly:SetRetiring",
    ]:
        assert token in pair, f"missing detached pair staging token: {token}"

    assert "function LegAssembly:Commit()" in leg
    assert "phaseSyncConnection" not in runtime


def test_b13_studio_spec_is_wired() -> None:
    spec_path = ROOT / "src" / "server" / "Tests" / "B13AtomicRedrawSpec.lua"
    assert spec_path.is_file(), "missing B13 Studio behavior spec"
    spec = spec_path.read_text(encoding="utf-8")

    for token in [
        "BUILD_FAILED",
        "AssemblyLinearVelocity",
        "AssemblyAngularVelocity",
        "CFrame",
        "GetLegPair",
        "GetPhaseDegrees",
        "RedrawSpawnSafety",
        "safe phase selection replaced old pair too early",
        "selected safe phase was not applied",
        "old pair changed after failed redraw",
        "atomic redraw + safe phase tests PASS",
    ]:
        assert token in spec, f"missing B13 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B13AtomicRedrawSpec" in bootstrap
    assert "B13AtomicRedrawSpec.run()" in bootstrap
