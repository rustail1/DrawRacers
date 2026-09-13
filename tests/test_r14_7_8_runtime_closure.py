from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_7_atomic_redraw_covers_persistent_pair_and_side_identity() -> None:
    studio_spec = read("src/server/Tests/B13AtomicRedrawSpec.lua")

    for token in [
        "local axle = pair:GetRoot()",
        "local joint = pair:GetJoint()",
        "local left = pair:GetLeftLeg()",
        "local right = pair:GetRightLeg()",
        'invalid.accepted == false',
        'racer:GetShapeVersion() == 1',
        'second.accepted == true and second.shapeVersion == 2',
        'racer:GetLegPair() == pair',
        'pair:GetRoot() == axle and pair:GetJoint() == joint',
        'pair:GetLeftLeg() == left and pair:GetRightLeg() == right',
        'body.CFrame == bodyCFrameBefore',
        'body.AssemblyLinearVelocity == linearBefore',
        'body.AssemblyAngularVelocity == angularBefore',
        '"LeftLeg_Retiring"',
        '"RightLeg_Retiring"',
        '"AxleRoot_Retiring"',
    ]:
        assert token in studio_spec, f"B13 persistent redraw spec missing token: {token}"

    for obsolete in [
        "B13 injected right-leg build failure",
        "B13 injected right-leg commit failure",
        "B13 injected post-enable failure",
        "LegAssembly.Commit",
        "LegPairAssembly.SetEnabled = function",
    ]:
        assert obsolete not in studio_spec, f"B13 still encodes retired staged-side failure path: {obsolete}"


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
