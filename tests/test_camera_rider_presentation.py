from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_early_camera_rider_presentation_contract() -> None:
    camera_math_path = ROOT / "src/shared/Math/CameraMath.lua"
    camera_path = ROOT / "src/client/Controllers/RaceCameraController.lua"
    rider_path = ROOT / "src/client/Controllers/RiderPresentationController.lua"

    assert camera_math_path.exists(), "early presentation requires pure CameraMath"
    assert camera_path.exists(), "early presentation requires production RaceCameraController"
    assert rider_path.exists(), "early presentation requires RiderPresentationController"

    camera_math = camera_math_path.read_text(encoding="utf-8")
    camera = camera_path.read_text(encoding="utf-8")
    rider = rider_path.read_text(encoding="utf-8")
    bootstrap = read("src/client/Bootstrap.client.lua")
    g0 = read("src/client/Dev/M0G0PresentationHarness.lua")

    for token in [
        "function CameraMath.ExpAlpha",
        "function CameraMath.SmoothVector",
        "function CameraMath.StepVerticalDeadZone",
        "function CameraMath.SmoothAngleDegrees",
        "function CameraMath.ClampPitch",
        "math.exp",
    ]:
        assert token in camera_math

    for token in [
        "FIELD_OF_VIEW = 60",
        "LOCAL_RACER_SCREEN_ANCHOR = 0.38",
        "LOOK_AHEAD = 11",
        "CAMERA_HEIGHT = 10",
        "SIDE_DISTANCE = 23",
        "POSITION_DAMPING_TIME = 0.16",
        "LOOK_TARGET_DAMPING_TIME = 0.12",
        "VERTICAL_DEAD_ZONE = 0.50",
        "VERTICAL_DAMPING_TIME = 0.22",
        "ORBIT_PITCH_LIMIT = 70",
        "ORBIT_INPUT_DAMPING_TIME = 0.08",
        "ORBIT_RETURN_TIME = 0.40",
        "_targetOrbitYaw",
        "_targetOrbitPitch",
    ]:
        assert token in camera
    assert "ORBIT_YAW_LIMIT" not in camera

    assert "function CameraMath.ScreenAnchorCameraX" in camera_math
    assert "verticalFovDegrees" in camera_math
    assert "aspectRatio" in camera_math
    assert "screenAnchor" in camera_math
    assert "math.tan" in camera_math
    assert "CameraMath.ScreenAnchorCameraX(" in camera
    assert "LOCAL_RACER_SCREEN_ANCHOR" in camera.split("CameraMath.ScreenAnchorCameraX(", 1)[1]
    assert "camera.ViewportSize" in camera

    assert 'GetAttribute("OwnerUserId")' in camera
    assert "LocalPlayer.UserId" in camera
    assert "BodyCollider" in camera
    assert "body.Position" in camera
    assert "body.CFrame" not in camera
    assert "RemoteEvent" not in camera
    assert "FireServer" not in camera

    assert "_ownedCamera = nil :: Camera?" in camera
    assert "self._ownedCamera == camera" in camera
    release_body = camera.split("function RaceCameraController:_releaseCamera()", 1)[1].split(
        "function RaceCameraController:_applyOrbitDelta", 1
    )[0]
    assert "local camera = self._ownedCamera" in release_body
    assert "local camera = Workspace.CurrentCamera" not in release_body
    assert "if camera == nil then\n\t\tself:_releaseCamera()\n\t\treturn" in camera

    assert "Enum.UserInputType.MouseButton2" in camera
    assert "Enum.UserInputType.MouseButton1" not in camera
    assert "CameraMath.ClampPitch" in camera
    assert "CameraMath.SmoothAngleDegrees" in camera
    assert "ORBIT_RETURN_TIME" in camera

    for token in [
        "_previousMouseBehavior",
        "function RaceCameraController:_beginMouseOrbit()",
        "function RaceCameraController:_endMouseOrbit()",
        "function RaceCameraController:_worldCameraInputAllowed",
        "UserInputService:GetFocusedTextBox()",
        "UserInputService.MouseBehavior",
        "Enum.MouseBehavior.LockCurrentPosition",
        "UserInputService.WindowFocusReleased:Connect",
    ]:
        assert token in camera, f"missing R17.1 camera ownership token: {token}"

    input_began_body = camera.split("UserInputService.InputBegan:Connect(function", 1)[1].split(
        "end))", 1
    )[0]
    local_racer_guard_index = input_began_body.index("findLocalRacerBody()")
    mouse_branch_index = input_began_body.index("Enum.UserInputType.MouseButton2")
    mouse_claim_index = input_began_body.index("self:_beginMouseOrbit()")
    processed_guard_index = input_began_body.index("if gameProcessed then")
    touch_branch_index = input_began_body.index("Enum.UserInputType.Touch")
    touch_claim_index = input_began_body.index("self._touchOrbitInput = input")
    assert local_racer_guard_index < mouse_branch_index < mouse_claim_index
    assert mouse_claim_index < processed_guard_index < touch_branch_index < touch_claim_index
    assert camera.count("self:_endMouseOrbit()") >= 5

    step_body = camera.split("function RaceCameraController:_step(dt: number)", 1)[1].split(
        "function RaceCameraController:Start()", 1
    )[0]
    return_index = step_body.index("ORBIT_RETURN_TIME")
    racer_lookup_index = step_body.index("local body = findLocalRacerBody()")
    assert return_index < racer_lookup_index

    assert "GetGuiObjectsAtPosition" in camera
    assert 'Name == "DrawInputRect"' in camera or 'Name ~= "DrawInputRect"' in camera
    assert "Enum.UserInputType.Touch" in camera

    # R17.2 rider remains presentation-only but now has a deterministic mount
    # and a real rig hierarchy. Only HumanoidRootPart is anchored; visible limbs
    # stay connected by Motor6D so the jockey pose can actually deform the rig.
    assert 'GetAttribute("OwnerUserId")' in rider
    assert "GetPlayerByUserId" in rider
    assert "RIDER_SCALE = 0.65" in rider
    assert "RIDER_MOUNT_X_OFFSET" in rider
    assert "RIDER_MOUNT_Y_OFFSET" in rider
    assert "function RiderPresentationController:_mountCFrame" in rider
    assert "ScaleTo(RIDER_SCALE)" in rider
    assert 'IsA("Accessory")' in rider
    assert "CanCollide = false" in rider
    assert "CanTouch = false" in rider
    assert "CanQuery = false" in rider
    assert "Massless = true" in rider
    assert 'descendant.Anchored = descendant.Name == "HumanoidRootPart"' in rider
    assert "descendant.Anchored = true" not in rider
    assert "riderHeight * 0.5" not in rider
    assert "BodyCollider" in rider
    assert "body.Position" in rider
    assert "body.CFrame" not in rider
    assert "RemoteEvent" not in rider
    assert "FireServer" not in rider
    assert "LegAssembly" not in rider
    assert "RacerRuntime" not in rider

    ensure_record_body = rider.split("function RiderPresentationController:_ensureRecord", 1)[1].split(
        "function RiderPresentationController:_placeRider", 1
    )[0]
    appearance_loaded_index = ensure_record_body.index("player:HasAppearanceLoaded()")
    clone_index = ensure_record_body.index("cloneCharacterVisual(character)")
    assert appearance_loaded_index < clone_index

    assert 'require(controllers:WaitForChild("RaceCameraController"))' in bootstrap
    assert 'require(controllers:WaitForChild("RiderPresentationController"))' in bootstrap
    assert "RaceCameraController.new" in bootstrap
    assert "RiderPresentationController.new" in bootstrap
    assert "camera.CameraType" not in g0
    assert "camera.FieldOfView" not in g0
    assert "camera.CFrame" not in g0
