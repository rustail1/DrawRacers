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
        "return leftLeg, rightLeg",
    ]:
        assert token in apply_shape, f"missing stable-axle redraw token: {token}"

    assert "self.leftLeg" not in apply_shape
    assert "self.rightLeg" not in apply_shape
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
    for token in [
        "self.leftLeg:ReplaceGeometry(shapeSpec)",
        "self.rightLeg:ReplaceGeometry(shapeSpec)",
        "self.leftLeg:SetReshapeProgress(0)",
        "self.rightLeg:SetReshapeProgress(0)",
    ]:
        assert token in begin, f"missing persistent-side redraw token: {token}"

    for forbidden in [
        "stagedLeft", "stagedRight", "oldLeft", "oldRight",
        "SetRetiring", "LegAssembly.new", 'Instance.new("HingeConstraint")',
    ]:
        assert forbidden not in begin, f"legacy replacement-side redraw remains: {forbidden}"

    assert "function LegAssembly:Commit()" not in leg
    assert "function LegAssembly:SetRetiring" not in leg
    assert "phaseSyncConnection" not in runtime


def test_b13_studio_spec_is_wired() -> None:
    spec_path = ROOT / "src" / "server" / "Tests" / "B13AtomicRedrawSpec.lua"
    assert spec_path.is_file(), "missing B13 Studio behavior spec"
    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B13AtomicRedrawSpec" in bootstrap
    assert "B13AtomicRedrawSpec.run()" in bootstrap
