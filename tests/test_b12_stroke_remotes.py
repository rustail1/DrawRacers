from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b12_exact_remote_tree_names_and_defaults() -> None:
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    remotes = project["tree"]["ReplicatedStorage"]["Remotes"]
    assert remotes["SubmitStroke"]["$className"] == "RemoteEvent"
    assert remotes["StrokeResult"]["$className"] == "RemoteEvent"
    assert {key for key in remotes if not key.startswith("$")} == {"SubmitStroke", "StrokeResult"}

    names_path = ROOT / "src" / "shared" / "Net" / "RemoteNames.lua"
    assert names_path.is_file(), "missing shared RemoteNames registry"
    names = names_path.read_text(encoding="utf-8")
    assert 'SubmitStroke = "SubmitStroke"' in names
    assert 'StrokeResult = "StrokeResult"' in names
    for forbidden in ["GenericRPC", "SetProperty", "SpawnThing", "RemoteFunction"]:
        assert forbidden not in names

    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    assert "StrokeSubmitCooldown = 0.20" in config
    assert "MaxStrokePayloadBytes = 4096" in config


def test_b12_authoritative_submit_processor_contract() -> None:
    service_path = ROOT / "src" / "server" / "Services" / "LegShapeService.lua"
    assert service_path.is_file(), "missing B11/B12 LegShapeService.lua"
    service = service_path.read_text(encoding="utf-8")

    for token in [
        "CreateSubmitProcessor",
        "ValidateAndBuild",
        "STALE_SEQUENCE",
        "RATE_LIMITED",
        "PAYLOAD_TOO_LARGE",
        "NO_RACER",
        "MALFORMED_POINTS",
        "NON_FINITE_POINT",
        "TOO_MANY_POINTS",
        "MaxStrokePayloadBytes",
        "StrokeSubmitCooldown",
        "lastAcceptedSequence",
        "pendingSequence",
        "HttpService:JSONEncode",
    ]:
        assert token in service, f"missing B12 submit processor token: {token}"

    for forbidden in [
        'Instance.new("Part")',
        "CFrame.new(",
        "RemoteEvent",
        "OnServerEvent",
        "FireClient",
        "RemoteFunction",
        "segmentPlan = payload",
        "shapeVersion = payload",
    ]:
        assert forbidden not in service, f"B11/B12 authority module must remain transport-independent: {forbidden}"


def test_b12_remote_binding_and_studio_spec_are_wired() -> None:
    transport_path = ROOT / "src" / "server" / "Services" / "StrokeRemoteTransport.lua"
    assert transport_path.is_file(), "missing B12 StrokeRemoteTransport.lua"
    transport = transport_path.read_text(encoding="utf-8")
    for token in [
        "LegShapeService.CreateSubmitProcessor",
        "OnServerEvent:Connect",
        "FireClient",
        'IsA("RemoteEvent")',
    ]:
        assert token in transport, f"missing B12 transport token: {token}"
    assert "RemoteFunction" not in transport

    spec_path = ROOT / "src" / "server" / "Tests" / "B12StrokeRemoteSpec.lua"
    assert spec_path.is_file(), "missing B12 Studio behavior spec"
    spec = spec_path.read_text(encoding="utf-8")
    for token in [
        "STALE_SEQUENCE",
        "RATE_LIMITED",
        "PAYLOAD_TOO_LARGE",
        "NO_RACER",
        "ShapeVersion",
        "SubmitStroke/StrokeResult tests PASS",
        'FindFirstChildWhichIsA("RemoteFunction")',
    ]:
        assert token in spec, f"missing B12 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B12StrokeRemoteSpec" in bootstrap
    assert "B12StrokeRemoteSpec.run()" in bootstrap


def test_b12_drawing_controller_request_result_semantics() -> None:
    drawing = (ROOT / "src" / "client" / "Controllers" / "DrawingController.lua").read_text(encoding="utf-8")
    for token in [
        "FireServer",
        "OnClientEvent",
        "sequence",
        "points",
        "StrokeMath.Normalize",
        "StrokeMath.Clamp",
        "StrokeMath.Dedupe",
        "StrokeMath.SimplifyRDP",
        "StrokeMath.Resample",
        "acceptedPoints",
        "_pendingStrokes",
        "_latestSubmittedSequence",
        "rejectReasonCode",
    ]:
        assert token in drawing, f"missing B12 DrawingController token: {token}"

    bootstrap = (ROOT / "src" / "client" / "Bootstrap.client.lua").read_text(encoding="utf-8")
    assert 'WaitForChild("SubmitStroke")' in bootstrap
    assert 'WaitForChild("StrokeResult")' in bootstrap
    assert "DrawingController.new(inputController, drawHud, submitStroke, strokeResult)" in bootstrap


def test_b12_no_generic_remote_surface() -> None:
    project_text = (ROOT / "default.project.json").read_text(encoding="utf-8")
    for forbidden in ["GenericRPC", "SetProperty", "SpawnThing", "RemoteFunction"]:
        assert forbidden not in project_text
