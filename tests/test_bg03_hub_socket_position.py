from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_bg03_drive_pivots_use_explicit_lower_body_mounts() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "LegMountHorizontalFraction = 0.78" in config
    assert "LegMountVerticalFraction = -0.72" in config
    assert '"LeftLegMount"' in pair
    assert '"RightLegMount"' in pair
    assert "mountY" in pair
    assert "bodyMount: Attachment" in drive
    assert "params.bodyMount" in drive
    assert "body.Size.X / 2" not in drive
    assert "pivotX" not in drive
    assert "LegSocketZAbs" not in pair
    assert "socketZ" not in pair


def test_bg03_leg_geometry_has_no_hidden_mount_translation() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "root.CFrame = params.driveRoot.CFrame" in leg
    assert 'weld(params.driveRoot, root, "DriveWeld")' in leg
    assert "CFrame.new(0, 0," not in leg
    assert "socketZ" not in leg
    assert "axleRoot" not in leg
