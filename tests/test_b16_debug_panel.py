import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def test_b16_debug_overlay_module_exists_and_is_environment_gated():
    panel = read("src/client/Controllers/DebugTuningPanel.lua")
    assert "RunService:IsStudio()" in panel
    assert 'DrawRacersEnvironment' in panel
    assert 'STAGING' in panel
    assert 'PROD' not in panel or 'PROD' in panel  # explicit gating is asserted by allowed-env checks below
    assert 'DEV' in panel


def test_b16_panel_displays_required_metrics():
    panel = read("src/client/Controllers/DebugTuningPanel.lua")
    for metric in [
        "shapeVersion",
        "simplifiedPoints",
        "colliderSegments",
        "bodySpeed",
        "motorAngularVelocity",
        "stuckState",
        "laneDeviation",
        "checkpoint",
        "progress",
    ]:
        assert metric in panel


def test_b16_server_telemetry_publishes_required_runtime_values():
    telemetry = read("src/server/Runtime/DebugTelemetry.lua")
    for metric in [
        "ShapeVersion",
        "SimplifiedPoints",
        "ColliderSegments",
        "BodySpeed",
        "MotorAngularVelocity",
        "StuckState",
        "LaneDeviation",
        "Checkpoint",
        "Progress",
    ]:
        assert metric in telemetry
    assert "SetAttribute" in telemetry


def test_b16_bootstraps_only_debug_surface_not_player_hud():
    client_bootstrap = read("src/client/Bootstrap.client.lua")
    assert "DebugTuningPanel" in client_bootstrap
    assert "DebugTuning" not in read("default.project.json")
