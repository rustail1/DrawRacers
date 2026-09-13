from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_bg03_drive_pivots_live_on_horizontal_cube_edges() -> None:
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert 'side == "Left" then -body.Size.X / 2 else body.Size.X / 2' in drive
    assert "bodyAttachment.Position = Vector3.new(pivotX, 0, 0)" in drive
    assert "CFrame.new(pivotX, 0, 0)" in drive
    assert "LegSocketZAbs" not in pair
    assert "socketZ" not in pair


def test_bg03_leg_geometry_has_no_hidden_mount_translation() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "root.CFrame = params.driveRoot.CFrame" in leg
    assert 'weld(params.driveRoot, root, "DriveWeld")' in leg
    assert "CFrame.new(0, 0," not in leg
    assert "socketZ" not in leg
    assert "axleRoot" not in leg
