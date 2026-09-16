--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CollisionGroups = require(script.Parent.Parent.Runtime:WaitForChild("CollisionGroups"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegCoreConfig = require(script.Parent.Parent.Runtime:WaitForChild("CoreV3"):WaitForChild("LegCoreConfig"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local C07CoreV3FlatLocomotionSpec = {}
local START_CONTACT_PROXIMITY = 0.20

local ROUND_SHAPE = {
	Vector2.zero,
	Vector2.new(0.72, 0),
	Vector2.new(0.624, 0.36),
	Vector2.new(0.36, 0.624),
	Vector2.new(0, 0.72),
	Vector2.new(-0.36, 0.624),
	Vector2.new(-0.624, 0.36),
	Vector2.new(-0.72, 0),
	Vector2.new(-0.624, -0.36),
	Vector2.new(-0.36, -0.624),
	Vector2.new(0, -0.72),
	Vector2.new(0.36, -0.624),
	Vector2.new(0.624, -0.36),
	Vector2.new(0.72, 0),
}

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

local function axleAttachmentError(core: any): number
	local joint = core:GetSharedAxle():GetJoint()
	local attachment0 = joint.Attachment0
	local attachment1 = joint.Attachment1
	if attachment0 == nil or attachment1 == nil then
		return math.huge
	end
	return (attachment0.WorldPosition - attachment1.WorldPosition).Magnitude
end

local function hasHorizontalAssist(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("VectorForce") then
			if math.abs(descendant.Force.X) > 1e-6 or math.abs(descendant.Force.Z) > 1e-6 then
				return true
			end
		elseif descendant:IsA("LinearVelocity") then
			local velocity = descendant.VectorVelocity
			if math.abs(velocity.X) > 1e-6 or math.abs(velocity.Z) > 1e-6 then
				return true
			end
		elseif descendant:IsA("BodyVelocity") then
			local velocity = descendant.Velocity
			if math.abs(velocity.X) > 1e-6 or math.abs(velocity.Z) > 1e-6 then
				return true
			end
		end
	end
	return false
end

local function legNearTrack(core: any, track: BasePart): number
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { track }
	params.MaxParts = 8

	local count = 0
	for _, leg in { core:GetLeftLeg(), core:GetRightLeg() } do
		assert(leg ~= nil, "C07 ACTIVE locomotion requires both leg owners")
		for _, part in leg:GetCollisionSegments() do
			local probeSize = part.Size + Vector3.new(
				START_CONTACT_PROXIMITY,
				START_CONTACT_PROXIMITY,
				START_CONTACT_PROXIMITY
			)
			if #Workspace:GetPartBoundsInBox(part.CFrame, probeSize, params) > 0 then
				count += 1
			end
		end
	end
	return count
end

function C07CoreV3FlatLocomotionSpec.run()
	CollisionGroups.ensure()
	local runtimeFolder, createdRuntime = ensureFolder(Workspace, "Runtime")
	local racersFolder, createdRacers = ensureFolder(runtimeFolder, "Racers")
	local tracksFolder, createdTracks = ensureFolder(runtimeFolder, "Tracks")
	local templatesFolder, createdTemplates = ensureFolder(ServerStorage, "RacerTemplates")

	local savedTemplate = templatesFolder:FindFirstChild("RacerTemplate")
	if savedTemplate ~= nil then
		savedTemplate.Name = "RacerTemplate_C07Saved"
	end

	local track = Instance.new("Part")
	track.Name = "C07FlatTrack"
	track.Size = Vector3.new(180, 2, 8)
	track.CFrame = CFrame.new(90, -1, 0)
	track.Anchored = true
	track.CanCollide = true
	track.CanTouch = true
	track.CanQuery = true
	track.CollisionGroup = CollisionGroups.Track
	track.Parent = tracksFolder

	local racer = nil :: any
	local generatedTemplate = nil :: Model?
	local ok, failure = xpcall(function()
		generatedTemplate = RacerRuntime.EnsureTemplate()
		local trackTopY = track.Position.Y + track.Size.Y * 0.5
		assert(math.abs(LegCoreConfig.Start.RestingAxleHeightAboveTrack - 1.55) < 1e-6,
			"C07 EMPTY height must keep the 3-stud cube just above Track contact")
		local spawnY = trackTopY + LegCoreConfig.Start.RestingAxleHeightAboveTrack
		racer = RacerRuntime.new({
			raceId = "C07_COREV3",
			slotIndex = 1,
			laneIndex = 1,
			isBot = false,
			trackId = "C07_FLAT",
			spawnCFrame = CFrame.new(4, spawnY, 0),
			laneCenterZ = 0,
		})

		local body = racer:GetBody()
		assert(body.Anchored == true, "C07 EMPTY racer must hang motionless before the first shape")
		assert(body.AssemblyLinearVelocity.Magnitude < 1e-4, "C07 EMPTY hold must zero linear velocity")
		assert(body.AssemblyAngularVelocity.Magnitude < 1e-4, "C07 EMPTY hold must zero angular velocity")
		local model = racer:GetModel()
		local lane = racer:GetLaneConstraint()
		local laneOwner = model:FindFirstChild("CoreV3LaneConstraint")
		assert(laneOwner ~= nil, "C07 dedicated lane owner missing")
		assert(countHinges(model) == 0, "C07 lane owner must not create a second/early hinge")
		assert(lane:GetPlaneConstraint().Enabled == true, "C07 lane PlaneConstraint must be enabled")
		local plane = lane:GetPlaneConstraint()
		local upright = lane:GetOrientationConstraint()
		assert(plane.Attachment0 ~= nil and plane.Attachment0.Axis == Vector3.zAxis,
			"C07 PlaneConstraint reference normal must lock only Z")
		assert(plane.Attachment1 ~= nil and plane.Attachment1.Axis == Vector3.zAxis,
			"C07 Body plane normal must leave X/Y free")
		assert(upright.Attachment0 ~= nil and upright.Attachment0.Parent == body,
			"C07 upright orientation must act only on BodyCollider")
		assert(upright.Attachment1 == nil, "C07 upright orientation must not constrain SharedAxle")
		assert(upright.RigidityEnabled == true, "C07 BodyCollider upright must be rigid")
		assert(model:FindFirstChildWhichIsA("AlignPosition", true) == nil,
			"C07 lane owner must not constrain X/Y through AlignPosition")
		assert(not hasHorizontalAssist(model), "C07 lane owner must not use horizontal movement helpers")

		-- The explicit EMPTY hold must remain stationary without a mover or force.
		local passiveStartX = body.Position.X
		for _ = 1, 4 do
			RunService.Heartbeat:Wait()
		end
		assert(math.abs(body.Position.X - passiveStartX) < 0.05, "C07 EMPTY hold allowed passive +X/-X movement")

		-- EMPTY is an explicit staging hold: even external impulses must not move
		-- the racer before a physical pair has committed ACTIVE.
		local heldPosition = body.Position
		body:ApplyImpulse(Vector3.new(body.AssemblyMass * 6, body.AssemblyMass * 35, body.AssemblyMass * 12))
		for _ = 1, 4 do
			RunService.Heartbeat:Wait()
		end
		assert((body.Position - heldPosition).Magnitude < 1e-4, "C07 EMPTY hold allowed pre-shape movement")
		local build = LegShapeService.ValidateAndBuild(racer, ROUND_SHAPE, true)
		assert(build.accepted == true, build.rejectReasonCode or "C07 ROUND must commit ACTIVE")
		assert(body.Anchored == false, "C07 first ACTIVE pair must release BodyCollider")
		assert(body.AssemblyLinearVelocity.Magnitude < 1e-4, "C07 released Body must start from zero linear velocity")
		assert(body.AssemblyAngularVelocity.Magnitude < 1e-4, "C07 released Body must start from zero angular velocity")

		local core = racer:GetLegCore()
		assert(core ~= nil and core:GetState() == "ACTIVE", "C07 accepted ROUND must be mechanically ACTIVE")
		local axle = core:GetSharedAxle()
		local axleRoot = axle:GetAxleRoot()
		local joint = axle:GetJoint()
		assert(axleRoot.AssemblyLinearVelocity.Magnitude < 1e-4, "C07 released axle must start from zero linear velocity")
		assert(axleRoot.AssemblyAngularVelocity.Magnitude < 1e-4, "C07 motor must not preload axle before release")
		assert(countHinges(model) == 1, "C07 requires exactly one HingeConstraint")
		assert(joint.Enabled == true, "C07 hinge must stay structurally connected")
		assert(joint.ActuatorType == Enum.ActuatorType.Motor, "C07 ACTIVE ROUND requires motor actuator")
		assert(not hasHorizontalAssist(model), "C07 must not use horizontal movement helpers")
		assert(
			legNearTrack(core, track) > 0,
			"C07 first release must begin with the physical pair already within Track contact proximity"
		)

		local startX = body.Position.X
		local elapsed = 0
		local continuousRotationSeconds = 0
		local sawPositiveVX = false
		local passed = false

		while elapsed < 2.0 do
			local dt = RunService.Heartbeat:Wait()
			elapsed += dt
			assert(countHinges(model) == 1, "C07 locomotion created duplicate hinge")
			assert(joint.Enabled == true, "C07 locomotion disconnected the hinge")
			assert(axleAttachmentError(core) <= 0.15, "C07 axle/body attachment separation exceeded 0.15")
			assert(not hasHorizontalAssist(model), "C07 locomotion used horizontal helper")

			local axis = if joint.Attachment1 ~= nil then joint.Attachment1.WorldAxis else Vector3.zAxis
			local relativeOmega = axleRoot.AssemblyAngularVelocity:Dot(axis) - body.AssemblyAngularVelocity:Dot(axis)
			local hasContact = legNearTrack(core, track) > 0
			local motorCommanded = joint.ActuatorType == Enum.ActuatorType.Motor and math.abs(joint.AngularVelocity) >= 1.0
			if hasContact and motorCommanded and math.abs(relativeOmega) >= 0.50 then
				continuousRotationSeconds += dt
			else
				continuousRotationSeconds = 0
			end

			if hasContact and body.AssemblyLinearVelocity.X > 0.02 then
				sawPositiveVX = true
			end
			local forwardDelta = body.Position.X - startX
			if forwardDelta > 0.50 and sawPositiveVX and continuousRotationSeconds >= 0.50 then
				passed = true
				break
			end
		end

		assert(passed, string.format(
			"C07 dead flat drive: dx=%.3f vx=%.3f sustainedRotation=%.2f",
			body.Position.X - startX,
			body.AssemblyLinearVelocity.X,
			continuousRotationSeconds
		))
	end, debug.traceback)

	if racer ~= nil then
		racer:Destroy()
	end
	track:Destroy()
	if generatedTemplate ~= nil and generatedTemplate.Parent ~= nil then
		generatedTemplate:Destroy()
	end
	if savedTemplate ~= nil then
		savedTemplate.Name = "RacerTemplate"
	end
	if createdTemplates and #templatesFolder:GetChildren() == 0 then templatesFolder:Destroy() end
	if createdTracks and #tracksFolder:GetChildren() == 0 then tracksFolder:Destroy() end
	if createdRacers and #racersFolder:GetChildren() == 0 then racersFolder:Destroy() end
	if createdRuntime and #runtimeFolder:GetChildren() == 0 then runtimeFolder:Destroy() end

	assert(ok, failure)
	print("[DrawRacers][C07] real flat locomotion physics PASS")
end

return C07CoreV3FlatLocomotionSpec
