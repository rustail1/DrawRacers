from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src/shared/Config/M0SceneConfig.lua"
BUILDER = ROOT / "src/server/M0TestScene.lua"
STUDIO_SPEC = ROOT / "src/server/Tests/B15ObstacleLabSpec.lua"
BOOTSTRAP = ROOT / "src/server/Bootstrap.server.lua"


def test_b15_canonical_obstacle_defaults_are_declared():
    text = CONFIG.read_text(encoding="utf-8")

    for token in [
        'PieceId = "FlatShort"',
        'StartX = 10',
        'Length = 18',
        'PieceId = "SmallSteps"',
        'StartX = 38',
        'Height = 1.5',
        'Depth = 4.0',
        'Gap = 1.0',
        'Count = 5',
        'PieceId = "SingleWallLow"',
        'StartX = 76',
        'Height = 2.6',
        'Thickness = 2.0',
        'PieceId = "GapSmall"',
        'StartX = 106',
        'GapWidth = 3.2',
        'PieceId = "LowTunnelWide"',
        'StartX = 140',
        'Clearance = 4.25',
        'TunnelLength = 16',
    ]:
        assert token in text, f"missing B15 canonical default token: {token}"


def test_b15_builder_uses_exact_collision_recipes_without_hidden_gap_floor():
    text = BUILDER.read_text(encoding="utf-8")

    for token in [
        'ObstacleLab',
        'buildFlatShort',
        'buildSmallSteps',
        'buildSingleWallLow',
        'buildGapSmall',
        'buildLowTunnelWide',
        'CollisionGroups.Track',
        'CanCollide = true',
        'GapApproach',
        'GapLanding',
        'TunnelCeiling',
    ]:
        assert token in text, f"missing B15 obstacle builder token: {token}"

    assert '"FlatLane"' not in text, "B15 must not leave one continuous floor under the canonical gap"


def test_b15_studio_geometry_spec_is_wired():
    assert STUDIO_SPEC.is_file(), "B15 requires a Studio geometry spec"
    spec = STUDIO_SPEC.read_text(encoding="utf-8")
    bootstrap = BOOTSTRAP.read_text(encoding="utf-8")

    for token in [
        'GapApproach',
        'GapLanding',
        'TunnelCeiling',
        'Step5',
        'Wall',
        '[DrawRacers][B15] obstacle lab geometry tests PASS',
    ]:
        assert token in spec, f"missing B15 Studio assertion token: {token}"

    assert 'B15ObstacleLabSpec' in bootstrap
    assert 'B15ObstacleLabSpec.run()' in bootstrap
