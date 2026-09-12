from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_current_status_docs_route_to_r17_runtime_without_promoting_human_gate() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    readme = read("README.md")

    for name, doc in [("SESSION", session), ("FEATURE_LIST", features), ("README", readme)]:
        for token in [
            "R17",
            "LegPairAssembly",
            "shared axle",
            "R17FINAL",
            "RaceCameraController",
            "RiderPresentationController",
            "HUMAN STUDIO PENDING",
        ]:
            assert token.lower() in doc.lower(), f"{name} missing current R17 status token: {token}"

    assert "APPROVED CONTRACT / IMPLEMENTATION PENDING. Current M0 runtime and gate are unchanged." not in session
    assert "These are **BACKLOG / sequence-gated**, not current M0 work." not in features
    assert "does not authorize early `RaceCameraController`/rider runtime" not in features

    # R17 did not pass any live solver/camera/rider/product gate merely by landing source changes.
    for doc in [session, features, readme]:
        assert "HUMAN REVIEW PASS" not in doc
        assert "B17/G0 — HUMAN_GATE PASS" not in doc


def test_status_docs_keep_current_r17_mechanics_and_camera_contract_exact() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    readme = read("README.md")

    current_sections = [
        session.split("## R17 CURRENT OVERRIDE", 1)[1].split("## Product state", 1)[0].lower(),
        features.split("## Current milestone / canonical override", 1)[1].split("## Bootstrap", 1)[0].lower(),
        readme.split("## Current state", 1)[1].split("## CORE / pre-G0 integrity repair", 1)[0].lower(),
    ]

    for section in current_sections:
        for token in [
            "one `axlejoint`",
            "one motor",
            "co-phase",
            "full 360",
            "first cleaned point",
        ]:
            assert token in section, f"current status section missing R17 invariant: {token}"
        assert "structural 180" not in section, "current R17 status must not claim obsolete 180-degree side offset"
        assert "phase-chasing" in section
        assert "human studio pending" in section


def test_latest_decision_makes_g0_the_fast_manual_studio_default_without_deleting_r17final() -> None:
    decision = read("docs/DECISION_LOG_STUDIO_CORE_ITERATION_DEFAULT_2026-09-12.md")
    config = read("src/shared/Config/StudioHarnessConfig.lua")
    server = read("src/server/Bootstrap.server.lua")
    client = read("src/client/Bootstrap.client.lua")

    for token in [
        "normal Roblox Studio `Play`",
        "G0",
        "B03–B16 Studio regression specs are **not** auto-run at startup",
        "R17FINAL",
        "remain selectable",
        "GitHub `Contract Verify`",
    ]:
        assert token in decision, f"Studio core-iteration decision missing token: {token}"

    assert 'Mode = "G0"' in config
    assert 'local runStartupRegressions = harnessMode ~= "G0"' in server
    assert 'local manualCoreMode = StudioHarnessConfig.Mode == "G0"' in client
    assert "HUMAN_GATE result" in decision


def test_status_docs_record_reference_feel_autodev_without_fabricating_tuning_winner() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    readme = read("README.md")
    merged = "\n".join([session, features, readme]).lower()

    for token in [
        "stable two-axis dead-zone",
        "collision-safe redraw phase",
        "body density",
        "leg density",
        "motor speed",
        "body friction",
        "production tuning remains unchanged",
        "r17.7",
        "r17final",
    ]:
        assert token in merged, f"status docs missing reference-feel autodev token: {token}"

    assert "human body feel choice pending" in merged
    assert "human review pass" not in merged


def test_navigation_docs_route_to_current_r17_owners_while_latest_decision_owns_studio_default() -> None:
    architecture = read("docs/ARCHITECTURE_MAP.md")
    handoff = read("docs/26_HANDOFF_MAP.md")
    decision = read("docs/DECISION_LOG_STUDIO_CORE_ITERATION_DEFAULT_2026-09-12.md")

    studio_row = next(line for line in architecture.splitlines() if "| Studio harness selection |" in line)
    assert "StudioHarnessConfig.lua" in studio_row
    assert "R17FINAL" in studio_row

    hinge_row = next(line for line in handoff.splitlines() if line.startswith("| Hinge locomotion |"))
    assert "LegPairAssembly" in hinge_row
    assert "LegAssembly/RacerRuntime" not in hinge_row

    stabilization_row = next(line for line in handoff.splitlines() if line.startswith("| Stabilization/lane |"))
    assert "RacerStabilizer" in stabilization_row

    sequencing_note = next(line for line in handoff.splitlines() if line.startswith("Camera/rider sequencing note:"))
    assert "R17 Product Owner overrides" in sequencing_note
    assert "current M0 owners" in sequencing_note
    assert "D09/E03 remain later" in sequencing_note
    assert "not an authorization to create" not in sequencing_note

    assert "committed default Studio harness returns to `G0`" in decision
