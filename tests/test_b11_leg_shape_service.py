from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b11_authoritative_leg_shape_service_contract() -> None:
    service_path = ROOT / "src" / "server" / "Services" / "LegShapeService.lua"
    builder_path = ROOT / "src" / "shared" / "Math" / "LegShapeMath.lua"
    assert service_path.is_file(), "missing B11 LegShapeService.lua"
    assert builder_path.is_file(), "missing shared canonical LegShapeMath owner"
    text = service_path.read_text(encoding="utf-8")
    builder = builder_path.read_text(encoding="utf-8")

    for token in [
        "function LegShapeService.ValidateAndBuild",
        'WaitForChild("LegShapeMath")',
        "LegShapeMath.BuildCanonical",
        "MinimumRawPoints",
        "MaxRawPoints",
        'typeof(point) ~= "Vector2"',
        "ApplyValidatedShape",
        "ShapeVersion",
        "normalizedPoints",
        "segmentPlan",
        "debugId",
    ]:
        assert token in text, f"missing B11 authority token: {token}"

    for token in [
        "StrokeMath.ClampToRect",
        "StrokeMath.Dedupe",
        "StrokeMath.SimplifyRDP",
        "StrokeMath.Resample",
        "StrokeMath.MeasureLength",
        "StrokeMath.ComputeBounds",
        "MinimumCleanedPolylineLength",
        "GeometryMath.BuildSegmentPlan",
    ]:
        assert token in builder, f"missing B11 canonical math token: {token}"

    for forbidden in [
        'Instance.new(',
        'RemoteEvent',
        'OnServerEvent',
        'CFrame.new(',
        'workspace.',
        'Workspace',
    ]:
        assert forbidden not in text, f"B11 service must not accept/create client world geometry directly: {forbidden}"
        assert forbidden not in builder, f"B11 canonical builder must stay pure: {forbidden}"


def test_b11_shape_types_and_runtime_commit_contract() -> None:
    types = (ROOT / "src" / "shared" / "Types" / "StrokeTypes.lua").read_text(encoding="utf-8")
    for token in [
        "export type ShapeBounds",
        "export type ShapeSegmentPlanEntry",
        "export type ShapeSpec",
        "export type LegShapeResult",
        "version: number",
        "normalizedPoints: { Vector2 }",
        "bounds: ShapeBounds",
        "extent: number",
        "segmentPlan: { ShapeSegmentPlanEntry }",
        "debugId: string",
    ]:
        assert token in types, f"missing B11 ShapeSpec type token: {token}"

    runtime = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")
    for token in [
        "currentShapeSpec = nil",
        "function RacerRuntime:ApplyValidatedShape",
        "function RacerRuntime:GetShapeVersion",
        "function RacerRuntime:GetCurrentShapeSpec",
        'SetAttribute("ShapeVersion", shapeSpec.version)',
        "self.currentShapeSpec = shapeSpec",
    ]:
        assert token in runtime, f"missing B11 RacerRuntime commit token: {token}"


def test_b11_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B11LegShapeServiceSpec.lua"
    assert spec.is_file(), "missing B11 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")

    for token in [
        "LegShapeService.ValidateAndBuild",
        "ShapeVersion",
        "TOO_SHORT",
        "NON_FINITE_POINT",
        "MALFORMED_POINTS",
        "authoritative LegShapeService tests PASS",
    ]:
        assert token in text, f"missing B11 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B11LegShapeServiceSpec" in bootstrap
    assert "B11LegShapeServiceSpec.run()" in bootstrap
