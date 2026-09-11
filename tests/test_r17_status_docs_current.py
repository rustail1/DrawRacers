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


def test_status_docs_keep_r17_mechanics_and_camera_contract_exact() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")
    readme = read("README.md")
    merged = "\n".join([session, features, readme]).lower()

    for token in [
        "one `axlejoint`",
        "one motor",
        "structural 180",
        "full 360",
        "first cleaned point",
    ]:
        assert token in merged, f"current status docs missing R17 invariant: {token}"

    assert "phase-chasing" in merged
    assert "human studio pending" in merged
