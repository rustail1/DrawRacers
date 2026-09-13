from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_rcp02_leg_reach_uses_cr2_bounded_scale_and_split_thickness() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "LegCanvasHalfSpan = 3.2" in config
    assert "MaxLegExtentFromHub = 4.5" in config
    assert "PhysicalLegSegmentThickness = 0.54" in config
    assert "VisualLegSegmentThickness = 0.78" in config
    assert "LegCanvasHalfSpan = 4.8" not in config
    assert "MaxLegExtentFromHub = 6.9" not in config


def test_rcp02_leg_assembly_uses_configured_visual_and_physical_thickness() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "geometry.PhysicalLegSegmentThickness" in leg
    assert "geometry.VisualLegSegmentThickness" in leg
    assert "BodyCollider" not in leg
