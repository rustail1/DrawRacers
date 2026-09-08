from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b01_input_controller_contract() -> None:
    controller = ROOT / "src" / "client" / "Controllers" / "InputController.lua"
    assert controller.is_file(), "missing InputController.lua"
    text = controller.read_text(encoding="utf-8")

    for token in ['"start"', '"move"', '"end"', '"cancel"']:
        assert token in text, f"missing semantic phase {token}"

    for token in [
        "Enum.UserInputType.MouseButton1",
        "Enum.UserInputType.MouseMovement",
        "Enum.UserInputType.Touch",
    ]:
        assert token in text, f"missing input family token {token}"

    assert "target.Active = true" in text
    assert "WindowFocusReleased" in text
    assert "InputChanged" in text
    assert "InputEnded" in text
    assert ":: any ::" not in text
    assert "workspace.CurrentCamera" not in text
    assert "CameraType" not in text


def test_b01_pointer_dependency_is_preserved_after_harness_removal() -> None:
    bootstrap = (ROOT / "src" / "client" / "Bootstrap.client.lua").read_text(encoding="utf-8")
    drawing = (ROOT / "src" / "client" / "Controllers" / "DrawingController.lua").read_text(encoding="utf-8")

    assert 'WaitForChild("InputController")' in bootstrap
    assert "InputController.new()" in bootstrap
    # B01 owns the InputController dependency, not the final constructor arity.
    # Later accepted stages may inject remotes/services after drawHud.
    assert "DrawingController.new(inputController, drawHud" in bootstrap
    assert "inputController:Bind(drawInputRect)" in drawing
    assert "B01InputHarness" not in bootstrap
