from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cr3_mechanical_exception_cancels_redraw_transaction_before_reject() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    cancel = runtime.split("function RacerRuntime:_CancelReshape", 1)[1].split("function RacerRuntime:PrepareForRecovery", 1)[0]
    validated = runtime.split("function RacerRuntime:ApplyValidatedShape", 1)[1].split("function RacerRuntime:IsDestroyed", 1)[0]

    assert "self._redrawPending = false" in cancel
    assert "self.legPair:CancelStagedRedraw()" in cancel

    failure_start = validated.index("if not applied then")
    failure_end = validated.index("\n\tend", failure_start)
    failure = validated[failure_start:failure_end]
    assert "self:_CancelReshape()" in failure
    assert failure.index("self:_CancelReshape()") < failure.index('rejectReasonCode = "BUILD_FAILED"')


def test_cr3_mechanical_exception_cleanup_does_not_publish_failed_shape() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    validated = runtime.split("function RacerRuntime:ApplyValidatedShape", 1)[1].split("function RacerRuntime:IsDestroyed", 1)[0]
    failure_start = validated.index("if not applied then")
    failure_end = validated.index("\n\tend", failure_start)
    failure = validated[failure_start:failure_end]

    assert "publishValidatedShapeState" not in failure
    assert 'rejectReasonCode = "BUILD_FAILED"' in failure
    assert validated.index('rejectReasonCode = "BUILD_FAILED"') < validated.index("publishValidatedShapeState(self, shapeSpec)")
