from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_mr04_runtime_uses_shared_canonical_shape_owner_for_internal_apply() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    internal = section(runtime, "local function makeInternalShapeSpec", "local function publishValidatedShapeState")
    assert "CanonicalLegShape.Build" in internal
    assert "StrokeMath" not in internal
    assert "GeometryMath" not in internal


def test_mr04_runtime_has_one_pair_constructor_and_transactional_redraw() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    initial = section(runtime, "function RacerRuntime:_CreateInitialLegPair", "function RacerRuntime:_ApplyShapeSpec")
    apply_body = section(runtime, "function RacerRuntime:_ApplyShapeSpec", "function RacerRuntime:ApplyShape")
    assert initial.count("LegPairAssembly.new") == 1
    assert "self.legPair = legPair" in initial
    assert "LegPairAssembly.new" not in apply_body
    assert "self.legPair:StageRedraw(shapeSpec)" in apply_body
    assert "self.legPair:CommitStagedRedraw()" in apply_body
    assert "REDRAW_PENDING" in apply_body


def test_mr04_recovery_is_destination_independent_and_cancels_redraw() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    recovery = section(runtime, "function RacerRuntime:PrepareForRecovery", "function RacerRuntime:_CreateInitialLegPair")
    assert "self:_CancelReshape()" in recovery
    assert "self.legPair:PrepareForRecovery()" in recovery
    for forbidden in ["PivotTo", "CFrame =", "AssemblyLinearVelocity", "AssemblyAngularVelocity"]:
        assert forbidden not in recovery


def test_mr04_validated_shape_publishes_only_after_mechanical_apply() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    validated = section(runtime, "function RacerRuntime:ApplyValidatedShape", "function RacerRuntime:IsDestroyed")
    apply_index = validated.index("self:_ApplyShapeSpec(shapeSpec, motorEnabled)")
    publish_index = validated.index("publishValidatedShapeState(self, shapeSpec)")
    assert apply_index < publish_index
    assert "accepted = false" in validated
    assert "accepted = true" in validated


def test_mr04_destroy_cancels_pending_transaction_before_owned_instances() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    destroy = section(runtime, "function RacerRuntime:Destroy", "return RacerRuntime")
    cancel_index = destroy.index("self:_CancelReshape()")
    pair_index = destroy.index("self.legPair:Destroy()")
    assert cancel_index < pair_index
