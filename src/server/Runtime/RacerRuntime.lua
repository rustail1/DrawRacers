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
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegPairAssembly = require(script.Parent:WaitForChild("LegPairAssembly"))
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
	if RunService:IsStudio() then return true end
	local environment = game:GetAttribute("DrawRacersEnvironment")
	return environment == "DEV" or environment == "STAGING"
end

local function ensureRuntimeFolder(model: Model, name: string): Folder
	local existing = model:FindFirstChild(name)
	if existing and existing:IsA("Folder") then return existing end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = model
	return folder
end

local function publishSpawnAttributes(model: Model, params: SpawnParams, laneCenterZ: number)
	model:SetAttribute("RaceId", params.raceId)
	model:SetAttribute("SlotIndex", params.slotIndex)
	model:SetAttribute("LaneIndex", params.laneIndex)
	model:SetAttribute("IsBot", params.isBot)
	model:SetAttribute("ShapeVersion", 0)
	model:SetAttribute("DebugRawPoints", 0)
	model:SetAttribute("DebugSimplifiedPoints", 0)
	model:SetAttribute("DebugPhysicsPoints", 0)
	model:SetAttribute("DebugPairPhaseErrorDegrees", 0)
	model:SetAttribute("DebugDriveAngularVelocity", 0)
	model:SetAttribute("TrackId", params.trackId)
	model:SetAttribute("Finished", false)
	model:SetAttribute("LaneCenterZ", laneCenterZ)
end

