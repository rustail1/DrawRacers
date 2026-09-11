from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_studio_gate_reports_server_and_client_readiness_separately() -> None:
    server = read("src/server/Bootstrap.server.lua")
    client = read("src/client/Bootstrap.client.lua")

    # The replicated READY attribute remains the server-side prerequisite used by
    # the client, but console evidence must not imply the client also booted.
    assert 'ReplicatedStorage:SetAttribute(STUDIO_GATE_ATTRIBUTE, "READY")' in server
    assert '[DrawRacers][StudioGate] SERVER READY' in server
    assert 'print("[DrawRacers][StudioGate] READY")' not in server

    # A successful client composition emits its own explicit evidence line. If a
    # required controller has a syntax/load error, this line is absent and Studio
    # already shows the actual client exception.
    assert '[DrawRacers][ClientGate] READY' in client
    assert client.index('[DrawRacers][ClientGate] READY') < client.index('[DrawRacers] client bootstrap ready')


def test_studio_gate_banner_names_the_selected_harness_instead_of_legacy_g0() -> None:
    client = read("src/client/Bootstrap.client.lua")

    assert 'StudioHarnessConfig.Mode' in client
    assert 'string.format("%s BLOCKED — SERVER TEST FAILED", StudioHarnessConfig.Mode)' in client
    assert 'string.format("%s TESTS RUNNING", StudioHarnessConfig.Mode)' in client
    assert '"G0 BLOCKED — SERVER TEST FAILED"' not in client
    assert '"G0 TESTS RUNNING"' not in client
