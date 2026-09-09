from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_3_ready_is_published_only_after_selected_harness_starts_safely() -> None:
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "local function startSelectedHarness" in bootstrap
    assert "local harnessOk, harnessError = xpcall(startSelectedHarness, debug.traceback)" in bootstrap
    assert "if specsPassed and harnessOk then" in bootstrap

    harness_start = bootstrap.index("local harnessOk, harnessError = xpcall(startSelectedHarness, debug.traceback)")
    ready_publish = bootstrap.index('SetAttribute(STUDIO_GATE_ATTRIBUTE, "READY")')
    assert harness_start < ready_publish, "READY must not be visible before the selected harness starts successfully"


def test_r14_4_studio_spec_reads_live_collision_matrix_for_default_and_track() -> None:
    studio_spec = read("src/server/Tests/B10StabilizationSpec.lua")
    assert 'game:GetService("PhysicsService")' in studio_spec
    assert "CollisionGroupsAreCollidable" in studio_spec
    assert 'CollisionGroupsAreCollidable("Default", "RacerBody") == false' in studio_spec
    assert 'CollisionGroupsAreCollidable("Default", "RacerLeg") == false' in studio_spec
    assert 'CollisionGroupsAreCollidable("Track", "RacerBody") == true' in studio_spec
    assert 'CollisionGroupsAreCollidable("Track", "RacerLeg") == true' in studio_spec
