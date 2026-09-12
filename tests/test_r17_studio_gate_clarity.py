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


def test_default_g0_manual_core_does_not_create_tests_running_banner() -> None:
    client = read("src/client/Bootstrap.client.lua")

    assert 'local manualCoreMode = StudioHarnessConfig.Mode == "G0"' in client
    assert 'local gateBanner: TextLabel? = if manualCoreMode then nil else createStudioGateBanner()' in client
    assert 'elseif gateBanner ~= nil then' in client
    # Explicit evidence modes may still show their diagnostic progress banner.
    assert 'string.format("%s TESTS RUNNING", StudioHarnessConfig.Mode)' in client
    assert '"G0 TESTS RUNNING"' not in client
    assert '[DrawRacers][ClientGate] G0 core startup BLOCKED' in client
