from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_7_atomic_redraw_covers_persistent_pair_drive_and_side_identity() -> None:
    studio_spec = read("src/server/Tests/B13AtomicRedrawSpec.lua")

    for token in [
        "local leftDrive = pair:GetLeftDrive()",
        "local rightDrive = pair:GetRightDrive()",
        "local leftJoint = leftDrive:GetJoint()",
        "local rightJoint = rightDrive:GetJoint()",
        "local left = leftDrive:GetLeg()",
        "local right = rightDrive:GetLeg()",
        'invalid.accepted == false',
        'racer:GetShapeVersion() == 1',
        'second.accepted == true and second.shapeVersion == 2',
        'racer:GetLegPair() == pair',
        'pair:GetLeftDrive() == leftDrive and pair:GetRightDrive() == rightDrive',
        'leftDrive:GetJoint() == leftJoint and rightDrive:GetJoint() == rightJoint',
        'pair:GetLeftLeg() == left and pair:GetRightLeg() == right',
        'body.CFrame == bodyCFrameBefore',
        'countNamedDriveModels(legsFolder) == 2',
        'countHinges(model) == 2',
        'assertNoPendingGeometry(model)',
    ]:
        assert token in studio_spec, f"B13 CR2 redraw spec missing token: {token}"

    for obsolete in [
        "AxleRoot_Retiring",
        "LeftLeg_Retiring",
        "RightLeg_Retiring",
        "pair:GetRoot()",
        "pair:GetJoint()",
        "LegAssembly.Commit",
        "LegPairAssembly.SetEnabled = function",
    ]:
        assert obsolete not in studio_spec, f"B13 still encodes retired shared-axle/staged-side path: {obsolete}"


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
