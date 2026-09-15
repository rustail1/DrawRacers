--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CollisionGroups = require(script.Parent.Parent.Runtime:WaitForChild("CollisionGroups"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegCoreConfig = require(script.Parent.Parent.Runtime.CoreV3:WaitForChild("LegCoreConfig"))

local C08CoreV3FallRecoverySpec = {}

local SHAPE = {
	Vector2.zero,
	Vector2.new(0.8, 0),
	Vector2.new(0.8, 0.8),
	Vector2.new(0, 0.8),
	Vector2.zero,
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

local function hasHorizontalHelper(root: Instance): boolean
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("VectorForce") and math.abs(descendant.Force.X) > 1e-6 then
			return true
		elseif descendant:IsA("LinearVelocity") and math.abs(descendant.VectorVelocity.X) > 1e-6 then
			return true
		elseif descendant:IsA("BodyVelocity") and math.abs(descendant.Velocity.X) > 1e-6 then
			return true
		end
	end
	return false
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

function C08CoreV3FallRecoverySpec.run()
	CollisionGroups.ensure()
	local runtimeFolder, createdRuntime = ensureFolder(Workspace, "Runtime")
	local racersFolder, createdRacers = ensureFolder(runtimeFolder, "Racers")
	local tracksFolder, createdTracks = ensureFolder(runtimeFolder, "Tracks")
	local templatesFolder, createdTemplates = ensureFolder(ServerStorage, "RacerTemplates")

	local savedTemplate = templatesFolder:FindFirstChild("RacerTemplate")
	if savedTemplate ~= nil then
		savedTemplate.Name = "RacerTemplate_C08Saved"
	end

	local track = Instance.new("Part")
	track.Name = "C08FlatTrack"
	track.Size = Vector3.new(120, 2, 12)
	track.CFrame = CFrame.new(50, -1, 2)
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
		local spawnCFrame = CFrame.new(4, 3.3, 2)
		racer = RacerRuntime.new({
			raceId = "C08_RECOVERY",
			slotIndex = 1,
			laneIndex = 1,
			isBot = false,
			trackId = "C08_FLAT",
			spawnCFrame = spawnCFrame,
			laneCenterZ = 2,
		})

		racer:ApplyShape(SHAPE, true)
		local model = racer:GetModel()
		local body = racer:GetBody()
		local core = racer:GetLegCore()
		local recovery = racer:GetFallRecovery()
		assert(core ~= nil and core:GetState() == "ACTIVE", "C08 fixture requires ACTIVE pair")
		assert(recovery ~= nil, "C08 FallRecovery owner missing")

		local acceptedShape = racer:GetCurrentShapeSpec()
		local shapeVersion = racer:GetShapeVersion()
		local sameModel = model
		local riderAnchor = Instance.new("Attachment")
		riderAnchor.Name = "RiderAnchor"
		riderAnchor.Parent = body
		local laneReference = racer:GetLaneConstraint():GetReference()
		local laneReferenceBefore = laneReference.CFrame

		model:PivotTo(CFrame.new(30, LegCoreConfig.Recovery.FallThreshold - 5, -9))
		body.AssemblyLinearVelocity = Vector3.new(35, -70, 18)
		body.AssemblyAngularVelocity = Vector3.new(8, 5, 6)

		waitFor(function()
			return recovery:GetRecoveryCount() == 1
		end, 2.0, "C08 recovery did not trigger")

		assert(racer:GetModel() == sameModel, "C08 recovery must not create a new racer")
		assert((body.Position - spawnCFrame.Position).Magnitude < 0.35, "C08 body did not return to spawn")
		assert(math.abs(body.Position.Z - 2) < 0.05, "C08 recovery must restore lane center")
		assert(body.AssemblyLinearVelocity.Magnitude < 5, "C08 dangerous linear velocity was not cleared")
		assert(body.AssemblyAngularVelocity.Magnitude < 5, "C08 dangerous angular velocity was not cleared")
		assert(laneReference.CFrame == laneReferenceBefore, "C08 lane world reference must survive whole-model PivotTo")
		assert(countHinges(model) == 1, "C08 recovery must preserve exactly one hinge")
		assert(racer:GetShapeVersion() == shapeVersion, "C08 recovery must preserve ShapeVersion")
		assert(racer:GetCurrentShapeSpec() == acceptedShape, "C08 recovery must preserve accepted ShapeSpec")
		assert(core:GetState() == "ACTIVE", "C08 recovered pair must remain ACTIVE")
		assert(core:GetSharedAxle():GetJoint().ActuatorType == Enum.ActuatorType.Motor, "C08 motor must resume")
		assert(riderAnchor.Parent == body, "C08 recovery must preserve RiderAnchor")
		assert(not hasHorizontalHelper(model), "C08 recovery must not add +X helper")

		for _ = 1, 5 do
			RunService.Heartbeat:Wait()
		end
		assert(recovery:GetRecoveryCount() == 1, "C08 one fall must trigger exactly one recovery")
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
	print("[DrawRacers][C08] Core V3 fall recovery PASS")
end

return C08CoreV3FallRecoverySpec
