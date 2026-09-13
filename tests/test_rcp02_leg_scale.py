from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def test_rcp02_leg_reach_uses_human_repaired_reference_scale_and_split_thickness() -> None:
    config = (ROOT / "src/shared/Config/PhysicsConfig.lua").read_text(encoding="utf-8")

    # BG-02 human evidence supersedes the temporary 2x RCP-02 scale. Keep the
    # leg clearly larger than the old 3.15/4.5 baseline without letting it
    # dominate the current 3-stud body and obstacle lab.
    assert re.search(r"LegCanvasHalfSpan\s*=\s*4\.8", config)
    assert re.search(r"MaxLegExtentFromHub\s*=\s*6\.9", config)
    assert re.search(r"PhysicalLegSegmentThickness\s*=\s*0\.54", config)
    assert re.search(r"VisualLegSegmentThickness\s*=\s*0\.78", config)


def test_rcp02_leg_assembly_uses_configured_visual_thickness_without_changing_body() -> None:
    leg = (ROOT / "src/server/Runtime/LegAssembly.lua").read_text(encoding="utf-8")
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")

    assert "geometry.VisualLegSegmentThickness" in leg
    assert "geometry.PhysicalLegSegmentThickness * 0.78" not in leg
    assert "geometry.PhysicalLegSegmentThickness" in leg
    assert "local BODY_SIZE = Vector3.new(3, 3, 3)" in runtime
