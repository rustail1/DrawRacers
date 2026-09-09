from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b07_leg_assembly_contract() -> None:
    leg_path = ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua"
    geometry_path = ROOT / "src" / "shared" / "Math" / "GeometryMath.lua"
    assert leg_path.is_file(), "missing B07 LegAssembly.lua"
    assert geometry_path.is_file(), "missing shared GeometryMath owner"
    leg = leg_path.read_text(encoding="utf-8")
    geometry = geometry_path.read_text(encoding="utf-8")

    for token in [
        '"LeftLeg"',
        '"LegRoot"',
        '"HubJoint"',
        '"Segments"',
        '"Visual"',
        '"RacerLeg"',
        'WeldConstraint',
        'PhysicalLegSegmentThickness',
        'SegmentOverlapAllowance',
        'shapeSpec.segmentPlan',
    ]:
        assert token in leg, f"missing B07 implementation token: {token}"

    for token in [
        'LegCanvasHalfSpan',
        'MaxLegExtentFromHub',
        'InnerHubNoCollisionRadius',
        'MinimumMappedSegmentLength',
        'BuildSegmentPlan',
    ]:
        assert token in geometry, f"missing B07 GeometryMath token: {token}"

    assert "CFrame.new(mapped" not in leg, "B07 must not invent center-spoke translation shortcuts"
    assert "local function mapPoint" not in leg, "LegAssembly must consume authoritative plan rather than remap stroke"


def test_b07_exact_defaults_and_studio_spec() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    for token in [
        "LegCanvasHalfSpan = 3.15",
        "MaxLegExtentFromHub = 4.5",
        "PhysicalLegSegmentThickness = 0.45",
        "InnerHubNoCollisionRadius = 0.65",
        "MinimumMappedSegmentLength = 0.08",
        "SegmentOverlapAllowance = 0.06",
        "MaxColliderSegmentsPerLeg = 14",
    ]:
        assert token in config, f"missing B07 config default: {token}"

    spec = ROOT / "src" / "server" / "Tests" / "B07LegAssemblySpec.lua"
    assert spec.is_file(), "missing B07 Studio behavior spec"
    spec_text = spec.read_text(encoding="utf-8")
    assert "GeometryMath.BuildSegmentPlan" in spec_text
    assert "LegAssembly.new" in spec_text
    assert "one-leg geometry tests PASS" in spec_text

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B07LegAssemblySpec" in bootstrap
    assert "B07LegAssemblySpec.run()" in bootstrap


def test_b07_studio_spec_distinguishes_corner_mapping_from_radial_cap() -> None:
    spec_text = (ROOT / "src" / "server" / "Tests" / "B07LegAssemblySpec.lua").read_text(encoding="utf-8")

    assert "local expectedCornerMagnitude = math.min(" in spec_text
    assert "PhysicsConfig.LegGeometry.LegCanvasHalfSpan * math.sqrt(2)" in spec_text
    assert "PhysicsConfig.LegGeometry.MaxLegExtentFromHub" in spec_text
    assert "assertClose(mapped[3].Magnitude, expectedCornerMagnitude" in spec_text
    assert "mapped[3].Magnitude <= PhysicsConfig.LegGeometry.MaxLegExtentFromHub + 1e-5" in spec_text

    assert "local hardCapGeometry = table.clone(PhysicsConfig.LegGeometry)" in spec_text
    assert "hardCapGeometry.LegCanvasHalfSpan = 4.0" in spec_text
    assert "GeometryMath.MapPoint(Vector2.new(1, 1), hardCapGeometry)" in spec_text
    assert "assertClose(hardCapped.Magnitude, hardCapGeometry.MaxLegExtentFromHub" in spec_text

    assert "assertClose(mapped[3].Magnitude, 4.5" not in spec_text
