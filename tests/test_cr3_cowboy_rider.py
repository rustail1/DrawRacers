from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cr3_rider_preserves_loaded_avatar_without_invented_cosmetics() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    assert "RIDER_PRESENTATION_SCALE = 1.0" in rider
    for token in ["applyCowboyPresentation", "CowboyHatBrim", "CowboyHatCrown", "CowboyHatBand"]:
        assert token not in rider
    for token in ["CanCollide = false", "CanTouch = false", "CanQuery = false", "Massless = true"]:
        assert token in rider
    clone = rider.split("local function cloneCharacterVisual", 1)[1].split("local function getPresentationRoot", 1)[0]
    assert "character:Clone()" in clone
    assert "visual:ScaleTo(RIDER_PRESENTATION_SCALE)" in clone
    assert "applyJockeyPose(visual)" in clone
    sanitize = rider.split("local function sanitizeVisual", 1)[1].split("local function findSeatPart", 1)[0]
    assert 'descendant:IsA("Accessory")' not in sanitize


def test_cr3_rider_is_presentation_only_and_does_not_touch_racer_physics() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    assert "BodyCollider" in rider
    assert "AssemblyLinearVelocity" not in rider
    assert "AssemblyAngularVelocity" not in rider
    assert "ApplyImpulse" not in rider
    assert "VectorForce" not in rider
    assert "LinearVelocity" not in rider
