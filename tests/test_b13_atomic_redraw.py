from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b13_atomic_redraw_contract() -> None:
    runtime = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")

    for token in [
        "captureLegPhaseDegrees",
        "stagedLeftLeg",
        "stagedRightLeg",
        "staged = true",
        "stagedLeftLeg:Commit()",
        "stagedRightLeg:Commit()",
        'oldLeftModel.Name = "LeftLeg_Retiring"',
        'oldRightModel.Name = "RightLeg_Retiring"',
        "oldLeftLeg:Destroy()",
        "oldRightLeg:Destroy()",
    ]:
        assert token in runtime, f"missing B13 atomic redraw token: {token}"

    stage_index = runtime.index("stagedLeftLeg = LegAssembly.new")
    commit_index = runtime.index("stagedLeftLeg:Commit()")
    old_destroy_index = runtime.index("oldLeftLeg:Destroy()")
    assert stage_index < commit_index < old_destroy_index, "old legs must survive until both replacements are staged and committed"

    apply_shape = runtime[runtime.index("function RacerRuntime:ApplyShape"):runtime.index("function RacerRuntime:ApplyValidatedShape")]
    for forbidden in [
        "self.body.CFrame =",
        "body.CFrame =",
        "AssemblyLinearVelocity =",
        "AssemblyAngularVelocity =",
        "PivotTo(",
    ]:
        assert forbidden not in apply_shape, f"B13 redraw must not teleport/reset body state: {forbidden}"

    for token in [
        "staged: boolean?",
        "local staged = params.staged == true",
        "if not staged then",
        "function LegAssembly:Commit()",
        "self.model.Parent = self.legsFolder",
        "function LegAssembly:IsCommitted()",
    ]:
        assert token in leg, f"missing B13 detached staging token: {token}"


def test_b13_studio_spec_is_wired() -> None:
    spec_path = ROOT / "src" / "server" / "Tests" / "B13AtomicRedrawSpec.lua"
    assert spec_path.is_file(), "missing B13 Studio behavior spec"
    spec = spec_path.read_text(encoding="utf-8")

    for token in [
        "BUILD_FAILED",
        "AssemblyLinearVelocity",
        "AssemblyAngularVelocity",
        "CFrame",
        "phase",
        "old LeftLeg changed after failed redraw",
        "old RightLeg changed after failed redraw",
        "atomic redraw tests PASS",
    ]:
        assert token in spec, f"missing B13 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B13AtomicRedrawSpec" in bootstrap
    assert "B13AtomicRedrawSpec.run()" in bootstrap
