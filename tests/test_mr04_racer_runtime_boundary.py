from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_mr04_runtime_uses_shared_canonical_shape_owner_for_internal_apply() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    assert 'WaitForChild("CanonicalLegShape")' in runtime
    assert 'WaitForChild("StrokeMath")' not in runtime
    assert 'WaitForChild("GeometryMath")' not in runtime

    internal = section(runtime, "local function makeInternalShapeSpec", "function RacerRuntime.new")
    assert "CanonicalLegShape.Build" in internal
    assert "PhysicsConfig.StrokeProcessing" in internal
    assert "PhysicsConfig.LegGeometry" in internal
    assert "StrokeMath." not in internal
    assert "GeometryMath." not in internal


def test_mr04_runtime_has_one_pair_constructor_and_no_duplicate_side_ownership_cache() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    initial = section(runtime, "function RacerRuntime:_CreateInitialLegPair", "function RacerRuntime:_ApplyShapeSpec")
    apply_body = section(runtime, "function RacerRuntime:_ApplyShapeSpec", "function RacerRuntime:ApplyShape")

    assert runtime.count("LegPairAssembly.new") == 1
    assert "LegPairAssembly.new" in initial
    assert "LegPairAssembly.new" not in apply_body
    assert "self.legPair:BeginGeometryReshape(shapeSpec)" in apply_body

    assert "self.leftLeg" not in runtime
    assert "self.rightLeg" not in runtime
    assert 'Instance.new("HingeConstraint")' not in runtime
    assert 'Instance.new("WedgePart")' not in runtime
    assert 'Instance.new("MeshPart")' not in runtime


def test_mr04_recovery_is_destination_independent_and_runtime_owned() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    recovery = section(runtime, "function RacerRuntime:PrepareForRecovery", "function RacerRuntime:_CancelReshape")

    assert "self:_CancelReshape()" in recovery
    assert "self.legPair:CompleteReshapeForRecovery()" in recovery
    for forbidden in [
        "PivotTo",
        ".CFrame =",
        "AssemblyLinearVelocity",
        "AssemblyAngularVelocity",
        "M0SceneConfig",
        "RecoveryKillY",
    ]:
        assert forbidden not in recovery, f"recovery preparation owns destination/teleport policy: {forbidden}"


def test_mr04_validated_shape_publishes_authoritative_state_only_after_mechanical_apply() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    validated = section(runtime, "function RacerRuntime:ApplyValidatedShape", "function RacerRuntime:IsDestroyed")

    apply_index = validated.index("self:_ApplyShapeSpec(shapeSpec, motorEnabled)")
    current_index = validated.index("self.currentShapeSpec = shapeSpec")
    version_index = validated.index('self.model:SetAttribute("ShapeVersion", shapeSpec.version)')
    assert apply_index < current_index < version_index
    assert "shapeSpec.version == self:GetShapeVersion() + 1" in validated


def test_mr04_destroy_cancels_transient_timeline_before_owned_instances() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    destroy = runtime.split("function RacerRuntime:Destroy", 1)[1]

    cancel_index = destroy.index("self:_CancelReshape()")
    pair_index = destroy.index("self.legPair:Destroy()")
    model_index = destroy.index("self.model:Destroy()")
    assert cancel_index < pair_index < model_index
