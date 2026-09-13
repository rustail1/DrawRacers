from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_mr06_mechanical_cluster_has_no_retired_shared_axle_or_fixed_center_paths() -> None:
    paths = [
        "src/server/Runtime/LegAssembly.lua",
        "src/server/Runtime/LegPairAssembly.lua",
        "src/server/Runtime/RacerRuntime.lua",
        "src/server/Services/LegShapeService.lua",
        "src/shared/Math/CanonicalLegShape.lua",
        "src/client/Controllers/DrawingController.lua",
    ]
    combined = "\n".join(read(path) for path in paths)
    for retired in [
        '"AxleRoot"', '"AxleJoint"', "AxleMotorAttachment", "LegSocketZAbs",
        "BeginGeometryReshape", "CompleteReshapeForRecovery",
        "ReshapeSupportForce", "GravityCompensationFraction", "ReshapeTipCollider",
        "PivotStartRadiusNormalized", "START_OFF_PIVOT", "START FROM THE DOT", "PivotMarker",
        "AcceptedShapeThumbnail", "ComputePhaseCorrection",
    ]:
        assert retired not in combined
    assert "presentationAnchor" in read("src/shared/Math/CanonicalLegShape.lua")
    assert "_presentationAnchors" in read("src/client/Controllers/DrawingController.lua")


def test_mr06_one_canonical_builder_and_twin_drive_hinge_owner() -> None:
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    service = read("src/server/Services/LegShapeService.lua")
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "function CanonicalLegShape.Build" in canonical
    assert "CanonicalLegShape.Build" in runtime
    assert "CanonicalLegShape.Build" in service
    assert "CanonicalLegShape.Build" in drawing
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert pair.count("LegDriveAssembly.new") == 2
    assert 'Instance.new("HingeConstraint")' not in pair


def test_mr06_pair_exposes_one_transactional_redraw_pipeline() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    for token in [
        "function LegPairAssembly:StageRedraw", "function LegPairAssembly:SetStageProgress",
        "function LegPairAssembly:CommitStagedRedraw", "function LegPairAssembly:CancelStagedRedraw",
    ]:
        assert token in pair
    assert "BeginGeometryReshape" not in pair
    assert "ReplaceGeometry" not in pair


def test_mr06_template_and_studio_specs_remain_available() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert 'body.Name = "BodyCollider"' in runtime
    assert 'ensureRuntimeFolder(model, "Legs")' in runtime
    for name in ["B07LegAssemblySpec", "B09TwoLegPhaseSpec", "B11LegShapeServiceSpec", "B13AtomicRedrawSpec", "B14RedrawStressSpec"]:
        assert name in bootstrap


def test_mr06_safety_gates_and_fast_g0_remain_intact() -> None:
    session = read("docs/SESSION.md")
    feature = read("docs/FEATURE_LIST.md")
    harness_config = read("src/shared/Config/StudioHarnessConfig.lua")
    assert 'Mode = "G0"' in harness_config
    assert "G0" in session
    assert "HUMAN" in session.upper()
    assert "G0" in feature
