from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b06_racer_runtime_contract() -> None:
    runtime = ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua"
    assert runtime.is_file(), "missing B06 RacerRuntime.lua"
    text = runtime.read_text(encoding="utf-8")

    for token in [
        "RacerTemplate",
        "BodyCollider",
        "Vector3.new(3, 3, 3)",
        "RuntimeAttachments",
        "LaneAlignAttachment",
        "OrientationAttachment",
        "RaceId",
        "SlotIndex",
        "LaneIndex",
        "IsBot",
        "ShapeVersion",
        "TrackId",
        "Finished",
        "function RacerRuntime:Destroy",
    ]:
        assert token in text, f"missing B06 runtime token: {token}"

    assert "Humanoid" not in text
    assert "Motor6D" not in text
    for retired_marker in ["LeftHub", "RightHub", "makeCompatibilityHub"]:
        assert retired_marker not in text, f"retired B06 compatibility marker remains: {retired_marker}"

    # The racer template owns only the body/runtime shell. LegPairAssembly creates
    # the one physical axle/hinge later, after an authoritative shape exists.
    template_section = text.split("function RacerRuntime.EnsureTemplate()", 1)[1].split(
        "function RacerRuntime.new", 1
    )[0]
    assert "AngularVelocity" not in template_section, "B06 template must not configure motor velocity"
    assert "HingeConstraint" not in template_section, "B06 template must not instantiate leg hinges"


def test_b06_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B06RacerRuntimeSpec.lua"
    assert spec.is_file(), "missing B06 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")
    for token in [
        "RacerRuntime.EnsureTemplate",
        "RacerRuntime.new",
        "BodyCollider",
        "RacerTemplate",
        "racer:Destroy()",
        "[DrawRacers][B06] RacerTemplate/RacerRuntime tests PASS",
    ]:
        assert token in text, f"missing B06 Studio spec token: {token}"

    assert "LeftHub" not in text and "RightHub" not in text

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B06RacerRuntimeSpec" in bootstrap
    assert "B06RacerRuntimeSpec.run()" in bootstrap