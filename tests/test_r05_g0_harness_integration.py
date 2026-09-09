from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r05_studio_harness_selector_defaults_to_g0_and_only_dispatches_one():
    config_path = ROOT / "src/shared/Config/StudioHarnessConfig.lua"
    assert config_path.is_file(), "R05 requires StudioHarnessConfig.lua"
    config = config_path.read_text(encoding="utf-8")
    assert 'Mode = "G0"' in config
    for mode in ['"NONE"', '"B08"', '"B09"', '"B10"', '"G0"']:
        assert mode in config

    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "StudioHarnessConfig.Mode" in bootstrap
    assert 'if harnessMode == "G0" then' in bootstrap
    assert 'elseif harnessMode == "B08" then' in bootstrap
    assert 'elseif harnessMode == "B09" then' in bootstrap
    assert 'elseif harnessMode == "B10" then' in bootstrap
    assert "B08OneHingeMotorHarness.start()\n\n\tlocal B09TwoLegPhaseHarness" not in bootstrap


def test_r05_g0_harness_uses_existing_transport_with_studio_only_player_mapping():
    harness_path = ROOT / "src/server/Tests/M0HumanHarness.lua"
    assert harness_path.is_file(), "R05 requires M0HumanHarness.lua"
    harness = harness_path.read_text(encoding="utf-8")
    for token in [
        'game:GetService("Players")',
        'game:GetService("RunService")',
        'RunService:IsStudio()',
        'StrokeRemoteTransport.Bind',
        'resolveRacer = function(player)',
        'SetAttribute("DebugTarget", true)',
        'WaitForChild("SubmitStroke")',
        'WaitForChild("StrokeResult")',
        'M0SceneConfig.Spawn.X',
        'PlayerAdded',
        'PlayerRemoving',
        '[DrawRacers][G0] human harness ready',
    ]:
        assert token in harness, f"missing R05 G0 harness token: {token}"

    for forbidden in ["RacerService", "RaceService", "RewardService", "RemoteFunction", "GenericRPC"]:
        assert forbidden not in harness, f"R05 must not pull later architecture into M0: {forbidden}"


def test_r05_bootstrap_keeps_b03_b16_specs_and_selects_g0_harness():
    bootstrap = read("src/server/Bootstrap.server.lua")
    for task in range(3, 17):
        if task == 8:
            continue
        assert f"B{task:02d}" in bootstrap, f"missing existing B{task:02d} regression wiring"
    assert "M0HumanHarness" in bootstrap
    assert "M0HumanHarness.start()" in bootstrap
