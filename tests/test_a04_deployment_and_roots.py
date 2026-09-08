from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

DEPLOY_FILES = [
    ROOT / "config" / "deploy" / "dev.env.lua",
    ROOT / "config" / "deploy" / "staging.env.lua",
    ROOT / "config" / "deploy" / "prod.env.lua",
]

REQUIRED_ENV_KEYS = [
    "EnvironmentName",
    "UniverseId",
    "EntryFTUEPlaceId",
    "RacePlaceId",
    "PlaceModeById",
    "DataStoreNamespace",
    "AnalyticsEnvironment",
    "MonetizationEnabled",
    "BotsEnabled",
    "StarterStylePassId",
    "NeonStylePassId",
    "PremiumPresentationPassId",
    "Coins450ProductId",
    "Coins1100ProductId",
    "Coins2500ProductId",
]

ID_KEYS = [
    "UniverseId",
    "EntryFTUEPlaceId",
    "RacePlaceId",
    "StarterStylePassId",
    "NeonStylePassId",
    "PremiumPresentationPassId",
    "Coins450ProductId",
    "Coins1100ProductId",
    "Coins2500ProductId",
]


def test_a04_environment_files_exist_with_exact_keys_and_no_fake_ids() -> None:
    for path in DEPLOY_FILES:
        assert path.is_file(), f"missing A04 deployment file: {path.relative_to(ROOT)}"
        text = path.read_text(encoding="utf-8")
        for key in REQUIRED_ENV_KEYS:
            assert re.search(rf"\b{re.escape(key)}\s*=", text), f"{path.name} missing {key}"
        for key in ID_KEYS:
            match = re.search(rf"\b{re.escape(key)}\s*=\s*([^,\n]+)", text)
            assert match, f"{path.name} missing value for {key}"
            assert match.group(1).strip() == "nil", f"{path.name} must not invent {key}"


def test_a04_namespaces_and_analytics_labels_are_environment_specific() -> None:
    texts = [path.read_text(encoding="utf-8") for path in DEPLOY_FILES]
    expected = [
        ("DEV", "DrawRacers_DEV_v1"),
        ("STAGING", "DrawRacers_STAGING_v1"),
        ("PROD", "DrawRacers_PROD_v1"),
    ]
    for text, (environment, namespace) in zip(texts, expected, strict=True):
        assert f'EnvironmentName = "{environment}"' in text
        assert f'DataStoreNamespace = "{namespace}"' in text
        assert f'AnalyticsEnvironment = "{environment}"' in text


def test_a04_asset_registry_and_fail_closed_validator_exist() -> None:
    registry = ROOT / "assets" / "asset_registry.lua"
    validator = ROOT / "config" / "deploy" / "validate.lua"
    assert registry.is_file(), "missing assets/asset_registry.lua"
    assert validator.is_file(), "missing config/deploy/validate.lua"

    registry_text = registry.read_text(encoding="utf-8")
    for field in [
        "Key",
        "AssetType",
        "AssetId",
        "Owner",
        "SourcePath",
        "SourceHash",
        "LicenseOrOriginal",
        "ModerationState",
        "RuntimeUse",
        "ReleaseRequired",
    ]:
        assert field in registry_text

    validator_text = validator.read_text(encoding="utf-8")
    assert "assertResolved" in validator_text
    assert "assertKnownPlace" in validator_text
    assert "assertSkuResolved" in validator_text
    assert "error(" in validator_text


def test_a04_rojo_project_declares_canonical_static_roots() -> None:
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    tree = project["tree"]

    assert tree["ReplicatedStorage"]["Remotes"]["$className"] == "Folder"
    assert tree["ReplicatedStorage"]["Assets"]["$className"] == "Folder"
    assert tree["ServerStorage"]["RacerTemplates"]["$className"] == "Folder"
    assert tree["ServerStorage"]["TrackPieces"]["$className"] == "Folder"

    runtime = tree["Workspace"]["Runtime"]
    assert runtime["$className"] == "Folder"
    for child in ["Tracks", "Racers", "RacePresentation"]:
        assert runtime[child]["$className"] == "Folder"

    starter_gui = tree["StarterGui"]
    for gui in ["RaceHUD", "DrawHUD", "ResultsHUD", "GarageHUD", "StoreHUD", "SettingsHUD"]:
        assert starter_gui[gui]["$className"] == "ScreenGui"
        assert starter_gui[gui]["$properties"]["ResetOnSpawn"] is False, (
            f"{gui} must persist across character respawn"
        )


def test_a04_filesystem_roots_still_exist() -> None:
    expected_dirs = [
        ROOT / "src" / "shared" / "Math",
        ROOT / "src" / "shared" / "Net",
        ROOT / "src" / "server" / "Services",
        ROOT / "src" / "server" / "Runtime",
        ROOT / "src" / "server" / "Tests",
        ROOT / "src" / "client" / "Controllers",
    ]
    for path in expected_dirs:
        assert path.is_dir(), f"missing canonical A04 root: {path.relative_to(ROOT)}"

    # Later accepted tasks may legitimately populate these roots. A04 regression
    # must preserve ownership/placement, not require them to stay empty forever.
