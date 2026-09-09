from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b14_existing_network_guards_cover_abuse_surface() -> None:
    service = (ROOT / "src" / "server" / "Services" / "LegShapeService.lua").read_text(encoding="utf-8")

    for token in [
        '"STALE_SEQUENCE"',
        '"MALFORMED_POINTS"',
        '"NON_FINITE_POINT"',
        '"TOO_MANY_POINTS"',
        '"PAYLOAD_TOO_LARGE"',
        '"RATE_LIMITED"',
        "MaxRawPoints",
        "MaxStrokePayloadBytes",
        "StrokeSubmitCooldown",
        "lastAcceptedSequence",
        "pendingSequence",
    ]:
        assert token in service, f"missing B14 abuse guard token: {token}"

    handle = service[service.index("function processor:Handle"):service.index("return processor", service.index("function processor:Handle"))]
    assert handle.index("validateNetworkPoints") < handle.index("LegShapeService.ValidateAndBuild")
    assert handle.index("MaxStrokePayloadBytes") < handle.index("LegShapeService.ValidateAndBuild")
    assert handle.index("StrokeSubmitCooldown") < handle.index("LegShapeService.ValidateAndBuild")


def test_b14_studio_stress_spec_is_wired() -> None:
    spec_path = ROOT / "src" / "server" / "Tests" / "B14RedrawStressSpec.lua"
    assert spec_path.is_file(), "missing B14 Studio abuse/stress spec"
    spec = spec_path.read_text(encoding="utf-8")

    for token in [
        "RATE_LIMITED",
        "STALE_SEQUENCE",
        "MALFORMED_POINTS",
        "NON_FINITE_POINT",
        "TOO_MANY_POINTS",
        "PAYLOAD_TOO_LARGE",
        "valid current shape",
        "no leaked leg models",
        "countLegParts",
        "for attempt = 1, 40 do",
        "for attempt = 1, 50 do",
        "redraw abuse/stress tests PASS",
    ]:
        assert token in spec, f"missing B14 stress acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B14RedrawStressSpec" in bootstrap
    assert "B14RedrawStressSpec.run()" in bootstrap


def test_b14_expensive_invalid_payload_cases_run_outside_submit_cooldown() -> None:
    spec = (ROOT / "src" / "server" / "Tests" / "B14RedrawStressSpec.lua").read_text(encoding="utf-8")
    cooldown_advance = "now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01"

    for marker in [
        "local malformed = processor:Handle",
        "local nonFinite = processor:Handle",
        "local tooMany = processor:Handle",
        "local oversized = processor:Handle",
    ]:
        marker_index = spec.index(marker)
        prior_window = spec[max(0, marker_index - 180):marker_index]
        assert cooldown_advance in prior_window, (
            f"{marker} must advance fake server time past StrokeSubmitCooldown so the Studio spec "
            "tests that payload guard instead of correctly receiving RATE_LIMITED"
        )
