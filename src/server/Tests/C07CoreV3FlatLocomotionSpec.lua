--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CollisionGroups = require(script.Parent.Parent.Runtime:WaitForChild("CollisionGroups"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local C07CoreV3FlatLocomotionSpec = {}

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
			local probeSize = part.Size + Vector3.new(0.08, 0.08, 0.08)
			if #Workspace:GetPartBoundsInBox(part.CFrame, probeSize, params) > 0 then
				count += 1
			end
		end
	end
	return count
end

local function waitFor(predicate: () -> boolean, timeout: number, message: string)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if predicate() then
			return
		end
		RunService.Heartbeat:Wait()
	end
	error(message)
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
		racer = RacerRuntime.new({
			raceId = "C07_COREV3",
			slotIndex = 1,
			laneIndex = 1,
			isBot = false,
			trackId = "C07_FLAT",
			spawnCFrame = CFrame.new(4, 3.3, 0),
			laneCenterZ = 0,
		})

		local body = racer:GetBody()
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		local model = racer:GetModel()
		local lane = racer:GetLaneConstraint()
		local laneOwner = model:FindFirstChild("CoreV3LaneConstraint")
		assert(laneOwner ~= nil, "C07 dedicated lane owner missing")
		assert(countHinges(model) == 0, "C07 lane owner must not create a second/early hinge")
		assert(lane:GetPlaneConstraint().Enabled == true, "C07 lane PlaneConstraint must be enabled")
		assert(lane:GetOrientationConstraint().RigidityEnabled == false, "C07 upright torque must remain bounded")
		assert(not hasHorizontalAssist(model), "C07 lane owner must not use horizontal movement helpers")

		-- No legs and no external X impulse: neither lane confinement nor upright
		-- torque may manufacture forward locomotion.
		local passiveStartX = body.Position.X
		for _ = 1, 4 do
			RunService.Heartbeat:Wait()
		end
		assert(math.abs(body.Position.X - passiveStartX) < 0.05, "C07 lane owner created passive +X/-X locomotion")

		-- One external impulse must remain effective in the plane (X/Y), while an
		-- imposed Z offset and body tilt are corrected by their dedicated constraints.
		body.CFrame = CFrame.new(4, 18, 3) * CFrame.Angles(math.rad(28), math.rad(18), math.rad(24))
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		local freedomStart = body.Position
		body:ApplyImpulse(Vector3.new(body.AssemblyMass * 6, body.AssemblyMass * 35, body.AssemblyMass * 12))
		for _ = 1, 12 do
			RunService.Heartbeat:Wait()
		end
		assert(body.Position.X - freedomStart.X > 0.20, "C07 PlaneConstraint blocked free X translation")
		assert(body.Position.Y - freedomStart.Y > 0.10, "C07 PlaneConstraint blocked free Y translation")
		waitFor(function()
			return math.abs(body.Position.Z - lane:GetLaneCenterZ()) <= 0.10
		end, 1.0, "C07 body did not return to lane center Z")
		waitFor(function()
			return body.CFrame.UpVector:Dot(Vector3.yAxis) >= 0.97
		end, 1.5, "C07 body did not return upright")

		body.CFrame = CFrame.new(4, 3.3, lane:GetLaneCenterZ())
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		RunService.Heartbeat:Wait()
		local build = LegShapeService.ValidateAndBuild(racer, ROUND_SHAPE, true)
		assert(build.accepted == true, build.rejectReasonCode or "C07 ROUND must commit ACTIVE")

		local core = racer:GetLegCore()
		assert(core ~= nil and core:GetState() == "ACTIVE", "C07 accepted ROUND must be mechanically ACTIVE")
		local axle = core:GetSharedAxle()
		local axleRoot = axle:GetAxleRoot()
		local joint = axle:GetJoint()
		assert(countHinges(model) == 1, "C07 requires exactly one HingeConstraint")
		assert(joint.Enabled == true, "C07 hinge must stay structurally connected")
		assert(joint.ActuatorType == Enum.ActuatorType.Motor, "C07 ACTIVE ROUND requires motor actuator")
		assert(not hasHorizontalAssist(model), "C07 must not use horizontal movement helpers")

		local contactDeadline = os.clock() + 4.0
		while os.clock() < contactDeadline and legNearTrack(core, track) == 0 do
			RunService.Heartbeat:Wait()
		end
		assert(legNearTrack(core, track) > 0, "C07 ROUND never reached leg/Track contact")

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
