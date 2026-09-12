from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _function_body(source: str, signature: str) -> str:
    start = source.index(signature)
    tail = source[start:]
    marker = "\nend\n\nfunction "
    end = tail.find(marker)
    return tail if end < 0 else tail[: end + len("\nend")]


def test_rcp01_redraw_reuses_existing_axle_and_joint() -> None:
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")

    apply_body = _function_body(runtime, "function RacerRuntime:_ApplyShapeSpec")

    assert "BeginGeometryReshape" in pair, "RCP-04 must preserve RCP-01 stable axle while reshaping geometry"
    assert "self.legPair:BeginGeometryReshape" in apply_body, "redraw must reuse the existing leg pair"
    assert "LegPairAssembly.new" not in apply_body, "redraw must not allocate a replacement axle/joint"


def test_rcp01_replace_geometry_is_failure_atomic() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    body = _function_body(pair, "function LegPairAssembly:BeginGeometryReshape")

    assert "stagedLeft" in body and "stagedRight" in body
    assert "pcall" in body, "replacement geometry must be prepared behind an error boundary"
    assert body.index("stagedLeft:Commit()") < body.index("oldLeft:Destroy()")
    assert body.index("stagedRight:Commit()") < body.index("oldRight:Destroy()")


def test_rcp01_stable_motor_remains_single_owner() -> None:
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src/server/Runtime/LegAssembly.lua").read_text(encoding="utf-8")

    assert pair.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in leg
    reshape_body = _function_body(pair, "function LegPairAssembly:BeginGeometryReshape")
    helper_body = pair[pair.index("local function buildStagedSides"):pair.index("function LegPairAssembly:ReplaceGeometry")]
    assert 'Instance.new("HingeConstraint")' not in reshape_body
    assert 'Instance.new("HingeConstraint")' not in helper_body
    assert "buildStagedSides(self, shapeSpec)" in reshape_body
    assert "axleRoot = self.axleRoot" in helper_body
