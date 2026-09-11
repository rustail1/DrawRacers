--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("StrokeMath")
)
local GeometryMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("GeometryMath")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegPairAssembly = require(script.Parent:WaitForChild("LegPairAssembly"))
local RedrawSpawnSafety = require(script.Parent:WaitForChild("RedrawSpawnSafety"))
local RacerAntiStall = require(script.Parent:WaitForChild("RacerAntiStall"))
local RacerStabilizer = require(script.Parent:WaitForChild("RacerStabilizer"))

local BODY_SIZE = Vector3.new(3, 3, 3)

local RacerRuntime = {}
RacerRuntime.__index = RacerRuntime

type ShapeSpec = StrokeTypes.ShapeSpec

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

local function hubOffset(sideSign: number): Vector3
	local geometry = PhysicsConfig.LegGeometry
	return Vector3.new(
		geometry.HubOffsetX,
		geometry.HubOffsetY,
		geometry.HubOffsetZAbs * sideSign
	)
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

	makeHub("LeftHub", hubOffset(-1), body, template)
	makeHub("RightHub", hubOffset(1), body, template)

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

local function makeInternalShapeSpec(normalizedPoints: { Vector2 }): ShapeSpec
	local anchoredPoints = StrokeMath.AnchorToFirstPoint(normalizedPoints)
	local plan = GeometryMath.BuildSegmentPlan(anchoredPoints, PhysicsConfig.LegGeometry)
	assert(#plan.segmentPlan > 0, "internal shape produced no legal physical segments")
	local bounds = StrokeMath.ComputeBounds(anchoredPoints)
	assert(bounds ~= nil, "internal shape requires bounds")
	return {
		version = 0,
		normalizedPoints = anchoredPoints,
		mappedPoints = plan.mappedPoints,
		bounds = bounds,
		segmentPlan = plan.segmentPlan,
		extent = plan.extent,
		debugRawPointCount = #normalizedPoints,
		debugPhysicsPointCount = #plan.mappedPoints,
		debugId = string.format("internal-shape-p%d", #normalizedPoints),
	}
end

local function angularDistanceDegrees(a: number, b: number): number
	return math.abs((a - b + 180) % 360 - 180)
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
	model:SetAttribute("DebugRedrawSafetyFallback", false)
	model:SetAttribute("DebugRedrawPenetrationScore", 0)
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
	local antiStall = RacerAntiStall.new({
		racerModel = model,
		body = body,
	})

	local self = setmetatable({
		model = model,
		body = body,
		legPair = nil,
		leftLeg = nil,
		rightLeg = nil,
		stabilizer = stabilizer,
		antiStall = antiStall,
		currentShapeSpec = nil :: ShapeSpec?,
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

function RacerRuntime:GetAntiStall()
	assert(not self.destroyed and self.antiStall ~= nil, "RacerRuntime is destroyed")
	return self.antiStall
end

function RacerRuntime:GetLegPair()
	assert(not self.destroyed, "RacerRuntime is destroyed")
	return self.legPair
end

function RacerRuntime:GetShapeVersion(): number
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	local version = self.model:GetAttribute("ShapeVersion")
	if type(version) ~= "number" then
		return 0
	end
	return version
end

function RacerRuntime:GetCurrentShapeSpec(): ShapeSpec?
	assert(not self.destroyed, "RacerRuntime is destroyed")
	return self.currentShapeSpec
end

function RacerRuntime:_ApplyShapeSpec(shapeSpec: ShapeSpec, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table", "shapeSpec missing segmentPlan")
	assert(#shapeSpec.segmentPlan > 0, "shapeSpec requires physical segments")

	local model = self.model
	local legsFolder = model:FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"), "RacerRuntime missing Legs folder")

	local oldLegPair = self.legPair
	local initialPhaseDegrees = if oldLegPair ~= nil then oldLegPair:GetPhaseDegrees() else 0
	local selectedPhaseDegrees = initialPhaseDegrees
	local redrawSafetyFallback = false
	local redrawPenetrationScore = 0
	local stagedLegPair = nil

	local buildOk, buildError = pcall(function()
		stagedLegPair = LegPairAssembly.new({
			racerModel = model,
			shapeSpec = shapeSpec,
			motorEnabled = false,
			initialPhaseDegrees = initialPhaseDegrees,
			staged = true,
		})

		selectedPhaseDegrees, redrawSafetyFallback, redrawPenetrationScore = RedrawSpawnSafety.ChoosePhase(
			model,
			stagedLegPair,
			initialPhaseDegrees
		)

		if angularDistanceDegrees(selectedPhaseDegrees, initialPhaseDegrees) > 0.01 then
			stagedLegPair:Destroy()
			stagedLegPair = LegPairAssembly.new({
				racerModel = model,
				shapeSpec = shapeSpec,
				motorEnabled = false,
				initialPhaseDegrees = selectedPhaseDegrees,
				staged = true,
			})
		end
	end)

	if not buildOk then
		if stagedLegPair ~= nil then
			stagedLegPair:Destroy()
		end
		error(buildError)
	end
	assert(stagedLegPair ~= nil, "atomic redraw staging produced incomplete shared leg pair")

	-- Safety selection completes while the old pair is still active. Only now is
	-- the old pair marked retiring, so a selection/build error cannot remove the
	-- player's last working geometry.
	if oldLegPair ~= nil then
		oldLegPair:SetRetiring(true)
	end

	local commitOk, commitError = pcall(function()
		stagedLegPair:Commit()
		stagedLegPair:SetEnabled(motorEnabled == true)
	end)
	if not commitOk then
		stagedLegPair:Destroy()
		if oldLegPair ~= nil then
			oldLegPair:SetRetiring(false)
		end
		error(commitError)
	end

	self.legPair = stagedLegPair
	self.leftLeg = stagedLegPair:GetLeftLeg()
	self.rightLeg = stagedLegPair:GetRightLeg()
	model:SetAttribute("DebugRedrawSafetyFallback", redrawSafetyFallback)
	model:SetAttribute("DebugRedrawPenetrationScore", redrawPenetrationScore)

	if redrawSafetyFallback then
		warn(string.format(
			"[DrawRacers][RedrawSafety] no zero-penetration phase; selected %.1f deg score=%d",
			selectedPhaseDegrees,
			redrawPenetrationScore
		))
	end

	if oldLegPair ~= nil then
		oldLegPair:Destroy()
	end

	return self.leftLeg, self.rightLeg
end

function RacerRuntime:ApplyShape(normalizedPoints: { Vector2 }, motorEnabled: boolean?)
	assert(#normalizedPoints >= 2, "ApplyShape requires at least two normalized points")
	return self:_ApplyShapeSpec(makeInternalShapeSpec(normalizedPoints), motorEnabled)
end

function RacerRuntime:ApplyValidatedShape(shapeSpec: ShapeSpec, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "ApplyValidatedShape requires live RacerRuntime")
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
	if self.legPair then
		self.legPair:Destroy()
		self.legPair = nil
	end
	self.leftLeg = nil
	self.rightLeg = nil
	if self.antiStall then
		self.antiStall:Destroy()
		self.antiStall = nil
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
