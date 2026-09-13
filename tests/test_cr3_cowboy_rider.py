from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cr3_rider_has_builtin_physics_neutral_cowboy_presentation() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    assert "applyCowboyPresentation" in rider
    for token in ["CowboyHatBrim", "CowboyHatCrown", "CowboyHatBand"]:
        assert token in rider
    assert 'FindFirstChild("Head", true)' in rider
    assert 'Instance.new("WeldConstraint")' in rider
    for token in ["CanCollide = false", "CanTouch = false", "CanQuery = false", "Massless = true"]:
        assert token in rider
    clone = rider.split("local function cloneCharacterVisual", 1)[1].split("local function getPresentationRoot", 1)[0]
    assert "visual:ScaleTo(RIDER_SCALE)" in clone
    assert "applyCowboyPresentation(visual)" in clone


def test_cr3_cowboy_is_presentation_only_and_does_not_touch_racer_physics() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    assert "BodyCollider" in rider
    assert "AssemblyLinearVelocity" not in rider
    assert "AssemblyAngularVelocity" not in rider
    assert "ApplyImpulse" not in rider
    assert "VectorForce" not in rider
    assert "LinearVelocity" not in rider
