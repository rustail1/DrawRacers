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


def test_rcp07_rider_recreation_invalidates_cosmetic_cache_by_instance_identity() -> None:
    text = read("src/client/Controllers/RacerCosmeticsController.lua")
    assert "tostring(rider)" not in text, (
        "rider cache must not key recreation by tostring(instance): rider clones reuse the same name"
    )
    assert "_riderInstances" in text, "controller must remember the exact styled rider instance per racer"
    assert "self._riderInstances[racer] == rider" in text, (
        "cache hit must require the current rider to be the same Instance that was previously styled"
    )


def test_rcp07_default_leg_skin_preserves_intrinsic_front_back_readability() -> None:
    catalog = read("src/shared/Config/CosmeticsCatalog.lua")
    leg_assembly = read("src/server/Runtime/LegAssembly.lua")
    assert "FRONT_VISUAL_COLOR" in leg_assembly and "BACK_VISUAL_COLOR" in leg_assembly, (
        "base leg presentation intentionally owns distinct front/back colors"
    )
    default_leg_block = catalog.split("LegSkins = {", 1)[1].split("CubeSkins = {", 1)[0]
    assert "Color =" not in default_leg_block, (
        "Default leg cosmetics must not erase the intrinsic front/back color distinction"
    )
    assert "Material =" not in default_leg_block, (
        "Default leg cosmetics should preserve the base leg material instead of restyling by default"
    )


def test_rcp07_switching_back_to_default_restores_intrinsic_leg_style() -> None:
    catalog = read("src/shared/Config/CosmeticsCatalog.lua")
    controller = read("src/client/Controllers/RacerCosmeticsController.lua")
    default_leg_block = catalog.split("LegSkins = {", 1)[1].split("CubeSkins = {", 1)[0]
    assert "PreserveBase = true" in default_leg_block, (
        "neutral Default needs explicit restore semantics; an empty style cannot undo a previously applied skin"
    )
    assert "_baseLegStyles" in controller, (
        "controller must remember each visual part's intrinsic appearance before cosmetic overrides"
    )
    assert "restoreBaseStyle" in controller, (
        "returning to Default must restore the intrinsic front/back appearance instead of leaving the prior skin stuck"
    )


def test_rcp07_bootstrap_starts_cosmetics_with_other_presentation_owners() -> None:
    bootstrap = read("src/client/Bootstrap.client.lua")
    assert 'WaitForChild("RacerCosmeticsController")' in bootstrap
    assert "RacerCosmeticsController.new()" in bootstrap
    start = bootstrap[bootstrap.index("local function startProductionPresentation"):]
    assert "racerCosmeticsController:Start()" in start
