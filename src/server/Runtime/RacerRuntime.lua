--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local GeometryMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("GeometryMath")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegAssembly = require(script.Parent:WaitForChild("LegAssembly"))
local RacerStabilizer = require(script.Parent:WaitForChild("RacerStabilizer"))

local BODY_SIZE = Vector3.new(3, 3, 3)
local LEFT_HUB_OFFSET = Vector3.new(0, -0.75, -1.62)
local RIGHT_HUB_OFFSET = Vector3.new(0, -0.75, 1.62)

local RacerRuntime = {}
RacerRuntime.__index = RacerRuntime

export type SpawnParams = {
	raceId: string,
	slotIndex: number,
	laneIndex: number,
	isBot: boolean,
	trackId: string,
	spawnCFrame: CFrame,
	laneCenterZ: number?,
}

local function debugEnvironmentAllowed(): boolean
	if RunService:IsStudio() then
		return true
	end
	local environment = game:GetAttribute("DrawRacersEnvironment")
	return environment == "DEV" or environment == "STAGING"
end

local function makeHub(name: string, offset: Vector3, body: Part, parent: Model): Part
	local hub = Instance.new("Part")
	hub.Name = name
	hub.Size = Vector3.new(0.25, 0.25, 0.25)
	hub.CFrame = body.CFrame * CFrame.new(offset)
	hub.Anchored = false
	hub.CanCollide = false
	hub.CanTouch = false
	hub.CanQuery = false
	hub.Transparency = 1
	hub.Massless = true
	hub.CollisionGroup = CollisionGroups.RacerBody
	hub.Parent = parent

	local motorAttachment = Instance.new("Attachment")
	motorAttachment.Name = "MotorAttachment"
	motorAttachment.Axis = Vector3.zAxis
	motorAttachment.SecondaryAxis = Vector3.yAxis
	motorAttachment.Parent = hub

	local bodyWeld = Instance.new("WeldConstraint")
	bodyWeld.Name = "BodyWeld"
	bodyWeld.Part0 = body
	bodyWeld.Part1 = hub
	bodyWeld.Parent = hub

	return hub
end

function RacerRuntime.EnsureTemplate(): Model
	CollisionGroups.ensure()

	local templatesRoot = ServerStorage:WaitForChild("RacerTemplates")
	local existing = templatesRoot:FindFirstChild("RacerTemplate")
	if existing and existing:IsA("Model") then
		return existing
	end

	local template = Instance.new("Model")
	template.Name = "RacerTemplate"

	local body = Instance.new("Part")
	body.Name = "BodyCollider"
	body.Size = BODY_SIZE
	body.Anchored = false
	body.CanCollide = true
	body.CanTouch = true
	body.CanQuery = true
	body.Transparency = 1
	body.CollisionGroup = CollisionGroups.RacerBody
	body.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.45, 0.05, 100, 100)
	body.Parent = template

	local visualRoot = Instance.new("Folder")
	visualRoot.Name = "VisualRoot"
	visualRoot.Parent = template

	makeHub("LeftHub", LEFT_HUB_OFFSET, body, template)
	makeHub("RightHub", RIGHT_HUB_OFFSET, body, template)

	local runtimeAttachments = Instance.new("Folder")
	runtimeAttachments.Name = "RuntimeAttachments"
	runtimeAttachments.Parent = template

	local laneAlignAttachment = Instance.new("Attachment")
	laneAlignAttachment.Name = "LaneAlignAttachment"
	laneAlignAttachment.Parent = runtimeAttachments

	local orientationAttachment = Instance.new("Attachment")
	orientationAttachment.Name = "OrientationAttachment"
	orientationAttachment.Parent = runtimeAttachments

	template.PrimaryPart = body
	template.Parent = templatesRoot
	return template
end

local function ensureRuntimeFolder(model: Model, name: string): Folder
	local existing = model:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = model
	return folder
end

