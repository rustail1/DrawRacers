from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b13_atomic_redraw_contract() -> None:
    runtime = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")
    pair = (ROOT / "src" / "server" / "Runtime" / "LegPairAssembly.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")

    apply_shape = runtime[runtime.index("function RacerRuntime:_ApplyShapeSpec"):runtime.index("function RacerRuntime:ApplyShape")]
    for token in [
        "self.legPair:BeginGeometryReshape(shapeSpec)",
        "self.legPair:SetEnabled",
        "self.leftLeg = leftLeg",
        "self.rightLeg = rightLeg",
    ]:
        assert token in apply_shape, f"missing stable-axle redraw token: {token}"

    assert "LegPairAssembly.new" not in apply_shape

    for forbidden in [
        "self.body.CFrame =",
        "body.CFrame =",
        "AssemblyLinearVelocity =",
        "AssemblyAngularVelocity =",
        "body:PivotTo(",
    ]:
        assert forbidden not in apply_shape, f"B13 redraw must not teleport/reset body state: {forbidden}"

    begin = pair[pair.index("function LegPairAssembly:BeginGeometryReshape"):pair.index("function LegPairAssembly:SetReshapeProgress")]
    helper = pair[pair.index("local function buildStagedSides"):pair.index("function LegPairAssembly:ReplaceGeometry")]
    for token in [
        "stagedLeft",
        "stagedRight",
        "oldLeft:SetRetiring(true)",
        "oldRight:SetRetiring(true)",
        "stagedLeft:Commit()",
        "stagedRight:Commit()",
        "oldLeft:SetRetiring(false)",
        "oldRight:SetRetiring(false)",
        "oldLeft:Destroy()",
        "oldRight:Destroy()",
    ]:
        assert token in begin, f"missing failure-atomic reshape token: {token}"

    assert "pcall" in helper and "self.axleRoot" in helper
    assert begin.index("stagedLeft:Commit()") < begin.index("oldLeft:Destroy()")
    assert begin.index("stagedRight:Commit()") < begin.index("oldRight:Destroy()")
    assert 'Instance.new("HingeConstraint")' not in begin
    assert 'Instance.new("HingeConstraint")' not in helper
    assert "function LegAssembly:Commit()" in leg
    assert "phaseSyncConnection" not in runtime


def test_b13_studio_spec_is_wired() -> None:
    spec_path = ROOT / "src" / "server" / "Tests" / "B13AtomicRedrawSpec.lua"
    assert spec_path.is_file(), "missing B13 Studio behavior spec"
    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B13AtomicRedrawSpec" in bootstrap
    assert "B13AtomicRedrawSpec.run()" in bootstrap
