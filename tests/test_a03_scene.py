from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src/shared/Config/M0SceneConfig.lua"
BUILDER = ROOT / "src/server/M0TestScene.lua"
BOOTSTRAP = ROOT / "src/server/Bootstrap.server.lua"


def test_a03_scene_contract_files_and_constants_exist():
    assert CONFIG.is_file(), "A03 requires M0SceneConfig.lua"
    assert BUILDER.is_file(), "A03 requires M0TestScene.lua"

    text = CONFIG.read_text(encoding="utf-8")
    for token in [
        'SceneName = "M0TestScene"',
        'Length = 180',
        'Width = 8',
        'TopY = 0',
        'X = 4',
        'Y = 3',
        'FlatAnchor',
        'StepsAnchor',
        'WallAnchor',
        'GapAnchor',
        'TunnelAnchor',
        'PieceId = "FlatShort"',
        'PieceId = "SmallSteps"',
        'PieceId = "SingleWallLow"',
        'PieceId = "GapSmall"',
        'PieceId = "LowTunnelWide"',
    ]:
        assert token in text, f"missing A03 contract token: {token}"


def test_a03_bootstrap_invokes_studio_scene_builder():
    text = BOOTSTRAP.read_text(encoding="utf-8")
    assert 'RunService:IsStudio()' in text
    assert 'require(script.Parent.M0TestScene)' in text
    assert '.build()' in text


def test_a03_builder_creates_reproducible_non_colliding_markers():
    text = BUILDER.read_text(encoding="utf-8")
    for token in [
        'WaitForChild("Runtime"):WaitForChild("Tracks")',
        'tracksRoot:FindFirstChild(config.SceneName)',
        ':Destroy()',
        'Instance.new("Folder")',
        'Instance.new("Part")',
        'Instance.new("SpawnLocation")',
        'CanCollide = false',
        'Anchored = true',
        'ObstacleAnchors',
    ]:
        assert token in text, f"missing reproducibility/safety token: {token}"
