from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b03_shared_modules_and_defaults_exist() -> None:
    stroke_types = ROOT / "src" / "shared" / "Types" / "StrokeTypes.lua"
    stroke_math = ROOT / "src" / "shared" / "Math" / "StrokeMath.lua"
    physics_config = ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua"
    studio_spec = ROOT / "src" / "server" / "Tests" / "B03StrokeMathSpec.lua"

    for path in [stroke_types, stroke_math, physics_config, studio_spec]:
        assert path.is_file(), f"missing B03 file: {path.relative_to(ROOT)}"

    math_text = stroke_math.read_text(encoding="utf-8")
    for token in ["function StrokeMath.Clamp", "function StrokeMath.Dedupe", "NON_FINITE_POINT", "TOO_MANY_POINTS"]:
        assert token in math_text, f"missing B03 behavior token {token}"

    # StrokeMath must stay pure/deterministic: no Instances, remotes, or player state.
    assert "Instance.new" not in math_text
    assert "game:GetService" not in math_text

    config_text = physics_config.read_text(encoding="utf-8")
    for token in [
        "RawSampleMinMovementNormalized = 0.010",
        "MaxRawPoints = 96",
        "MinimumRawPoints = 3",
        "DedupeDistance = 0.012",
        "NormalizedMin = -1",
        "NormalizedMax = 1",
    ]:
        assert token in config_text, f"B03 must start from docs/16 default: {token}"


def test_b03_studio_spec_covers_determinism_and_bad_values() -> None:
    spec = (ROOT / "src" / "server" / "Tests" / "B03StrokeMathSpec.lua").read_text(encoding="utf-8")
    for token in [
        "outOfBounds",
        "nearDuplicates",
        "math.huge",
        "nanValue",
        "TOO_MANY_POINTS",
        "NON_FINITE_POINT",
        "assertSamePoints",
        "[DrawRacers][B03] StrokeMath tests PASS",
    ]:
        assert token in spec, f"B03 Studio spec missing case {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B03StrokeMathSpec" in bootstrap
