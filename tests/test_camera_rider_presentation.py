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

    # Deterministic camera math must be frame-rate independent and explicitly
    # expose the vertical dead-zone/orbit helpers used by the controller.
    assert "function CameraMath.ExpAlpha" in camera_math
    assert "math.exp" in camera_math
    assert "function CameraMath.SmoothVector" in camera_math
    assert "function CameraMath.StepVerticalDeadZone" in camera_math
    assert "function CameraMath.ClampOrbit" in camera_math

    # Exact locked starting values from doc 16 / camera decision.
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
        "ORBIT_YAW_LIMIT = 40",
        "ORBIT_PITCH_LIMIT = 18",
        "ORBIT_RETURN_TIME = 0.40",
    ]:
        assert token in camera

    # The canonical 0.38 horizontal screen anchor is an active composition
    # input, not a dead constant. Pure math derives the camera's X offset from
    # FOV/aspect + look-ahead/side distance, and the controller uses it.
    assert "function CameraMath.ScreenAnchorCameraX" in camera_math
    assert "verticalFovDegrees" in camera_math
    assert "aspectRatio" in camera_math
    assert "screenAnchor" in camera_math
    assert "math.tan" in camera_math
    assert "CameraMath.ScreenAnchorCameraX(" in camera
    assert "LOCAL_RACER_SCREEN_ANCHOR" in camera.split("CameraMath.ScreenAnchorCameraX(", 1)[1]
    assert "camera.ViewportSize" in camera

    # Camera is local presentation only: lookup is via the replicated
    # server-authored OwnerUserId and there is no network authority path.
    assert 'GetAttribute("OwnerUserId")' in camera
    assert "LocalPlayer.UserId" in camera
    assert "BodyCollider" in camera
    assert "body.Position" in camera
    assert "body.CFrame" not in camera
    assert "RemoteEvent" not in camera
    assert "FireServer" not in camera

    # Camera lifecycle must restore the exact Camera instance that was captured.
    # Workspace.CurrentCamera may be replaced by Roblox during lifecycle changes;
    # restoring old type/FOV onto the replacement would corrupt its state.
    assert "_ownedCamera = nil :: Camera?" in camera
    assert "self._ownedCamera == camera" in camera
    release_body = camera.split("function RaceCameraController:_releaseCamera()", 1)[1].split(
        "function RaceCameraController:_applyOrbitDelta", 1
    )[0]
    assert "local camera = self._ownedCamera" in release_body
    assert "local camera = Workspace.CurrentCamera" not in release_body

    # Losing Workspace.CurrentCamera is also loss of camera ownership. The
    # controller must release the previously captured instance instead of
    # leaving it Scriptable with stale saved state until some future camera appears.
    assert "if camera == nil then\n\t\tself:_releaseCamera()\n\t\treturn" in camera

    # Desktop orbit owns RMB only and automatically returns after release.
    assert "Enum.UserInputType.MouseButton2" in camera
    assert "Enum.UserInputType.MouseButton1" not in camera
    assert "CameraMath.ClampOrbit" in camera
    assert "ORBIT_RETURN_TIME" in camera

    # Orbit input is meaningful only while this controller has an eligible local
    # racer to own. A pre-spawn RMB/touch gesture must not accumulate stale orbit
    # that is suddenly applied when a later racer appears.
    input_began_body = camera.split("UserInputService.InputBegan:Connect(function", 1)[1].split(
        "end))", 1
    )[0]
    local_racer_guard_index = input_began_body.index("findLocalRacerBody()")
    mouse_claim_index = input_began_body.index("self._mouseOrbitHeld = true")
    touch_claim_index = input_began_body.index("self._touchOrbitInput = input")
    assert local_racer_guard_index < mouse_claim_index
    assert local_racer_guard_index < touch_claim_index

    # Orbit return is presentation lifecycle state, not racer-body state. If the
    # racer briefly disappears after RMB release (respawn/replacement gap), the
    # 0.40 s return must continue instead of freezing and reappearing stale.
    step_body = camera.split("function RaceCameraController:_step(dt: number)", 1)[1].split(
        "function RaceCameraController:Start()", 1
    )[0]
    return_index = step_body.index("ORBIT_RETURN_TIME")
    racer_lookup_index = step_body.index("local body = findLocalRacerBody()")
    assert return_index < racer_lookup_index

    # Touch ownership is decided at begin from GUI/DrawInputRect hit testing.
    assert "GetGuiObjectsAtPosition" in camera
    assert 'Name == "DrawInputRect"' in camera or 'Name ~= "DrawInputRect"' in camera
    assert "Enum.UserInputType.Touch" in camera

    # Rider is a standardized client-only visual with a deterministic
    # oversized-accessory fallback and no gameplay authority.
    assert 'GetAttribute("OwnerUserId")' in rider
    assert "GetPlayerByUserId" in rider
    assert "ScaleTo(0.65)" in rider
    assert 'IsA("Accessory")' in rider
    assert "CanCollide = false" in rider
    assert "CanTouch = false" in rider
    assert "CanQuery = false" in rider
    assert "Massless = true" in rider
    assert "descendant.Anchored = true" in rider
    assert 'descendant.Anchored = descendant.Name == "HumanoidRootPart"' not in rider
    assert "BodyCollider" in rider
    assert "body.Position" in rider
    assert "body.CFrame" not in rider
    assert "RemoteEvent" not in rider
    assert "FireServer" not in rider
    assert "LegAssembly" not in rider
    assert "RacerRuntime" not in rider

    # Player.Character can exist before Roblox finishes applying the avatar
    # appearance. The rider must not cache a partial clone for the lifetime of
    # that Character; wait until HasAppearanceLoaded() before cloning it.
    ensure_record_body = rider.split("function RiderPresentationController:_ensureRecord", 1)[1].split(
        "function RiderPresentationController:_placeRider", 1
    )[0]
    appearance_loaded_index = ensure_record_body.index("player:HasAppearanceLoaded()")
    clone_index = ensure_record_body.index("cloneCharacterVisual(character)")
    assert appearance_loaded_index < clone_index

    # Bootstrap composes the production owners. The old Studio harness may
    # keep its debug proxy, but cannot remain a second active camera owner.
    assert 'require(controllers:WaitForChild("RaceCameraController"))' in bootstrap
    assert 'require(controllers:WaitForChild("RiderPresentationController"))' in bootstrap
    assert "RaceCameraController.new" in bootstrap
    assert "RiderPresentationController.new" in bootstrap
    assert "camera.CameraType" not in g0
    assert "camera.FieldOfView" not in g0
    assert "camera.CFrame" not in g0
