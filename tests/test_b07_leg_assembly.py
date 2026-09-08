from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b07_leg_assembly_contract() -> None:
    leg_path = ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua"
    assert leg_path.is_file(), "missing B07 LegAssembly.lua"
    text = leg_path.read_text(encoding="utf-8")

    for token in [
        '"LeftLeg"',
        '"LegRoot"',
        '"HubJoint"',
        '"Segments"',
        '"Visual"',
        '"RacerLeg"',
        'WeldConstraint',
        'LegCanvasHalfSpan',
        'MaxLegExtentFromHub',
        'PhysicalLegSegmentThickness',
        'InnerHubNoCollisionRadius',
        'SegmentOverlapAllowance',
        'MinimumMappedSegmentLength',
    ]:
        assert token in text, f"missing B07 implementation token: {token}"

    # B07 established the one-side assembly contract. Later B09 is allowed to
    # generalize the same component to RightLeg without invalidating B07.
    assert "CFrame.new(mapped" not in text, "B07 must not invent center-spoke translation shortcuts"


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
    assert "LegAssembly.new" in spec_text
    assert "one-leg geometry tests PASS" in spec_text

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B07LegAssemblySpec" in bootstrap
    assert "B07LegAssemblySpec.run()" in bootstrap
