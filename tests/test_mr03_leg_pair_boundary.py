from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_mr03_pair_has_one_persistent_axle_motor_and_no_staging_lifecycle() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")

    assert pair.count('Instance.new("HingeConstraint")') == 1
    for required in [
        'axleRoot.Name = "AxleRoot"',
        'joint.Name = "AxleJoint"',
        'side = "Left"',
        'side = "Right"',
        "function LegPairAssembly:SetInitialPhaseDegrees",
        "motorEverEnabled",
        "function LegPairAssembly:SetEnabled",
        "function LegPairAssembly:BeginGeometryReshape",
        "function LegPairAssembly:CompleteReshapeForRecovery",
    ]:
        assert required in pair, f"missing MR-03 persistent-pair token: {required}"

    for retired in [
        "staged",
        "stagingContainer",
        "LegPairStaging",
        "committed",
        "function LegPairAssembly:Commit",
        "function LegPairAssembly:IsCommitted",
    ]:
        assert retired not in pair, f"retired MR-02 bridge remains in LegPairAssembly: {retired}"


def test_mr03_initial_phase_can_change_only_before_first_motor_activation() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    start = pair.index("function LegPairAssembly:SetInitialPhaseDegrees")
    end = pair.index("function LegPairAssembly:", start + len("function LegPairAssembly:SetInitialPhaseDegrees"))
    body = pair[start:end]

    assert "self.motorEverEnabled" in body
    assert "self.joint.Enabled" in body
    assert "axleBaseCFrame(self.body)" in body
    assert "self.axleRoot.CFrame" in body
    assert "self.body.CFrame =" not in body
    assert "AssemblyLinearVelocity =" not in body
    assert "AssemblyAngularVelocity =" not in body

    enable_start = pair.index("function LegPairAssembly:SetEnabled")
    destroy_start = pair.index("function LegPairAssembly:Destroy", enable_start)
    enable_body = pair[enable_start:destroy_start]
    assert "self.motorEverEnabled = true" in enable_body
    assert "self.joint.Enabled = enabled" in enable_body


def test_mr03_initial_runtime_builds_exactly_one_pair_then_selects_phase_and_enables_motor() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    start = runtime.index("function RacerRuntime:_CreateInitialLegPair")
    end = runtime.index("function RacerRuntime:_ApplyShapeSpec", start)
    initial = runtime[start:end]

    assert initial.count("LegPairAssembly.new") == 1, "initial placement must create exactly one persistent pair"
    assert "RedrawSpawnSafety.ChoosePhase" in initial
    assert "SetInitialPhaseDegrees(selectedPhaseDegrees)" in initial
    assert "SetEnabled(motorEnabled == true)" in initial
    assert initial.index("RedrawSpawnSafety.ChoosePhase") < initial.index("SetInitialPhaseDegrees(selectedPhaseDegrees)")
    assert initial.index("SetInitialPhaseDegrees(selectedPhaseDegrees)") < initial.index("SetEnabled(motorEnabled == true)")

    for retired in [
        "staged = true",
        ":Commit()",
        "stagedLegPair",
    ]:
        assert retired not in initial, f"retired initial staging path remains: {retired}"


def test_mr03_redraw_keeps_existing_pair_identity() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    start = runtime.index("function RacerRuntime:_ApplyShapeSpec")
    end = runtime.index("function RacerRuntime:ApplyShape", start)
    apply_body = runtime[start:end]

    assert "self.legPair:BeginGeometryReshape(shapeSpec)" in apply_body
    assert "LegPairAssembly.new" not in apply_body
    assert "self.body.CFrame =" not in apply_body
    assert "AssemblyLinearVelocity =" not in apply_body
    assert "AssemblyAngularVelocity =" not in apply_body