local function publishValidatedShapeState(self: any, shapeSpec: ShapeSpec)
	self.currentShapeSpec = shapeSpec
	self.model:SetAttribute("ShapeVersion", shapeSpec.version)
	self.model:SetAttribute("DebugRawPoints", shapeSpec.debugRawPointCount or #shapeSpec.normalizedPoints)
	self.model:SetAttribute("DebugSimplifiedPoints", #shapeSpec.normalizedPoints)
	self.model:SetAttribute("DebugPhysicsPoints", shapeSpec.debugPhysicsPointCount or #shapeSpec.mappedPoints)
end

local function buildInternalShapeSpec(points: { Vector2 }, version: number): ShapeSpec
	local canonical, canonicalError = CanonicalLegShape.Build(points, PhysicsConfig.StrokeProcessing, PhysicsConfig.LegGeometry)
	assert(canonical ~= nil, canonicalError or "internal shape rejected")
	return {
		version = version,
		normalizedPoints = canonical.normalizedPoints,
		mappedPoints = canonical.mappedPoints,
		bounds = canonical.bounds,
		extent = canonical.extent,
		segmentPlan = canonical.segmentPlan,
		debugRawPointCount = canonical.debugRawPointCount,
		debugPhysicsPointCount = canonical.debugPhysicsPointCount,
		debugId = string.format("internal-shape-v%d-p%d", version, #points),
	}
end

function RacerRuntime.EnsureTemplate(): Model
	CollisionGroups.ensure()
	local templatesRoot = ServerStorage:WaitForChild("RacerTemplates")
	local existing = templatesRoot:FindFirstChild("RacerTemplate")
	if existing and existing:IsA("Model") then return existing end

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

function RacerRuntime.new(params: SpawnParams)
	assert(params.slotIndex >= 1 and params.slotIndex <= 8, "slotIndex must be 1..8")
	assert(params.laneIndex >= 1 and params.laneIndex <= 8, "laneIndex must be 1..8")
	local template = RacerRuntime.EnsureTemplate()
	local racersRoot = Workspace:WaitForChild("Runtime"):WaitForChild("Racers")
	local laneCenterZ = params.laneCenterZ or params.spawnCFrame.Position.Z
	local model = template:Clone()
	model.Name = string.format("Racer_%s_%d", params.raceId, params.slotIndex)
	local body = model:FindFirstChild("BodyCollider")
	assert(body and body:IsA("Part"), "RacerTemplate missing BodyCollider")
	model.PrimaryPart = body
	ensureRuntimeFolder(model, "Legs")
	ensureRuntimeFolder(model, "Presentation")
	if debugEnvironmentAllowed() then ensureRuntimeFolder(model, "Debug") end
	publishSpawnAttributes(model, params, laneCenterZ)
	model:PivotTo(params.spawnCFrame)
	model.Parent = racersRoot

	local stabilizer = RacerStabilizer.new({ racerModel = model, body = body, laneCenterZ = laneCenterZ })
	local antiStall = RacerAntiStall.new({ racerModel = model, body = body })
	return setmetatable({
		model = model,
		body = body,
		legPair = nil,
		stabilizer = stabilizer,
		antiStall = antiStall,
		currentShapeSpec = nil :: ShapeSpec?,
		_redrawPending = false,
		_transactionGeneration = 0,
		destroyed = false,
	}, RacerRuntime)
end

function RacerRuntime:GetModel(): Model
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	return self.model
end
function RacerRuntime:GetBody(): Part
	assert(not self.destroyed and self.body ~= nil, "RacerRuntime is destroyed")
	return self.body
end
function RacerRuntime:GetStabilizer() return self.stabilizer end
function RacerRuntime:GetAntiStall() return self.antiStall end
function RacerRuntime:GetLegPair() return self.legPair end
function RacerRuntime:GetShapeVersion(): number
	local version = self.model:GetAttribute("ShapeVersion")
	return if type(version) == "number" then version else 0
end
function RacerRuntime:GetCurrentShapeSpec(): ShapeSpec? return self.currentShapeSpec end
function RacerRuntime:IsRedrawPending(): boolean return self._redrawPending end

function RacerRuntime:_cancelPendingRedraw()
	self._transactionGeneration += 1
	self._redrawPending = false
	if self.legPair ~= nil then self.legPair:CancelStagedRedraw() end
end

function RacerRuntime:PrepareForRecovery()
	assert(not self.destroyed, "PrepareForRecovery requires live RacerRuntime")
	self:_cancelPendingRedraw()
	if self.legPair ~= nil then self.legPair:PrepareForRecovery() end
end

function RacerRuntime:ApplyShape(normalizedPoints: { Vector2 }, motorEnabled: boolean?)
	local spec = buildInternalShapeSpec(normalizedPoints, self:GetShapeVersion() + 1)
	local result = self:ApplyValidatedShape(spec, motorEnabled)
	assert(result.accepted == true, result.rejectReasonCode or "internal shape apply failed")
	return self.legPair:GetLeftLeg(), self.legPair:GetRightLeg()
end

function RacerRuntime:ApplyValidatedShape(shapeSpec: ShapeSpec, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "ApplyValidatedShape requires live RacerRuntime")
	assert(type(shapeSpec) == "table" and type(shapeSpec.version) == "number", "invalid ShapeSpec")
	assert(shapeSpec.version == self:GetShapeVersion() + 1, "ShapeSpec version must increment by exactly one")
	if self._redrawPending then
		return { accepted = false, rejectReasonCode = "REDRAW_PENDING" }
	end

	if self.legPair == nil then
		local ok, pairOrError = pcall(function()
			return LegPairAssembly.new({
				racerModel = self.model,
				shapeSpec = shapeSpec,
				motorEnabled = motorEnabled == true,
				initialPhaseDegrees = 0,
			})
		end)
		if not ok then
			warn("[DrawRacers][CR2] initial twin-drive build failed: " .. tostring(pairOrError))
			return { accepted = false, rejectReasonCode = "NO_SAFE_REDRAW_PHASE" }
		end
		self.legPair = pairOrError
		publishValidatedShapeState(self, shapeSpec)
		return { accepted = true }
	end

	self._redrawPending = true
	self._transactionGeneration += 1
	local generation = self._transactionGeneration
	local staged, stageError = self.legPair:StageRedraw(shapeSpec)
	if not staged then
		self._redrawPending = false
		return { accepted = false, rejectReasonCode = stageError or "NO_SAFE_REDRAW_PHASE" }
	end

	local reshape = PhysicsConfig.LegReshape
	local duration = math.clamp(reshape.TypicalDuration, reshape.MinimumDuration, reshape.MaximumDuration)
	local steps = 3
	for step = 1, steps do
		if self.destroyed or generation ~= self._transactionGeneration then
			if self.legPair ~= nil then self.legPair:CancelStagedRedraw() end
			self._redrawPending = false
			return { accepted = false, rejectReasonCode = "REDRAW_CANCELLED" }
		end
		self.legPair:SetStageProgress(step / steps)
		task.wait(duration / steps)
	end

	local committed, commitError = self.legPair:CommitStagedRedraw()
	if not committed then
		self._redrawPending = false
		return { accepted = false, rejectReasonCode = commitError or "NO_SAFE_REDRAW_PHASE" }
	end
	self.legPair:SetEnabled(motorEnabled == true)
	publishValidatedShapeState(self, shapeSpec)
	self._redrawPending = false
	return { accepted = true }
end

function RacerRuntime:IsDestroyed(): boolean return self.destroyed end

function RacerRuntime:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	self:_cancelPendingRedraw()
	if self.legPair then self.legPair:Destroy() end
	if self.antiStall then self.antiStall:Destroy() end
	if self.stabilizer then self.stabilizer:Destroy() end
	if self.model then self.model:Destroy() end
	self.legPair = nil
	self.antiStall = nil
	self.stabilizer = nil
	self.model = nil
	self.body = nil
	self.currentShapeSpec = nil
end

return RacerRuntime
