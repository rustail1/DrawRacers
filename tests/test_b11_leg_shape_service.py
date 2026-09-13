from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_b11_authoritative_fixed_pivot_shape_service_contract() -> None:
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    service = read("src/server/Services/LegShapeService.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "CanonicalLegShape.Build" in service
    assert "PivotStartRadiusNormalized" in config
    assert "START_OFF_PIVOT" in builder
    assert "AnchorToFirstPoint" not in builder
    assert "presentationAnchor" not in builder
    assert "canonical.normalizedPoints" in service
    assert "canonical.segmentPlan" in service
    assert "racerRuntime:ApplyValidatedShape(shapeSpec, motorEnabled)" in service
    assert "applyResult.accepted" in service
    assert "applyResult.rejectReasonCode" in service


def test_b11_shape_version_and_result_publish_after_mechanical_accept() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    service = read("src/server/Services/LegShapeService.lua")
    validated = runtime.split("function RacerRuntime:ApplyValidatedShape", 1)[1].split("function RacerRuntime:IsDestroyed", 1)[0]
    assert validated.index("self:_ApplyShapeSpec(shapeSpec, motorEnabled)") < validated.index("publishValidatedShapeState(self, shapeSpec)")
    assert "shapeVersion = nextVersion" in service
    assert "acceptedPoints = serializeSemanticPoints(shapeSpec.normalizedPoints)" in service


def test_b11_studio_spec_is_wired() -> None:
    assert (ROOT / "src/server/Tests/B11LegShapeServiceSpec.lua").is_file()
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "B11LegShapeServiceSpec" in bootstrap
    assert "B11LegShapeServiceSpec.run()" in bootstrap
