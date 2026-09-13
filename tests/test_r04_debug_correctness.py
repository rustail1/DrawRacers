from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r04_collider_count_follows_cr2_canonical_segments_only():
    telemetry = read("src/server/Runtime/DebugTelemetry.lua")
    assert 'legs:GetDescendants()' in telemetry
    assert 'descendant:IsA("BasePart")' in telemetry
    assert 'string.match(descendant.Name, "^Segment_%d+$")' in telemetry
    assert "StageTipVisual" not in telemetry
    assert "PendingSegments" not in telemetry


def test_r04_simplified_points_come_from_current_shape_spec():
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    assert 'SetAttribute("DebugSimplifiedPoints", #shapeSpec.normalizedPoints)' in runtime


def test_r04_stuck_uses_documented_horizontal_progress_window():
    config = read("src/shared/Config/PhysicsConfig.lua")
    telemetry = read("src/server/Runtime/DebugTelemetry.lua")
    assert "ProgressSampleWindow = 2.5" in config
    assert "MeaningfulHorizontalProgress = 0.35" in config
    assert "body.Position.X" in telemetry
    assert "local recovery = PhysicsConfig.Recovery" in telemetry
    assert "recovery.ProgressSampleWindow" in telemetry
    assert "recovery.MeaningfulHorizontalProgress" in telemetry
    assert "bodySpeed < 0.5" not in telemetry


def test_r04_debug_panel_prefers_explicit_target_then_human():
    panel = read("src/client/Controllers/DebugTuningPanel.lua")
    assert 'GetAttribute("DebugTarget") == true' in panel
    assert 'GetAttribute("IsBot") == false' in panel
