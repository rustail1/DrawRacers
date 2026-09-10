from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b04_stroke_math_contract() -> None:
    stroke_math = (ROOT / "src" / "shared" / "Math" / "StrokeMath.lua").read_text(encoding="utf-8")
    physics_config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")

    for token in [
        "function StrokeMath.Normalize",
        "function StrokeMath.ClampToRect",
        "function StrokeMath.AnchorToFirstPoint",
        "function StrokeMath.SimplifyRDP",
        "function StrokeMath.Resample",
        "function StrokeMath.MeasureLength",
    ]:
        assert token in stroke_math, f"missing B04 function: {token}"

    # R16.3B: pixel mapping is isotropic and owned by DrawInputRect height.
    normalize_body = stroke_math.split("function StrokeMath.Normalize", 1)[1].split(
        "function StrokeMath.MeasureLength", 1
    )[0]
    assert "local unit = canvasSize.Y * 0.5" in normalize_body
    assert "point.X - center.X" in normalize_body
    assert "center.Y - point.Y" in normalize_body
    assert "ComputeBounds" not in normalize_body

    for token in [
        "RawSemanticHalfWidth = 1.75",
        "RawSemanticHalfHeight = 1.0",
        "RDPEpsilon = 0.022",
        "ResampleTargetPoints = 12",
        "MaxCleanedPoints = 15",
        "MinimumCleanedPolylineLength = 0.18",
    ]:
        assert token in physics_config, f"missing B04 config default: {token}"


def test_b04_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B04StrokeMathSpec.lua"
    assert spec.is_file(), "missing B04 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")
    assert "StrokeMath.Normalize" in text
    assert "StrokeMath.AnchorToFirstPoint" in text
    assert "StrokeMath.SimplifyRDP" in text
    assert "StrokeMath.Resample" in text
    assert "useful V shape collapsed" in text

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B04StrokeMathSpec" in bootstrap
    assert "B04StrokeMathSpec.run()" in bootstrap
