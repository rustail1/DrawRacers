from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r05_studio_harness_selector_keeps_g0_as_direct_core_default_and_r17final_available():
    config_path = ROOT / "src/shared/Config/StudioHarnessConfig.lua"
    assert config_path.is_file(), "R05 requires StudioHarnessConfig.lua"
    config = config_path.read_text(encoding="utf-8")
    assert 'Mode = "G0"' in config
    for mode in ['"NONE"', '"B08"', '"B09"', '"B10"', '"G0"', '"R17FINAL"']:
        assert mode in config

    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "StudioHarnessConfig.Mode" in bootstrap
    assert 'local runStartupRegressions = harnessMode ~= "G0"' in bootstrap
    assert 'if harnessMode == "G0" then' in bootstrap
    assert 'elseif harnessMode == "B08" then' in bootstrap
    assert 'elseif harnessMode == "B09" then' in bootstrap
    assert 'elseif harnessMode == "B10" then' in bootstrap
    assert 'elseif harnessMode == "R17FINAL" then' in bootstrap
    assert "G0 manual core mode — startup regression/evidence suite skipped" in bootstrap
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
        'WaitForChild("RemoteNames")',
        'RemoteNames.SubmitStroke',
        'RemoteNames.StrokeResult',
        'local spawn = M0SceneConfig.Spawn',
        'spawn.X',
        'PlayerAdded',
        'PlayerRemoving',
        '[DrawRacers][G0] human harness ready',
    ]:
        assert token in harness, f"missing R05 G0 harness token: {token}"

    for forbidden in ["RacerService", "RaceService", "RewardService", "RemoteFunction", "GenericRPC"]:
        assert forbidden not in harness, f"R05 must not pull later architecture into M0: {forbidden}"


def test_r05_bootstrap_keeps_b03_b16_specs_available_but_skips_them_for_default_g0():
    bootstrap = read("src/server/Bootstrap.server.lua")
    for task in range(3, 17):
        if task == 8:
            continue
        assert f"B{task:02d}" in bootstrap, f"missing existing B{task:02d} regression wiring"
    assert "StudioSpecRunner.run(testsFolder, STUDIO_REGRESSION_SPECS)" in bootstrap
    assert 'if sceneOk and runStartupRegressions then' in bootstrap
    assert "M0HumanHarness" in bootstrap
    assert "M0HumanHarness.start()" in bootstrap
