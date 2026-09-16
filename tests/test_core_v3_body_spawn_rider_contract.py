from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_core_v3_body_upright_is_body_only_and_position_neutral() -> None:
    lane = read("src/server/Runtime/CoreV3/LaneConstraint.lua")

    assert 'Instance.new("PlaneConstraint")' in lane
    assert "referenceAttachment.Axis = Vector3.zAxis" in lane
    assert "bodyPlaneAttachment.Axis = Vector3.zAxis" in lane
    assert 'Instance.new("AlignOrientation")' in lane
    assert "upright.Attachment0 = uprightAttachment" in lane
    assert "upright.RigidityEnabled = true" in lane
    assert 'Instance.new("AlignPosition")' not in lane
    assert 'Instance.new("VectorForce")' not in lane
    assert 'Instance.new("LinearVelocity")' not in lane
    assert 'WaitForChild("SharedAxle")' not in lane
    assert "GetSharedAxle" not in lane


def test_core_v3_flat_spawn_starts_at_body_contact_height_and_starts_still() -> None:
    harness = read("src/server/Tests/CoreV3FlatHarness.lua")
    core_config = read("src/server/Runtime/CoreV3/LegCoreConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")

    assert "ReferenceBenchmark.SpawnY" not in harness
    assert "RestingAxleHeightAboveTrack = BODY_HALF_HEIGHT + START_CONTACT_EPSILON" in core_config
    assert "SuspendedAxleHeightAboveTrack" not in core_config
    assert "TRACK_TOP_Y" in harness
    assert "LegCoreConfig.Start.RestingAxleHeightAboveTrack" in harness
    assert "body.Anchored = true" in runtime
    assert "local function releaseInitialHold" in runtime
    assert "body.Anchored = false" in runtime
    assert "body.AssemblyLinearVelocity = Vector3.zero" in harness
    assert "body.AssemblyAngularVelocity = Vector3.zero" in harness
    assert "TweenService" not in harness


def test_first_release_uses_one_bounded_geometry_clearance_placement_before_atomic_activation() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    controller = read("src/server/Runtime/CoreV3/LegCoreController.lua")
    wait_clear = controller.split("function LegCoreController:_StepWaitClear", 1)[1].split(
        "function LegCoreController:_Step", 1
    )[0]
    activation = controller.split("function LegCoreController:_ActivatePair", 1)[1].split(
        "function LegCoreController:_StepPreview", 1
    )[0]

    assert "setInitialHoldLift" in runtime
    assert "initialHoldBaseBodyCFrame" in runtime
    assert "self.setInitialHoldLift(result.requiredLift)" in wait_clear
    assert "result.requiredLift >= LegCoreConfig.Rebuild.MaxLift" in wait_clear
    assert wait_clear.index("self.setInitialHoldLift(result.requiredLift)") < wait_clear.index("self:_ActivatePair()")
    assert "beforePhysicalActivation" in runtime
    assert "beforePhysicalActivation" in activation
    assert "self.state = STATE_ACTIVE" in activation
    assert activation.index("self.state = STATE_ACTIVE") < activation.index("beforePhysicalActivation")
    assert activation.index("beforePhysicalActivation") < activation.index("self.leftLeg:SetPhysicsEnabled(true)")
    assert activation.index("beforePhysicalActivation") < activation.index("self.sharedAxle:SetEnabled")
    assert "axleRoot.AssemblyLinearVelocity = Vector3.zero" in runtime
    assert "axleRoot.AssemblyAngularVelocity = Vector3.zero" in runtime
    assert "Vector3.new(0, lift, 0)" in runtime
    assert "Vector3.new(lift, 0, 0)" not in runtime
    assert "Vector3.new(0, 0, lift)" not in runtime


def test_first_start_does_not_use_max_shape_extent_as_spawn_height() -> None:
    config = read("src/server/Runtime/CoreV3/LegCoreConfig.lua")

    assert "local BODY_HALF_HEIGHT = 1.5" in config
    assert "local START_CONTACT_EPSILON = 0.05" in config
    assert "MaxLegExtentFromHub" not in config
    assert "StartPresentationGap" not in config


def test_rider_uses_uninvented_loaded_avatar_at_explicit_unit_scale() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")

    assert "RIDER_PRESENTATION_SCALE = 1.0" in rider
    assert "visual:ScaleTo(RIDER_PRESENTATION_SCALE)" in rider
    assert "character:Clone()" in rider
    assert "player:HasAppearanceLoaded()" in rider
    for removed in (
        "applyCowboyPresentation",
        "CowboyHatPresentation",
        "CowboyHatBrim",
        "CowboyHatCrown",
        "CowboyHatBand",
        "configureCowboyPart",
        "weldCowboyPart",
    ):
        assert removed not in rider

    sanitize = rider[rider.index("local function sanitizeVisual"):rider.index("local function stabilizeVisualAssemblies")]
    assert 'descendant:IsA("Accessory")' not in sanitize
    for neutral in (
        "descendant.CanCollide = false",
        "descendant.CanTouch = false",
        "descendant.CanQuery = false",
        "descendant.Massless = true",
    ):
        assert neutral in sanitize
    assert "ensureRiderAnchor(body)" in rider
    assert "record.visual:PivotTo" in rider
