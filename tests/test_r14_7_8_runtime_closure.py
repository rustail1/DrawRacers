from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_7_atomic_redraw_covers_post_commit_enable_failure() -> None:
    studio_spec = read("src/server/Tests/B13AtomicRedrawSpec.lua")

    assert "local originalSetEnabled = LegAssembly.SetEnabled" in studio_spec
    assert "B13 injected post-enable failure" in studio_spec
    assert "enableFailed.accepted == false" in studio_spec
    assert 'enableFailed.rejectReasonCode == "BUILD_FAILED"' in studio_spec
    assert '"enable failure changed ShapeVersion"' in studio_spec
    assert '"old LeftLeg not restored after enable failure"' in studio_spec
    assert '"old RightLeg not restored after enable failure"' in studio_spec
    assert '"enable failure leaked staged leg models"' in studio_spec
    assert "LegAssembly.SetEnabled = originalSetEnabled" in studio_spec


def test_r14_8_transport_limits_do_not_mislead_as_geometry_feedback() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    start = drawing.index("local function validationMessageForReason")
    end = drawing.index("local function inputTypeFamily", start)
    mapping = drawing[start:end]

    for semantic_reason in ["TOO_FEW_POINTS", "TOO_SHORT", "INVALID_STROKE"]:
        assert f'reasonCode == "{semantic_reason}"' in mapping

    for technical_reason in ["TOO_MANY_POINTS", "TOO_MANY_CLEANED_POINTS", "PAYLOAD_TOO_LARGE"]:
        assert f'reasonCode == "{technical_reason}"' not in mapping

    assert 'return "DRAW A DIFFERENT SHAPE"' in mapping
    assert 'return "TRY AGAIN"' in mapping
