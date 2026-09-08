from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b05_studio_matrix_exists_and_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B05StrokeMathMatrixSpec.lua"
    assert spec.is_file(), "missing B05 Studio stroke-math matrix"

    text = spec.read_text(encoding="utf-8")
    for token in [
        "ROUND_01",
        "LONG_BAR_01",
        "SMALL_ROUND_01",
        "HOOK_01",
        "ASYM_01",
        "SUBOPTIMAL_01",
        "tiny stroke",
        "duplicate-heavy",
        "self-cross",
        "MaxRawPoints",
        "NON_FINITE_POINT",
        "TOO_MANY_POINTS",
        "StrokeMath.Clamp",
        "StrokeMath.Dedupe",
        "StrokeMath.SimplifyRDP",
        "StrokeMath.Resample",
        "StrokeMath.MeasureLength",
    ]:
        assert token in text, f"B05 matrix missing case/operation: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B05StrokeMathMatrixSpec" in bootstrap
    assert "B05StrokeMathMatrixSpec.run()" in bootstrap


def test_b05_does_not_add_world_or_network_authority() -> None:
    spec = (ROOT / "src" / "server" / "Tests" / "B05StrokeMathMatrixSpec.lua").read_text(encoding="utf-8")
    for forbidden in ["RemoteEvent", "FireServer", "FireClient", "Workspace", "Instance.new"]:
        assert forbidden not in spec, f"B05 math matrix must stay pure/test-only: found {forbidden}"