local function captureLegPhaseDegrees(leg: any, hub: Part, fallbackDegrees: number): number
	if leg == nil then
		return fallbackDegrees
	end

	local root = leg:GetRoot()
	local relative = hub.CFrame:ToObjectSpace(root.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
end

local function makeInternalShapeSpec(normalizedPoints: { Vector2 })
	local plan = GeometryMath.BuildSegmentPlan(normalizedPoints, PhysicsConfig.LegGeometry)
	assert(#plan.segmentPlan > 0, "internal shape produced no legal physical segments")
	return {
		version = 0,
		normalizedPoints = normalizedPoints,
		mappedPoints = plan.mappedPoints,
		segmentPlan = plan.segmentPlan,
		extent = plan.extent,
		debugRawPointCount = #normalizedPoints,
		debugPhysicsPointCount = #plan.mappedPoints,
	}
end

function RacerRuntime.new(params: SpawnParams)
	assert(params.slotIndex >= 1 and params.slotIndex <= 8, "slotIndex must be 1..8")
	assert(params.laneIndex >= 1 and params.laneIndex <= 8, "laneIndex must be 1..8")
	assert(params.raceId ~= "", "raceId must not be empty")
	assert(params.trackId ~= "", "trackId must not be empty")

	local template = RacerRuntime.EnsureTemplate()
	local racersRoot = Workspace:WaitForChild("Runtime"):WaitForChild("Racers")

	local model = template:Clone()
	model.Name = string.format("Racer_%s_%d", params.raceId, params.slotIndex)

	local body = model:FindFirstChild("BodyCollider")
	assert(body and body:IsA("Part"), "RacerTemplate missing BodyCollider")
	model.PrimaryPart = body

	ensureRuntimeFolder(model, "Legs")
	ensureRuntimeFolder(model, "Presentation")
	if debugEnvironmentAllowed() then
		ensureRuntimeFolder(model, "Debug")
	end

	model:SetAttribute("RaceId", params.raceId)
	model:SetAttribute("SlotIndex", params.slotIndex)
	model:SetAttribute("LaneIndex", params.laneIndex)
	model:SetAttribute("IsBot", params.isBot)
	model:SetAttribute("ShapeVersion", 0)
	model:SetAttribute("DebugRawPoints", 0)
	model:SetAttribute("DebugSimplifiedPoints", 0)
	model:SetAttribute("DebugPhysicsPoints", 0)
	model:SetAttribute("TrackId", params.trackId)
	model:SetAttribute("Finished", false)
	model:SetAttribute("LaneCenterZ", params.laneCenterZ or params.spawnCFrame.Position.Z)

	model:PivotTo(params.spawnCFrame)
	model.Parent = racersRoot

	local stabilizer = RacerStabilizer.new({
		racerModel = model,
		body = body,
		laneCenterZ = params.laneCenterZ or params.spawnCFrame.Position.Z,
	})

	local self = setmetatable({
		model = model,
		body = body,
		leftLeg = nil,
		rightLeg = nil,
		stabilizer = stabilizer,
		currentShapeSpec = nil,
		destroyed = false,
	}, RacerRuntime)

	return self
end

function RacerRuntime:GetModel(): Model
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	return self.model
end

function RacerRuntime:GetBody(): Part
	assert(not self.destroyed and self.body ~= nil, "RacerRuntime is destroyed")
	return self.body
end

function RacerRuntime:GetStabilizer()
	assert(not self.destroyed and self.stabilizer ~= nil, "RacerRuntime is destroyed")
	return self.stabilizer
end

function RacerRuntime:GetShapeVersion(): number
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	local version = self.model:GetAttribute("ShapeVersion")
	if type(version) ~= "number" then
		return 0
	end
	return version
end

function RacerRuntime:GetCurrentShapeSpec()
	assert(not self.destroyed, "RacerRuntime is destroyed")
	return self.currentShapeSpec
end

function RacerRuntime:_ApplyShapeSpec(shapeSpec: any, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table", "shapeSpec missing segmentPlan")
	assert(#shapeSpec.segmentPlan > 0, "shapeSpec requires physical segments")

	local model = self.model
	local leftHub = model:FindFirstChild("LeftHub")
	local rightHub = model:FindFirstChild("RightHub")
	local legsFolder = model:FindFirstChild("Legs")
	assert(leftHub and leftHub:IsA("Part"), "RacerRuntime missing LeftHub")
	assert(rightHub and rightHub:IsA("Part"), "RacerRuntime missing RightHub")
	assert(legsFolder and legsFolder:IsA("Folder"), "RacerRuntime missing Legs folder")

	local oldLeftLeg = self.leftLeg
	local oldRightLeg = self.rightLeg
	local leftPhaseDegrees = captureLegPhaseDegrees(oldLeftLeg, leftHub, 0)
	local rightPhaseDegrees = captureLegPhaseDegrees(
		oldRightLeg,
		rightHub,
		PhysicsConfig.Motor.RightPhaseOffsetDegrees
	)

	local stagedLeftLeg = nil
	local stagedRightLeg = nil
	local buildOk, buildError = pcall(function()
		stagedLeftLeg = LegAssembly.new({
			racerModel = model,
			side = "Left",
			shapeSpec = shapeSpec,
			motorEnabled = false,
			initialPhaseDegrees = leftPhaseDegrees,
			staged = true,
		})

		stagedRightLeg = LegAssembly.new({
			racerModel = model,
			side = "Right",
			shapeSpec = shapeSpec,
			motorEnabled = false,
			initialPhaseDegrees = rightPhaseDegrees,
			staged = true,
		})
	end)

	if not buildOk then
		if stagedLeftLeg ~= nil then
			stagedLeftLeg:Destroy()
		end
		if stagedRightLeg ~= nil then
			stagedRightLeg:Destroy()
		end
		error(buildError)
	end

	assert(stagedLeftLeg ~= nil and stagedRightLeg ~= nil, "atomic redraw staging produced incomplete legs")

	local oldLeftModel = if oldLeftLeg ~= nil then oldLeftLeg:GetModel() else nil
	local oldRightModel = if oldRightLeg ~= nil then oldRightLeg:GetModel() else nil
	if oldLeftModel ~= nil then
		oldLeftModel.Name = "LeftLeg_Retiring"
	end
	if oldRightModel ~= nil then
		oldRightModel.Name = "RightLeg_Retiring"
	end

	-- No yield occurs between staging completion and the commit below. Roblox physics cannot
	-- step between these statements, so both ready assemblies replace the previous pair as one
	-- server transaction without writing BodyCollider CFrame or assembly velocities.
	stagedLeftLeg:Commit()
	stagedRightLeg:Commit()
	stagedLeftLeg:SetEnabled(motorEnabled == true)
	stagedRightLeg:SetEnabled(motorEnabled == true)
	self.leftLeg = stagedLeftLeg
	self.rightLeg = stagedRightLeg

	if oldLeftLeg ~= nil then
		oldLeftLeg:Destroy()
	end
	if oldRightLeg ~= nil then
		oldRightLeg:Destroy()
	end

	return stagedLeftLeg, stagedRightLeg
end

-- Server-internal convenience path retained for geometry/harness tests. It still routes through
-- the one shared GeometryMath owner; client/remote paths must use ApplyValidatedShape.
function RacerRuntime:ApplyShape(normalizedPoints: { Vector2 }, motorEnabled: boolean?)
	assert(#normalizedPoints >= 2, "ApplyShape requires at least two normalized points")
	return self:_ApplyShapeSpec(makeInternalShapeSpec(normalizedPoints), motorEnabled)
end

function RacerRuntime:ApplyValidatedShape(shapeSpec: any, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	assert(type(shapeSpec) == "table", "ApplyValidatedShape requires ShapeSpec")
	assert(type(shapeSpec.version) == "number", "ShapeSpec missing numeric version")
	assert(type(shapeSpec.normalizedPoints) == "table", "ShapeSpec missing normalizedPoints")
	assert(type(shapeSpec.segmentPlan) == "table", "ShapeSpec missing segmentPlan")
	assert(shapeSpec.version == self:GetShapeVersion() + 1, "ShapeSpec version must increment by exactly one")

	local leftLeg, rightLeg = self:_ApplyShapeSpec(shapeSpec, motorEnabled)
	self.currentShapeSpec = shapeSpec
	self.model:SetAttribute("ShapeVersion", shapeSpec.version)
	self.model:SetAttribute("DebugRawPoints", shapeSpec.debugRawPointCount or #shapeSpec.normalizedPoints)
	self.model:SetAttribute("DebugSimplifiedPoints", #shapeSpec.normalizedPoints)
	self.model:SetAttribute("DebugPhysicsPoints", shapeSpec.debugPhysicsPointCount or #shapeSpec.mappedPoints)
	return leftLeg, rightLeg
end

function RacerRuntime:IsDestroyed(): boolean
	return self.destroyed
end

function RacerRuntime:Destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true
	if self.leftLeg then
		self.leftLeg:Destroy()
		self.leftLeg = nil
	end
	if self.rightLeg then
		self.rightLeg:Destroy()
		self.rightLeg = nil
	end
	if self.stabilizer then
		self.stabilizer:Destroy()
		self.stabilizer = nil
	end
	if self.model then
		self.model:Destroy()
	end
	self.model = nil
	self.body = nil
	self.currentShapeSpec = nil
end

return RacerRuntime