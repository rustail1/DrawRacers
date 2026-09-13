from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def read(p): return (ROOT / p).read_text(encoding="utf-8")

def test_b07_leg_assembly_contract():
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "driveRoot" in leg
    assert 'Instance.new("HingeConstraint")' not in leg
    assert '"DriveWeld"' in leg
    for token in ["InstallGeometry", "StageGeometry", "CommitStagedGeometry", "CancelStagedGeometry"]:
        assert f"function LegAssembly:{token}" in leg
    assert "ReshapeTipCollider" not in leg

def test_b07_exact_defaults_and_studio_spec():
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "LegCanvasHalfSpan = 3.2" in config
    assert "MaxLegExtentFromHub = 4.5" in config
    assert "PhysicalLegSegmentThickness = 0.54" in config
    assert "VisualLegSegmentThickness = 0.78" in config
    assert (ROOT / "src/server/Tests/B07LegAssemblySpec.lua").is_file()

def test_b07_destroy_does_not_mutate_borrowed_shape_spec_tables():
    leg = read("src/server/Runtime/LegAssembly.lua")
    destroy = leg.split("function LegAssembly:Destroy", 1)[1]
    assert "shapeSpec" not in destroy
