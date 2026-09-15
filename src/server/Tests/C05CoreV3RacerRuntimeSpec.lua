--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local CanonicalLegShape = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("CanonicalLegShape")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local C05CoreV3RacerRuntimeSpec = {}

local FIRST_SHAPE = {
	Vector2.zero,
	Vector2.new(-0.55, 0.70),
	Vector2.new(0.10, 0.92),
	Vector2.new(0.72, 0.45),
	Vector2.new(1.30, -0.05),
	Vector2.new(0.45, -0.78),
	Vector2.new(-0.45, -0.68),
}

local SECOND_SHAPE = {
	Vector2.zero,
	Vector2.new(-0.25, 0.75),
	Vector2.new(0.55, 0.60),
	Vector2.new(0.85, -0.30),
	Vector2.new(0.10, -0.85),
	Vector2.new(-0.70, -0.55),
}


local function networkPayload(sequence: number)
	return {
		sequence = sequence,
		points = {
			{ x = -0.72, y = 0 },
			{ x = 0, y = 0.72 },
			{ x = 0.72, y = 0 },
			{ x = 0, y = -0.72 },
		},
	}
end

local function assertNoDriveColliderValidation()
	local base = PhysicsConfig.LegGeometry
	local forcedNoColliderGeometry = {
		LegCanvasHalfSpan = base.LegCanvasHalfSpan,
		MaxLegExtentFromHub = base.MaxLegExtentFromHub,
		MinUsefulLegExtent = base.MinUsefulLegExtent,
		LegMountOutset = base.LegMountOutset,
		LegMountVerticalFraction = base.LegMountVerticalFraction,
		RightLegFixedPhaseDegrees = base.RightLegFixedPhaseDegrees,
		PhysicalLegSegmentThickness = base.PhysicalLegSegmentThickness,
		VisualLegSegmentThickness = base.VisualLegSegmentThickness,
		MaxColliderSegmentsPerLeg = base.MaxColliderSegmentsPerLeg,
		InnerHubNoCollisionRadius = 999,
		MinimumMappedSegmentLength = base.MinimumMappedSegmentLength,
		SegmentOverlapAllowance = base.SegmentOverlapAllowance,
	}
	local shape, reason = CanonicalLegShape.Build(
		FIRST_SHAPE,
		PhysicsConfig.StrokeProcessing,
		forcedNoColliderGeometry
	)
	assert(shape == nil and reason == "NO_DRIVE_COLLIDERS", "C05 canonical validation must reject shapes with zero drive colliders")
end

local function assertMechanicalPendingExceptionSafety()
	local now = 20.0
	local firstFault = true
	local fakeRacer = {
		GetShapeVersion = function()
			if firstFault then
				firstFault = false
				error("C05 injected GetShapeVersion failure")
			end
			return 0
		end,
		ApplyValidatedShape = function()
			return { accepted = false, rejectReasonCode = "BUILD_FAILED" }
		end,
	}
	local playerKey = {}
	local processor = LegShapeService.CreateSubmitProcessor({
		resolveRacer = function(key)
			return if key == playerKey then fakeRacer else nil
		end,
		now = function()
			return now
		end,
	})

	local first = processor:Handle(playerKey, networkPayload(1))
	assert(first ~= nil and first.accepted == false, "C05 injected transaction fault must reject")
	assert(first.rejectReasonCode == "MECHANICAL_INTERNAL_ERROR", "C05 transaction exception must become MECHANICAL_INTERNAL_ERROR")

	now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.05
	local second = processor:Handle(playerKey, networkPayload(2))
	assert(second ~= nil and second.rejectReasonCode ~= "REDRAW_PENDING", "C05 transaction exception must always release mechanicalPending")
end

local function ensureFolder(parent: Instance, name: string): (Folder, boolean)
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing:IsA("Folder"), name .. " must be Folder")
		return existing, false
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder, true
end

