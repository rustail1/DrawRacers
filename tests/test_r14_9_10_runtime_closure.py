from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_9_ci_still_runs_contracts_then_pinned_rojo_build() -> None:
    workflow = read(".github/workflows/contract-verify.yml")
    rokit = read("rokit.toml")

    assert "python verify.py" in workflow
    assert "paradoxum-games/setup-rokit@v3" in workflow
    assert "rokit install --no-trust-check" in workflow
    assert "rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx" in workflow
    assert workflow.index("python verify.py") < workflow.index("rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx")
    assert 'rojo = "rojo-rbx/rojo@7.7.0"' in rokit


def test_r14_10_runtime_modules_consume_shared_stroke_types() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    service = read("src/server/Services/LegShapeService.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    assembly = read("src/server/Runtime/LegAssembly.lua")
    transport = read("src/server/Services/StrokeRemoteTransport.lua")

    for source in [drawing, service, runtime, assembly, transport]:
        assert 'WaitForChild("Types"):WaitForChild("StrokeTypes")' in source

    assert "type SemanticPoint = StrokeTypes.SemanticPoint" in drawing
    assert "type SubmitStrokePayload = StrokeTypes.SubmitStrokePayload" in drawing
    assert "local payload: SubmitStrokePayload" in drawing

    assert "type ShapeSpec = StrokeTypes.ShapeSpec" in service
    assert "type LegShapeResult = StrokeTypes.LegShapeResult" in service
    assert "local shapeSpec: ShapeSpec" in service

    assert "type ShapeSpec = StrokeTypes.ShapeSpec" in runtime
    assert "shapeSpec: ShapeSpec" in runtime
    assert "currentShapeSpec = nil :: ShapeSpec?" in runtime

    assert "type ShapeSpec = StrokeTypes.ShapeSpec" in assembly
    assert "shapeSpec: ShapeSpec" in assembly

    assert "type StrokeResultPayload = StrokeTypes.StrokeResultPayload" in transport
    assert "): StrokeResultPayload?" in transport


def test_r14_10_studio_remote_consumer_uses_remote_names_registry() -> None:
    spec = read("src/server/Tests/B12StrokeRemoteSpec.lua")
    assert 'WaitForChild("RemoteNames")' in spec
    assert "RemoteNames.SubmitStroke" in spec
    assert "RemoteNames.StrokeResult" in spec
    assert 'WaitForChild("SubmitStroke")' not in spec
    assert 'WaitForChild("StrokeResult")' not in spec
