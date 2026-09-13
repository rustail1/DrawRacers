from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_rcp06_rider_keeps_safe_accessories_and_remains_physics_neutral() -> None:
    rider = (ROOT / "src/client/Controllers/RiderPresentationController.lua").read_text(encoding="utf-8")

    sanitize = rider[rider.index("local function sanitizeVisual"):rider.index("local function findSeatPart")]
    assert 'descendant:IsA("Accessory")' not in sanitize, "safe cosmetic accessories must survive rider sanitization"
    for dangerous in ['descendant:IsA("Tool")', 'descendant:IsA("Script")', 'descendant:IsA("LocalScript")', 'descendant:IsA("ModuleScript")']:
        assert dangerous in sanitize
    for neutral in [
        "descendant.CanCollide = false",
        "descendant.CanTouch = false",
        "descendant.CanQuery = false",
        "descendant.Massless = true",
    ]:
        assert neutral in sanitize


def test_rcp06_sanitize_preserves_cloned_visual_transparency() -> None:
    rider = (ROOT / "src/client/Controllers/RiderPresentationController.lua").read_text(encoding="utf-8")

    sanitize = rider[rider.index("local function sanitizeVisual"):rider.index("local function findSeatPart")]
    assert 'if descendant.Name == "HumanoidRootPart" then' in sanitize
    assert "descendant.Transparency = 1" in sanitize
    assert "descendant.Transparency = 0" not in sanitize, (
        "safe cloned body/accessory transparency is part of avatar presentation and must not be flattened to opaque"
    )


def test_rcp06_pose_has_explicit_riding_joint_contract_and_seat_alignment() -> None:
    rider = (ROOT / "src/client/Controllers/RiderPresentationController.lua").read_text(encoding="utf-8")
    for token in [
        "applyJockeyPose",
        'string.find(name, "rightshoulder"',
        'string.find(name, "leftshoulder"',
        'string.find(name, "righthip"',
        'string.find(name, "lefthip"',
        'name == "waist"',
        "RIDER_MOUNT_X_OFFSET",
        "RIDER_SEAT_CLEARANCE",
        "localSeat:Inverse()",
    ]:
        assert token in rider, f"missing rider pose token: {token}"
