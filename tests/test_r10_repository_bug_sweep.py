from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r10_accepted_stroke_thickness_uses_live_pointer_only_while_drawing() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    start = drawing.index("function DrawingController:_strokeThickness")
    end = drawing.index("function DrawingController:_renderAcceptedStroke", start)
    block = drawing[start:end]

    assert "self._drawing" in block
    assert "self._pointerFamily" in block
    assert "self._layoutFamily" in block
    assert "if self._drawing then self._pointerFamily else self._layoutFamily" in block


def test_r10_empty_ghost_stays_gone_after_first_pointer_down() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert "_hasStartedStroke = false" in drawing
    assert "self._hasStartedStroke = true" in drawing
    assert "emptyGhost.Visible = #self._acceptedSemanticPoints == 0" not in drawing
    assert "emptyGhost.Visible = not self._hasStartedStroke" in drawing


def test_r10_validation_toast_is_mutually_exclusive_and_bounded_to_two_seconds() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert "local VALIDATION_TOAST_DURATION = 2.0" in drawing
    assert "_validationGeneration = 0" in drawing
    assert "task.delay(VALIDATION_TOAST_DURATION" in drawing
    assert "generation == self._validationGeneration" in drawing
    assert "self._ui.drawHint.Visible = false" in drawing


def test_r10_layout_family_ignores_unsupported_input_types() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert "local function inputTypeFamily(inputType: Enum.UserInputType): string?" in drawing
    assert "Enum.UserInputType.Keyboard" in drawing
    assert "Enum.UserInputType.MouseMovement" in drawing
    assert "return nil" in drawing[drawing.index("local function inputTypeFamily"):drawing.index("local function initialLayoutFamily")]

    handler_start = drawing.index("UserInputService.LastInputTypeChanged")
    handler_end = drawing.index("print(\"[DrawRacers][B02] local draw preview ready\")", handler_start)
    handler = drawing[handler_start:handler_end]
    assert "family == nil" in handler
    assert "return" in handler
    assert "self:_applyLayout(family)" in handler
