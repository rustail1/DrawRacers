from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_a02_minimal_bootstrap_structure() -> None:
    expected_directories = [
        ROOT / "src" / "shared" / "Config",
        ROOT / "src" / "shared" / "Types",
    ]
    expected_files = [
        ROOT / "src" / "server" / "Bootstrap.server.lua",
        ROOT / "src" / "client" / "Bootstrap.client.lua",
    ]

    for path in expected_directories:
        assert path.is_dir(), f"missing A02 directory: {path.relative_to(ROOT)}"

    for path in expected_files:
        assert path.is_file(), f"missing A02 bootstrap file: {path.relative_to(ROOT)}"

    # A02 is deliberately minimal. Future orchestration roots arrive only when
    # their owning task needs them; empty placeholder systems are forbidden.
    forbidden_early_directories = [
        ROOT / "src" / "server" / "Services",
        ROOT / "src" / "server" / "Runtime",
        ROOT / "src" / "client" / "Controllers",
    ]
    for path in forbidden_early_directories:
        assert not path.exists(), f"future root created too early: {path.relative_to(ROOT)}"


def test_a02_rojo_mapping_still_targets_canonical_roots() -> None:
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    tree = project["tree"]

    assert tree["ReplicatedStorage"]["Shared"]["$path"] == "src/shared"
    assert tree["ServerScriptService"]["$path"] == "src/server"
    assert (
        tree["StarterPlayer"]["StarterPlayerScripts"]["$path"]
        == "src/client"
    )
