from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r02_semantic_sampling_is_decoupled_from_visual_preview():
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "RawSampleMinMovementNormalized" in drawing
    assert "_semanticPixelPoints" in drawing
    assert "_tryAppendSemanticPoint" in drawing
    assert "MaxRawPoints" in drawing
    assert "_livePoints" in drawing


def test_r02_client_rejects_obvious_too_short_payload_before_remote():
    drawing = read("src/client/Controllers/DrawingController.lua")
    shared = read("src/shared/Math/LegShapeMath.lua")
    assert "MinimumRawPoints" in drawing
    assert "LegShapeMath.BuildCanonical" in drawing
    assert "MinimumCleanedPolylineLength" in shared
    assert "StrokeMath.MeasureLength(cleaned)" in shared
    assert '"TOO_FEW_POINTS"' in drawing
    assert "FireServer" in drawing
    assert drawing.index("LegShapeMath.BuildCanonical") < drawing.index("FireServer")


def test_r02_accepted_result_order_tracks_server_truth_not_latest_submit_only():
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "_lastAcceptedSequence" in drawing
    assert "sequence > self._lastAcceptedSequence" in drawing
    assert "self._lastAcceptedSequence = sequence" in drawing
    assert "if sequence ~= self._latestSubmittedSequence then" not in drawing

    submit_body = drawing.split("function DrawingController:_submitStrokeIntent", 1)[1].split(
        "function DrawingController:_onStrokeResult", 1
    )[0]
    assert "for oldSequence" not in submit_body, "submit must not erase older pending strokes before their result arrives"
