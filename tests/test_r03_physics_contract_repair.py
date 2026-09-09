from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r03_collision_matrix_includes_decoration_and_trigger():
    collision = read("src/server/Runtime/CollisionGroups.lua")
    assert 'Decoration = "Decoration"' in collision
    assert 'Trigger = "Trigger"' in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.Track, CollisionGroups.Decoration, false)" in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Trigger, false)" in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Trigger, false)" in collision


def test_r14_4_default_group_cannot_push_racer_geometry():
    collision = read("src/server/Runtime/CollisionGroups.lua")
    assert 'Default = "Default"' in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Default, false)" in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Default, false)" in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Track, true)" in collision
    assert "CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Track, true)" in collision


def test_r03_stabilizer_has_free_tilt_deadzone_without_forward_force():
    config = read("src/shared/Config/PhysicsConfig.lua")
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert "OrientationFreeTiltDegrees = 25" in config
    assert "OrientationFreeTiltDegrees" in stabilizer
    assert "orientationAlign.Enabled = orientationErrorDegrees > config.OrientationFreeTiltDegrees" in stabilizer
    assert "MaxAxesForce = Vector3.new(0, 0, config.LaneMaxForceZ)" in stabilizer


def test_r03_m0_lab_lives_under_runtime_tracks_and_tunnel_uses_top_y():
    scene = read("src/server/M0TestScene.lua")
    assert 'WaitForChild("Runtime"):WaitForChild("Tracks")' in scene
    assert "scene.Parent = tracksRoot" in scene
    assert "workspace:FindFirstChild(config.SceneName)" not in scene
    assert "config.Lane.TopY + clearance + ceilingThickness / 2" in scene
