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

    # InputController owns pointer normalization only. Camera ownership stays elsewhere.
    assert "workspace.CurrentCamera" not in text
    assert "CameraType" not in text


def test_b01_bootstrap_has_studio_acceptance_harness() -> None:
    bootstrap = (ROOT / "src" / "client" / "Bootstrap.client.lua").read_text(encoding="utf-8")
    assert "InputController" in bootstrap
    assert "RunService:IsStudio()" in bootstrap
    assert "B01InputHarness" in bootstrap
    assert "[DrawRacers][B01]" in bootstrap
