from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_first_shape_does_not_receive_redraw_hop() -> None:
    controller = read("src/server/Runtime/CoreV3/LegCoreController.lua")
    begin = controller.split("function LegCoreController:_BeginRebuild", 1)[1].split(
        "function LegCoreController:_ActivatePair", 1
    )[0]

    assert "local isRedraw = self.state == STATE_ACTIVE" in begin
    assert "if isRedraw then\n\t\tself:_ApplyRedrawHop()\n\tend" in begin
    assert begin.count("self:_ApplyRedrawHop()") == 1

    c04 = read("src/server/Tests/C04CoreV3ControllerSpec.lua")
    assert "C04 first shape must not apply redraw hop" in c04
    assert "C04 redraw hop must remain visibly upward" in c04


def test_wait_clear_settles_vertical_motion_before_pair_activation() -> None:
    controller = read("src/server/Runtime/CoreV3/LegCoreController.lua")
    wait_clear = controller.split("function LegCoreController:_StepWaitClear", 1)[1].split(
        "function LegCoreController:_Step", 1
    )[0]
    config = read("src/server/Runtime/CoreV3/LegCoreConfig.lua")
    c04 = read("src/server/Tests/C04CoreV3ControllerSpec.lua")

    assert "ClearanceSettlePositionTolerance = 0.05" in config
    assert "ClearanceSettleVerticalSpeed = 0.5" in config
    assert "local positionSettled" in wait_clear
    assert "local verticalSpeedSettled" in wait_clear
    assert "if result.clear and positionSettled and verticalSpeedSettled then" in wait_clear
    assert "if result.clear then\n\t\tself:_ActivatePair()" not in wait_clear
    assert "C04 pair must activate with settled vertical speed" in c04


def test_empty_hold_never_receives_clearance_force() -> None:
    controller = read("src/server/Runtime/CoreV3/LegCoreController.lua")
    wait_clear = controller.split("function LegCoreController:_StepWaitClear", 1)[1].split(
        "function LegCoreController:_Step", 1
    )[0]
    c05 = read("src/server/Tests/C05CoreV3RacerRuntimeSpec.lua")

    assert "if not self.body.Anchored then\n\t\tself:_EnsureLiftAssist(dt)\n\tend" in wait_clear
    assert "C05 rejected EMPTY build must not create clearance force" in c05


def test_rider_clone_keeps_avatar_runtime_and_hides_only_source_visual() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    sanitize = rider.split("local function sanitizeVisual", 1)[1].split(
        "local function stabilizeVisualAssemblies", 1
    )[0]

    assert "character:Clone()" in rider
    assert "player:HasAppearanceLoaded()" in rider
    assert "humanoid:Destroy()" not in sanitize
    assert "humanoid.AutoRotate = false" in sanitize
    assert "humanoid.PlatformStand = true" in sanitize
    assert "humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None" in sanitize
    assert 'descendant:IsA("Accessory")' not in sanitize
    assert "local function hideSourceCharacter" in rider
    assert "part.LocalTransparencyModifier = 1" in rider
    assert "local function restoreSourceCharacter" in rider
    assert "part.LocalTransparencyModifier = previousTransparency" in rider
    for forbidden in ('Instance.new("VectorForce")', 'Instance.new("LinearVelocity")', "ApplyImpulse"):
        assert forbidden not in rider
