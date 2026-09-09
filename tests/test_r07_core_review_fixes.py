from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r07_b12_validates_exact_outer_payload_and_rate_limits_before_heavy_point_work() -> None:
    service = read("src/server/Services/LegShapeService.lua")
    studio_spec = read("src/server/Tests/B12StrokeRemoteSpec.lua")

    assert "validateNetworkEnvelope" in service
    assert '"MALFORMED_PAYLOAD"' in service
    assert "unexpectedField" in studio_spec
    assert "MALFORMED_PAYLOAD" in studio_spec

    # Cheap sequence/envelope/stale checks may happen first, but expensive point walking/JSON
    # must not be repeatable at arbitrary frequency by an abusive client.
    rate_stamp = service.index("state.lastRequestAt = now")
    point_validation = service.index("validateNetworkPoints(payload.points)")
    assert rate_stamp < point_validation


def test_r07_b16_reports_raw_physics_point_counts_and_actual_motor_state() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    telemetry = read("src/server/Runtime/DebugTelemetry.lua")
    panel = read("src/client/Controllers/DebugTuningPanel.lua")
    studio_spec = read("src/server/Tests/B16DebugTuningSpec.lua")

    for token in ["DebugRawPoints", "DebugPhysicsPoints"]:
        assert token in runtime
        assert token in telemetry
        assert token in panel
        assert token in studio_spec

    assert "DebugMotorEnabled" in telemetry
    assert "DebugMotorEnabled" in panel
    assert "DebugMotorEnabled" in studio_spec
    assert "HubJoint" in telemetry


def test_r07_runtime_debug_folder_uses_dev_staging_environment_gate_not_studio_only() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    assert 'game:GetAttribute("DrawRacersEnvironment")' in runtime
    assert 'environment == "DEV" or environment == "STAGING"' in runtime


def test_r07_square_semantic_draw_surface_is_visible_and_owner_docs_match_decision() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    layout = read("docs/59_UI_LAYOUT_WIREFRAME_SPEC.md")
    hierarchy = read("docs/68_UI_COMPONENT_HIERARCHY_IMPLEMENTATION_SPEC.md")

    assert "SemanticSquareConstraint" in drawing
    assert "DrawInputSurfaceStroke" in drawing
    assert "square semantic DrawInputRect" in layout
    assert "square semantic DrawInputRect" in hierarchy
    assert "92% width × 82% height" not in layout


def test_r07_decision_log_uses_only_canonical_collision_groups() -> None:
    decision = read("docs/DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md")
    assert "RacerGhostVisual" not in decision
