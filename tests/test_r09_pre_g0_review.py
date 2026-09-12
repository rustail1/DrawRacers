from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r09_accepted_preview_is_semantic_and_touch_layout_uses_current_rcp03_tokens() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    for token in [
        "_acceptedSemanticPoints",
        "copySemanticPoints",
        "semanticPointsToPixels",
        "TOUCH_VALIDATION_POSITION",
        "TOUCH_VALIDATION_SIZE",
        "TOUCH_HINT_POSITION",
        "TOUCH_HINT_SIZE",
        "UDim2.fromScale(0.5, 0.565)",
        "UDim2.fromScale(0.5, 0.475)",
        "UDim2.fromScale(0.44, 0.058)",
        "UDim2.fromScale(0.50, 0.064)",
        "LegShapeMath.BuildCanonical",
    ]:
        assert token in drawing, f"missing R09 responsive/semantic preview token: {token}"

    assert "self._pendingStrokes[sequence] = copyPoints(previewPixels)" not in drawing
    assert "points = copySemanticPoints(rawSemanticPoints)" in drawing
    assert "copySemanticPoints(result.acceptedPoints)" in drawing
    assert "_presentationAnchors" in drawing

    apply_layout = drawing[
        drawing.index("function DrawingController:_applyLayout"):
        drawing.index("function DrawingController:_applyPendingLayout")
    ]
    assert "validationToast.Position" in apply_layout
    assert "validationToast.Size" in apply_layout
    assert "drawHint.Position" in apply_layout
    assert "drawHint.Size" in apply_layout
    assert "_renderAcceptedStroke" in apply_layout


def test_r09_obstacle_requirement_tag_overrides_recovery_surface_assist() -> None:
    anti_stall = read("src/server/Runtime/RacerAntiStall.lua")
    classify = anti_stall[
        anti_stall.index("local function classifyContactSurface"):
        anti_stall.index("function RacerAntiStall.new")
    ]

    requirement_index = classify.index("local requirementTag = getRequirementTag(surface)")
    recovery_index = classify.index("hasRecoverySurfaceTag(surface)")
    assert requirement_index < recovery_index, "RequirementTag must be inspected before RecoverySurface eligibility"
    assert 'requirementTag ~= nil and requirementTag ~= "FAST_ROLL"' in classify
    assert 'return "OBSTACLE"' in classify
    assert 'requirementTag == "FAST_ROLL"' in classify


def test_r09_spawned_racer_drops_template_only_runtime_attachments_folder() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert 'model:FindFirstChild("RuntimeAttachments")' in stabilizer
    assert "runtimeAttachments:Destroy()" in stabilizer

    take_lane = stabilizer.index('takeAttachment(runtimeAttachments, body, "LaneAlignAttachment")')
    take_orientation = stabilizer.index('takeAttachment(runtimeAttachments, body, "OrientationAttachment")')
    destroy_folder = stabilizer.index("runtimeAttachments:Destroy()")
    assert take_lane < destroy_folder and take_orientation < destroy_folder
