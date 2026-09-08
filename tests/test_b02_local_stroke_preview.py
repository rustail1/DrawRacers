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

    assert "UDim2.fromScale(0.46, 0.255)" in text
    assert "UDim2.fromScale(0.64, 0.285)" in text
    assert "UDim2.fromScale(0.92, 0.82)" in text
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
    assert "RemoteEvent" not in text


def test_b02_bootstrap_replaces_b01_harness() -> None:
    bootstrap = (ROOT / "src" / "client" / "Bootstrap.client.lua").read_text(encoding="utf-8")
    assert 'WaitForChild("DrawingController")' in bootstrap
    assert "DrawingController.new(inputController, drawHud)" in bootstrap
    assert "drawingController:Start()" in bootstrap
    assert "B01InputHarness" not in bootstrap
