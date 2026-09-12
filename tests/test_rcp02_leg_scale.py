from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def test_rcp02_leg_reach_is_approximately_doubled_and_thickness_is_split() -> None:
    config = (ROOT / "src/shared/Config/PhysicsConfig.lua").read_text(encoding="utf-8")

    assert re.search(r"LegCanvasHalfSpan\s*=\s*6\.3", config)
    assert re.search(r"MaxLegExtentFromHub\s*=\s*9\.0", config)
    assert re.search(r"PhysicalLegSegmentThickness\s*=\s*0\.6[0-5]", config)
    assert re.search(r"VisualLegSegmentThickness\s*=\s*0\.9", config)


def test_rcp02_leg_assembly_uses_configured_visual_thickness_without_changing_body() -> None:
    leg = (ROOT / "src/server/Runtime/LegAssembly.lua").read_text(encoding="utf-8")
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")

    assert "geometry.VisualLegSegmentThickness" in leg
    assert "geometry.PhysicalLegSegmentThickness * 0.78" not in leg
    assert "geometry.PhysicalLegSegmentThickness" in leg
    assert "local BODY_SIZE = Vector3.new(3, 3, 3)" in runtime