local function countHinges(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

local function countNamedModels(root: Instance, name: string): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == name then
			count += 1
		end
	end
	return count
end

local function countClass(root: Instance, className: string): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA(className) then
			count += 1
		end
	end
	return count
end

local function waitForState(core: any, target: string, timeout: number)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if core:GetState() == target then
			return
		end
		RunService.Heartbeat:Wait()
	end
	error(string.format("C05 timed out waiting for state %s; current=%s", target, core:GetState()))
end

local function collectPhysicalParts(core: any): { BasePart }
	local parts = {}
	for _, leg in { core:GetLeftLeg(), core:GetRightLeg() } do
		if leg ~= nil then
			for _, part in leg:GetPhysicalSegments() do
				table.insert(parts, part)
			end
		end
	end
	return parts
end

local function assertNoHorizontalForce(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("VectorForce") then
			assert(math.abs(descendant.Force.X) < 1e-6, "C05 Core V3 validation must not contain +X/-X VectorForce")
		end
	end
end

function C05CoreV3RacerRuntimeSpec.run()
	assertNoDriveColliderValidation()
	assertMechanicalPendingExceptionSafety()

	local runtimeFolder, createdRuntime = ensureFolder(Workspace, "Runtime")
	local racersFolder, createdRacers = ensureFolder(runtimeFolder, "Racers")
	local tracksFolder, createdTracks = ensureFolder(runtimeFolder, "Tracks")
	local templatesFolder, createdTemplates = ensureFolder(ServerStorage, "RacerTemplates")
	local templateExistedBefore = templatesFolder:FindFirstChild("RacerTemplate") ~= nil

	local track = Instance.new("Part")
	track.Name = "C05FlatTrack"
	track.Size = Vector3.new(160, 1, 30)
	track.CFrame = CFrame.new(0, 0, 0)
	track.Anchored = true
	track.CanCollide = true
	track.CanTouch = true
	track.CanQuery = true
	track.Parent = tracksFolder

	local racer = nil :: any
	local ok, failure = xpcall(function()
		racer = RacerRuntime.new({
			raceId = "C05_COREV3",
			slotIndex = 1,
			laneIndex = 1,
			isBot = false,
			trackId = "C05_FLAT",
			spawnCFrame = CFrame.new(0, 10, 0),
			laneCenterZ = 0,
		})

		local model = racer:GetModel()
		local body = racer:GetBody()
		body.Anchored = true

		assert(model:GetAttribute("CoreV3Validation") == true, "C05 racer must explicitly mark Core V3 validation mode")
		local laneOwner = model:FindFirstChild("CoreV3LaneConstraint")
		assert(laneOwner ~= nil and laneOwner:IsA("Model"), "C05 racer must create one dedicated lane/upright owner")
		assert(countNamedModels(model, "CoreV3LaneConstraint") == 1, "C05 racer must create lane owner exactly once")
		assert(countClass(laneOwner, "PlaneConstraint") == 1, "C05 lane owner must create exactly one PlaneConstraint")
		assert(countClass(laneOwner, "AlignOrientation") == 1, "C05 lane owner must create exactly one AlignOrientation")
		assert(countClass(laneOwner, "AlignPosition") == 0, "C05 lane owner must not constrain X/Y with AlignPosition")
		local laneConstraint = racer:GetLaneConstraint()
		local plane = laneConstraint:GetPlaneConstraint()
		local upright = laneConstraint:GetOrientationConstraint()
		assert(plane.Enabled == true, "C05 lane PlaneConstraint must stay enabled")
		assert(plane.Attachment0 ~= nil and plane.Attachment1 ~= nil, "C05 lane PlaneConstraint attachments missing")
		assert(math.abs((plane.Attachment0 :: Attachment).WorldAxis:Dot(Vector3.zAxis)) >= 0.999, "C05 lane plane normal must be world Z")
		assert(upright.Enabled == true, "C05 upright constraint must stay enabled")
		assert(upright.Mode == Enum.OrientationAlignmentMode.OneAttachment, "C05 upright must target world orientation")
		assert(upright.RigidityEnabled == false, "C05 upright must use bounded torque")
		assert(upright.MaxTorque > 0 and upright.MaxTorque < math.huge, "C05 upright torque must be finite and positive")
		assert(upright.Attachment0 ~= nil and (upright.Attachment0 :: Attachment).Parent == body, "C05 upright must act on BodyCollider only")
		assert(countHinges(model) == 0, "C05 fresh racer must not create a hinge before the first shape")
		assert(racer:GetLegCore() == nil, "C05 Core V3 controller must be lazy before first shape")
		assert(model:FindFirstChild("AntiStallForce", true) == nil, "C05 AntiStall must be absent in Core V3 validation")
		assert(model:FindFirstChild("BodyFloatForce", true) == nil, "C05 persistent BodyFloat must be absent in Core V3 validation")
		assert(model:FindFirstChild("OrientationAlign", true) == nil, "C05 legacy RacerStabilizer must be absent in Core V3 validation")

		local first = LegShapeService.ValidateAndBuild(racer, FIRST_SHAPE, false)
		assert(first.accepted == true, first.rejectReasonCode or "C05 first ShapeSpec application rejected")

		local core = racer:GetLegCore()
		assert(core ~= nil, "C05 first shape must create exactly one Core V3 controller")
		assert(core:GetState() == "ACTIVE", "C05 accepted result must not return before mechanical ACTIVE commit")
		local bodyProperties = body.CustomPhysicalProperties
		assert(bodyProperties ~= nil, "C05 Core V3 body must have explicit physical properties")
		assert(math.abs((bodyProperties :: PhysicalProperties).Density - 0.25) < 1e-6, "C05 Core V3 body mass tuning changed unexpectedly")
		assert(math.abs((bodyProperties :: PhysicalProperties).Friction) < 1e-6, "C05 Core V3 BodyCollider must not add Track friction")
		local sharedAxle = core:GetSharedAxle()
		assert(countHinges(model) == 1, "C05 first shape must create exactly one HingeConstraint")
		assert(model:FindFirstChild("CoreV3LaneConstraint") == laneOwner, "C05 first shape must preserve lane owner identity")
		assert(racer:GetLaneConstraint() == laneConstraint, "C05 first shape must preserve lane owner object")
		assert(countNamedModels(model, "CoreV3LaneConstraint") == 1, "C05 first shape must not duplicate lane owner")
		assert(core:GetState() == "ACTIVE", "C05 accepted first shape must already be mechanically ACTIVE")
		assert(racer:GetShapeVersion() == 1, "C05 first accepted shape must publish version 1")
		assert(racer:GetCurrentShapeSpec() == first.shapeSpec, "C05 RacerRuntime must publish the authoritative first ShapeSpec")
		assertNoHorizontalForce(model)

		local oldLeft = core:GetLeftLeg()
		local oldRight = core:GetRightLeg()
		assert(oldLeft ~= nil and oldRight ~= nil, "C05 first ACTIVE state requires both leg owners")
		local oldPhysicalParts = collectPhysicalParts(core)

		local second = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
		assert(second.accepted == true, second.rejectReasonCode or "C05 second ShapeSpec application rejected")
		assert(core:GetState() == "ACTIVE", "C05 accepted redraw must not return before mechanical ACTIVE commit")
		assert(racer:GetLegCore() == core, "C05 redraw must preserve the same LegCoreController")
		assert(core:GetSharedAxle() == sharedAxle, "C05 redraw must preserve the same SharedAxle")
		assert(countHinges(model) == 1, "C05 redraw must not create a second hinge")
		assert(model:FindFirstChild("CoreV3LaneConstraint") == laneOwner, "C05 redraw must preserve lane owner identity")
		assert(racer:GetLaneConstraint() == laneConstraint, "C05 redraw must preserve lane owner object")
		assert(countNamedModels(model, "CoreV3LaneConstraint") == 1, "C05 redraw must not duplicate lane owner")
		assert(core:GetLeftLeg() ~= oldLeft and core:GetRightLeg() ~= oldRight, "C05 redraw must replace only leg geometry owners")
		for _, part in oldPhysicalParts do
			assert(part.Parent == nil, "C05 old physical geometry must be destroyed on redraw")
		end

		assert(racer:GetLegCore() == core, "C05 ACTIVE redraw replaced LegCoreController")
		assert(core:GetSharedAxle() == sharedAxle, "C05 ACTIVE redraw replaced SharedAxle")
		assert(countHinges(model) == 1, "C05 ACTIVE redraw must still have exactly one hinge")
		assert(racer:GetShapeVersion() == 2, "C05 second accepted shape must publish version 2")
		assert(racer:GetCurrentShapeSpec() == second.shapeSpec, "C05 RacerRuntime must publish the authoritative second ShapeSpec")
		assertNoHorizontalForce(model)

		-- A mechanically impossible redraw must be rejected only after the Core V3
		-- controller fails closed. It must never advance ShapeVersion or remain
		-- published as the current active ShapeSpec.
		local blocker = Instance.new("Part")
		blocker.Name = "C05ImpossibleMechanicalCommit"
		blocker.Size = Vector3.new(60, 40, 40)
		blocker.CFrame = body.CFrame
		blocker.Anchored = true
		blocker.CanCollide = false
		blocker.CanTouch = false
		blocker.CanQuery = true
		blocker.Transparency = 1
		blocker.Parent = tracksFolder

		local failed = LegShapeService.ValidateAndBuild(racer, FIRST_SHAPE, false)
		assert(failed.accepted == false, "C05 impossible redraw must not be acknowledged before mechanical completion")
		assert(failed.rejectReasonCode == "CLEARANCE_FAILED", "C05 impossible redraw must preserve mechanical failure reason")
		assert(failed.clearAccepted == true, "C05 failed redraw must tell the client that the old accepted pair was invalidated")
		assert(core:GetState() == "EMPTY", "C05 rejected mechanical redraw must fail closed to EMPTY")
		assert(racer:GetShapeVersion() == 2, "C05 rejected mechanical redraw must not advance ShapeVersion")
		assert(racer:GetCurrentShapeSpec() == nil, "C05 failed-closed racer must not publish a stale active ShapeSpec")
		blocker:Destroy()

		racer:PrepareForRecovery()
		local recoveryJoint = core:GetSharedAxle():GetJoint()
		assert(recoveryJoint.Enabled == true, "C05 recovery must keep physical hinge connected")
		assert(recoveryJoint.ActuatorType == Enum.ActuatorType.None, "C05 recovery must disable only the motor actuator")
	end, debug.traceback)

	if racer ~= nil then
		racer:Destroy()
	end
	track:Destroy()

	local template = templatesFolder:FindFirstChild("RacerTemplate")
	if not templateExistedBefore and template ~= nil then
		template:Destroy()
	end
	if createdTemplates and #templatesFolder:GetChildren() == 0 then
		templatesFolder:Destroy()
	end
	if createdTracks and #tracksFolder:GetChildren() == 0 then
		tracksFolder:Destroy()
	end
	if createdRacers and #racersFolder:GetChildren() == 0 then
		racersFolder:Destroy()
	end
	if createdRuntime and #runtimeFolder:GetChildren() == 0 then
		runtimeFolder:Destroy()
	end

	assert(ok, failure)
	print("[DrawRacers][C05] Core V3 RacerRuntime integration PASS")
end

return C05CoreV3RacerRuntimeSpec
