--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegAssembly = require(script.Parent:WaitForChild("LegAssembly"))

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
}

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
	if RunService:IsStudio() then
		ensureRuntimeFolder(model, "Debug")
	end

	model:SetAttribute("RaceId", params.raceId)
	model:SetAttribute("SlotIndex", params.slotIndex)
	model:SetAttribute("LaneIndex", params.laneIndex)
	model:SetAttribute("IsBot", params.isBot)
	model:SetAttribute("ShapeVersion", 0)
	model:SetAttribute("TrackId", params.trackId)
	model:SetAttribute("Finished", false)

	model:PivotTo(params.spawnCFrame)
	model.Parent = racersRoot

	local self = setmetatable({
		model = model,
		body = body,
		leftLeg = nil,
		rightLeg = nil,
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

function RacerRuntime:ApplyShape(normalizedPoints: { Vector2 }, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	assert(#normalizedPoints >= 2, "ApplyShape requires at least two normalized points")

	if self.leftLeg then
		self.leftLeg:Destroy()
		self.leftLeg = nil
	end
	if self.rightLeg then
		self.rightLeg:Destroy()
		self.rightLeg = nil
	end

	local leftLeg = LegAssembly.new({
		racerModel = self.model,
		side = "Left",
		normalizedPoints = normalizedPoints,
		motorEnabled = motorEnabled,
		initialPhaseDegrees = 0,
	})

	local rightOk, rightResult = pcall(function()
		return LegAssembly.new({
			racerModel = self.model,
			side = "Right",
			normalizedPoints = normalizedPoints,
			motorEnabled = motorEnabled,
			initialPhaseDegrees = PhysicsConfig.Motor.RightPhaseOffsetDegrees,
		})
	end)

	if not rightOk then
		leftLeg:Destroy()
		error(rightResult)
	end

	local rightLeg = rightResult
	self.leftLeg = leftLeg
	self.rightLeg = rightLeg

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
	if self.model then
		self.model:Destroy()
	end
	self.model = nil
	self.body = nil
end

return RacerRuntime
