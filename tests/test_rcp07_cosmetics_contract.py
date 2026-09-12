from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_rcp07_catalog_has_independent_default_skin_categories() -> None:
    path = ROOT / "src/shared/Config/CosmeticsCatalog.lua"
    assert path.is_file(), "RCP-07 requires CosmeticsCatalog"
    text = path.read_text(encoding="utf-8")
    for token in [
        'DefaultLegSkinId = "Default"',
        'DefaultCubeSkinId = "Default"',
        'DefaultRiderSkinId = "Default"',
        "LegSkins = {",
        "CubeSkins = {",
        "RiderSkins = {",
    ]:
        assert token in text, f"missing cosmetic catalog token: {token}"
    for forbidden in ["PhysicsConfig", "ShapeSpec", "MotorMaxTorque", "MaxLegExtentFromHub", "Friction", "Density"]:
        assert forbidden not in text, f"cosmetic catalog must not own gameplay tuning: {forbidden}"


def test_rcp07_controller_is_presentation_only() -> None:
    path = ROOT / "src/client/Controllers/RacerCosmeticsController.lua"
    assert path.is_file(), "RCP-07 requires RacerCosmeticsController"
    text = path.read_text(encoding="utf-8")
    for token in [
        'GetAttribute("LegSkinId")',
        'GetAttribute("CubeSkinId")',
        'GetAttribute("RiderSkinId")',
        "CosmeticsCatalog.LegSkins",
        "CosmeticsCatalog.CubeSkins",
        "CosmeticsCatalog.RiderSkins",
        'FindFirstChild("Visual")',
        'FindFirstChild("VisualRoot")',
        'FindFirstChild("RacePresentation")',
    ]:
        assert token in text, f"missing cosmetic controller token: {token}"

    for forbidden in [
        "PhysicsConfig",
        "ShapeSpec",
        "CustomPhysicalProperties",
        "CanCollide = true",
        "AssemblyLinearVelocity",
        "AngularVelocity",
        "MotorMaxTorque",
        "MaxLegExtentFromHub",
        "PhysicalLegSegmentThickness",
        "FireServer",
    ]:
        assert forbidden not in text, f"cosmetic controller must remain presentation-only: {forbidden}"


def test_rcp07_bootstrap_starts_cosmetics_with_other_presentation_owners() -> None:
    bootstrap = read("src/client/Bootstrap.client.lua")
    assert 'WaitForChild("RacerCosmeticsController")' in bootstrap
    assert "RacerCosmeticsController.new()" in bootstrap
    start = bootstrap[bootstrap.index("local function startProductionPresentation"):]
    assert "racerCosmeticsController:Start()" in start
