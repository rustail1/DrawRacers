from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b02_local_preview_contract() -> None:
    controller = ROOT / "src" / "client" / "Controllers" / "DrawingController.lua"
    assert controller.is_file(), "missing DrawingController.lua"
    text = controller.read_text(encoding="utf-8")

    for token in [
        '"SafeRoot"',
        '"DrawCanvas"',
        '"DrawInputRect"',
        '"StrokePreview"',
        '"AcceptedShapeThumbnail"',
        '"EmptyGhost"',
        '"ValidationToast"',
        '"DrawHint"',
    ]:
        assert token in text, f"missing hierarchy token {token}"

    # R16.3B: DrawInputRect is the full visible 1.75:1 semantic drawing surface.
    assert "UDim2.fromScale(0.46, 0.28)" in text
    assert "UDim2.fromScale(0.64, 0.34)" in text
    assert "UDim2.fromScale(1, 1)" in text
    assert "R16WideDrawSurfaceConstraint" in text
    assert "inputController:Bind(drawInputRect)" in text

    for phase in [
        'event.phase == "start"',
        'event.phase == "move"',
        'event.phase == "end"',
        'event.phase == "cancel"',
    ]:
        assert phase in text, f"missing B02 phase handler {phase}"

    assert "acceptedPoints" in text
    assert "livePoints" in text
    assert "renderAcceptedStroke" in text
    assert "clearLiveStroke" in text


def test_b02_bootstrap_keeps_drawing_controller_and_allows_later_dependencies() -> None:
    bootstrap = (ROOT / "src" / "client" / "Bootstrap.client.lua").read_text(encoding="utf-8")
    assert 'WaitForChild("DrawingController")' in bootstrap
    assert "DrawingController.new(inputController, drawHud" in bootstrap
    assert "drawingController:Start()" in bootstrap
    assert "B01InputHarness" not in bootstrap


def test_b02_drawhud_wait_is_bounded_and_fails_closed() -> None:
    bootstrap = (ROOT / "src" / "client" / "Bootstrap.client.lua").read_text(encoding="utf-8")
    assert "DRAW_HUD_WAIT_TIMEOUT" in bootstrap
    assert 'WaitForChild("DrawHUD", DRAW_HUD_WAIT_TIMEOUT)' in bootstrap
    assert 'assert(drawHudInstance and drawHudInstance:IsA("ScreenGui")' in bootstrap
    assert 'WaitForChild("DrawHUD") :: ScreenGui' not in bootstrap
