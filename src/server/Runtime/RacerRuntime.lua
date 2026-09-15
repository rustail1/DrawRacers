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
local LegCoreController = require(script.Parent:WaitForChild("CoreV3"):WaitForChild("LegCoreController"))

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
	model:SetAttribute("CoreV3Validation", true)
	model:SetAttribute("AntiStallActive", false)
end

local function makeInternalShapeSpec(normalizedPoints: { Vector2 }, version: number): ShapeSpec
	local canonical, canonicalError = CanonicalLegShape.Build(
		normalizedPoints,
		PhysicsConfig.StrokeProcessing,
		PhysicsConfig.LegGeometry
	)
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
		debugId = string.format("internal-shape-v%d-p%d", version, #normalizedPoints),
	}
end

local function publishValidatedShapeState(self: any, shapeSpec: ShapeSpec)
	self.currentShapeSpec = shapeSpec
	self.model:SetAttribute("ShapeVersion", shapeSpec.version)
	self.model:SetAttribute("DebugRawPoints", shapeSpec.debugRawPointCount or #shapeSpec.normalizedPoints)
	self.model:SetAttribute("DebugSimplifiedPoints", #shapeSpec.normalizedPoints)
	self.model:SetAttribute("DebugPhysicsPoints", shapeSpec.debugPhysicsPointCount or #shapeSpec.mappedPoints)
end

local function clearActiveShapeState(self: any)
	self.currentShapeSpec = nil
	self.model:SetAttribute("DebugRawPoints", 0)
	self.model:SetAttribute("DebugSimplifiedPoints", 0)
	self.model:SetAttribute("DebugPhysicsPoints", 0)
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
	local bodyMaterial = PhysicsConfig.PhysicalMaterials.Body
	body.CustomPhysicalProperties = PhysicalProperties.new(
		bodyMaterial.Density,
		bodyMaterial.Friction,
		bodyMaterial.Elasticity,
		bodyMaterial.FrictionWeight,
		bodyMaterial.ElasticityWeight
	)
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
	assert(params.raceId ~= "", "raceId must not be empty")
	assert(params.trackId ~= "", "trackId must not be empty")

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
	if debugEnvironmentAllowed() then
		ensureRuntimeFolder(model, "Debug")
	end
	publishSpawnAttributes(model, params, laneCenterZ)
	body.CFrame = params.spawnCFrame
	model.Parent = racersRoot

	return setmetatable({
		model = model,
		body = body,
		legCore = nil :: any?,
		currentShapeSpec = nil :: ShapeSpec?,
		destroyed = false,
	}, RacerRuntime)
end

function RacerRuntime:_EnsureLegCore()
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	if self.legCore == nil then
		self.legCore = LegCoreController.new(self.model)
	end
	return self.legCore
end

function RacerRuntime:GetModel(): Model
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	return self.model
end

function RacerRuntime:GetBody(): Part
	assert(not self.destroyed and self.body ~= nil, "RacerRuntime is destroyed")
	return self.body
end

function RacerRuntime:GetLegCore()
	assert(not self.destroyed, "RacerRuntime is destroyed")
	return self.legCore
end

function RacerRuntime:GetShapeVersion(): number
	assert(not self.destroyed and self.model ~= nil, "RacerRuntime is destroyed")
	local version = self.model:GetAttribute("ShapeVersion")
	return if type(version) == "number" then version else 0
end

function RacerRuntime:GetCurrentShapeSpec(): ShapeSpec?
	assert(not self.destroyed, "RacerRuntime is destroyed")
	return self.currentShapeSpec
end

function RacerRuntime:IsRedrawPending(): boolean
	if self.destroyed or self.legCore == nil then
		return false
	end
	local state = self.legCore:GetState()
	return state == "PREVIEW" or state == "WAIT_CLEAR"
end

function RacerRuntime:SetMotorEnabled(enabled: boolean)
	assert(not self.destroyed, "SetMotorEnabled requires live RacerRuntime")
	assert(type(enabled) == "boolean", "enabled must be boolean")
	if self.legCore ~= nil then
		self.legCore:SetMotorEnabled(enabled)
	end
end

function RacerRuntime:PrepareForRecovery()
	assert(not self.destroyed, "PrepareForRecovery requires live RacerRuntime")
	if self.legCore ~= nil then
		self.legCore:PrepareForRecovery()
	end
end

function RacerRuntime:ApplyShape(normalizedPoints: { Vector2 }, motorEnabled: boolean?)
	assert(#normalizedPoints >= 2, "ApplyShape requires at least two normalized points")
	local shapeSpec = makeInternalShapeSpec(normalizedPoints, self:GetShapeVersion() + 1)
	local result = self:ApplyValidatedShape(shapeSpec, motorEnabled)
	assert(result.accepted == true, result.rejectReasonCode or "internal shape apply failed")
	local core = self:GetLegCore()
	assert(core ~= nil, "accepted shape missing Core V3 controller")
	return core:GetLeftLeg(), core:GetRightLeg()
end

function RacerRuntime:ApplyValidatedShape(shapeSpec: ShapeSpec, motorEnabled: boolean?)
	assert(not self.destroyed and self.model ~= nil, "ApplyValidatedShape requires live RacerRuntime")
	assert(type(shapeSpec) == "table" and type(shapeSpec.version) == "number", "invalid ShapeSpec")
	assert(shapeSpec.version == self:GetShapeVersion() + 1, "ShapeSpec version must increment by exactly one")
	if self:IsRedrawPending() then
		return { accepted = false, rejectReasonCode = "REDRAW_PENDING" }
	end

	local hadAcceptedShape = self.currentShapeSpec ~= nil
	local applied, acceptedOrError, reasonOrNil = pcall(function()
		self:_EnsureLegCore()
		return self.legCore:ApplyShape(shapeSpec, motorEnabled == true)
	end)
	if not applied then
		warn("[DrawRacers][CoreV3] mechanical apply failed: " .. tostring(acceptedOrError))
		local invalidatedAccepted = hadAcceptedShape
			and self.legCore ~= nil
			and self.legCore:GetState() == "EMPTY"
		if invalidatedAccepted then
			clearActiveShapeState(self)
		end
		return {
			accepted = false,
			rejectReasonCode = "BUILD_FAILED",
			clearAccepted = invalidatedAccepted,
		}
	end
	if acceptedOrError ~= true then
		local invalidatedAccepted = hadAcceptedShape
			and self.legCore ~= nil
			and self.legCore:GetState() == "EMPTY"
		if invalidatedAccepted then
			clearActiveShapeState(self)
		end
		return {
			accepted = false,
			rejectReasonCode = reasonOrNil or "BUILD_FAILED",
			clearAccepted = invalidatedAccepted,
		}
	end

	-- Core V3 is fail-closed: the previous pair is destroyed as soon as the new
	-- rebuild starts. From this point until ACTIVE there is intentionally no
	-- accepted physical shape. Keep the old ShapeVersion as history, but clear
	-- the active ShapeSpec so server/client presentation cannot claim otherwise.
	clearActiveShapeState(self)

	local waited, committedOrError, mechanicalReason = pcall(function()
		return self.legCore:WaitForRebuildResult()
	end)
	if not waited then
		warn("[DrawRacers][CoreV3] mechanical completion wait failed: " .. tostring(committedOrError))
		self.legCore:PrepareForRecovery()
		clearActiveShapeState(self)
		return {
			accepted = false,
			rejectReasonCode = "BUILD_FAILED",
			clearAccepted = hadAcceptedShape,
		}
	end
	if committedOrError ~= true then
		clearActiveShapeState(self)
		return {
			accepted = false,
			rejectReasonCode = mechanicalReason or "BUILD_FAILED",
			clearAccepted = hadAcceptedShape,
		}
	end

	publishValidatedShapeState(self, shapeSpec)
	return { accepted = true }
end

function RacerRuntime:IsDestroyed(): boolean
	return self.destroyed
end

function RacerRuntime:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.legCore ~= nil then
		self.legCore:Destroy()
	end
	if self.model ~= nil then
		self.model:Destroy()
	end
	self.legCore = nil
	self.model = nil
	self.body = nil
	self.currentShapeSpec = nil
end

return RacerRuntime
