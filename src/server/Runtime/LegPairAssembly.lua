--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local LegDriveMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("LegDriveMath")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)

local LegAssembly = require(script.Parent:WaitForChild("LegAssembly"))
local LegDriveAssembly = require(script.Parent:WaitForChild("LegDriveAssembly"))

local STATE_ACTIVE = "ACTIVE"
local STATE_REBUILD = "REBUILD"

local FLOAT_ATTACHMENT_NAME = "BodyFloatAttachment"
local FLOAT_FORCE_NAME = "BodyFloatForce"

local LegPairAssembly = {}
LegPairAssembly.__index = LegPairAssembly

type ShapeSpec = StrokeTypes.ShapeSpec

export type BuildParams = {
	racerModel: Model,
	shapeSpec: ShapeSpec,
	motorEnabled: boolean?,
	initialPhaseDegrees: number?,
}

local function validateShapeSpec(shapeSpec: ShapeSpec)
	assert(type(shapeSpec) == "table", "shapeSpec required")
	assert(
		type(shapeSpec.segmentPlan) == "table" and #shapeSpec.segmentPlan > 0,
		"shapeSpec missing segmentPlan"
	)
end

local function ensureFloatAttachment(body: Part): Attachment
	local existing = body:FindFirstChild(FLOAT_ATTACHMENT_NAME)
	if existing ~= nil and not existing:IsA("Attachment") then
		existing:Destroy()
		existing = nil
	end

	local attachment = existing :: Attachment?
	if attachment == nil then
		attachment = Instance.new("Attachment")
		attachment.Name = FLOAT_ATTACHMENT_NAME
		attachment.Parent = body
	end
	return attachment
end

local function ensureFloatForce(body: Part, attachment: Attachment): VectorForce
	local existing = body:FindFirstChild(FLOAT_FORCE_NAME)
	if existing ~= nil and not existing:IsA("VectorForce") then
		existing:Destroy()
		existing = nil
	end

	local force = existing :: VectorForce?
	if force == nil then
		force = Instance.new("VectorForce")
		force.Name = FLOAT_FORCE_NAME
		force.Parent = body
	end

	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	return force
end

local function configureBody(body: Part)
	local material = PhysicsConfig.PhysicalMaterials.Body
	body.CustomPhysicalProperties = PhysicalProperties.new(
		material.Density,
		material.Friction,
		material.Elasticity,
		material.FrictionWeight,
		material.ElasticityWeight
	)
end

local function applyRedrawHop(body: Part)
	if body.Anchored then
		return
	end

	local dynamics = PhysicsConfig.BodyDynamics
	local velocity = body.AssemblyLinearVelocity
	local target = math.max(0, dynamics.RedrawHopTargetVelocity)
	if velocity.Y >= target then
		return
	end

	local delta = math.min(
		target - velocity.Y,
		math.max(0, dynamics.RedrawHopMaxDeltaVelocity)
	)
	if delta <= 0 then
		return
	end

	body:ApplyImpulse(Vector3.new(
		0,
		body.AssemblyMass * delta,
		0
	))
end

function LegPairAssembly.new(params: BuildParams)
	validateShapeSpec(params.shapeSpec)

	local racerModel = params.racerModel
	local body = racerModel:FindFirstChild("BodyCollider")
	local legsFolder = racerModel:FindFirstChild("Legs")

	assert(body and body:IsA("Part"), "racerModel missing BodyCollider")
	assert(legsFolder and legsFolder:IsA("Folder"), "racerModel missing Legs")

	configureBody(body)

	local floatAttachment = ensureFloatAttachment(body)
	local floatForce = ensureFloatForce(body, floatAttachment)

	local drive = LegDriveAssembly.new({
		body = body,
		container = legsFolder,
		initialPhaseDegrees = params.initialPhaseDegrees or 0,
	})

	local leftLeg = LegAssembly.new({
		container = drive:GetModel(),
		side = "Left",
		driveRoot = drive:GetLeftRoot(),
	})

	local rightLeg = LegAssembly.new({
		container = drive:GetModel(),
		side = "Right",
		driveRoot = drive:GetRightRoot(),
	})

	local self = setmetatable({
		racerModel = racerModel,
		body = body,
		drive = drive,
		leftLeg = leftLeg,
		rightLeg = rightLeg,

		floatAttachment = floatAttachment,
		floatForce = floatForce,

		state = STATE_ACTIVE,
		currentShapeSpec = params.shapeSpec,
		stagedShapeSpec = nil :: ShapeSpec?,
		rebuildStartedAt = 0,

		motorEnabled = params.motorEnabled == true,
		stepConnection = nil :: RBXScriptConnection?,
		destroyed = false,
	}, LegPairAssembly)

	-- Never teleport the racer to make a leg fit. Initial colliders are installed
	-- disabled and become live segment-by-segment once clear of Track.
	leftLeg:InstallGeometryDeferred(params.shapeSpec)
	rightLeg:InstallGeometryDeferred(params.shapeSpec)

	self.stepConnection = RunService.Heartbeat:Connect(function()
		self:Step()
	end)

	self:_UpdateFloatForce()
	self:_ApplyMotorState()
	return self
end

function LegPairAssembly:_UpdateFloatForce()
	if self.destroyed or self.body == nil or self.floatForce == nil then
		return
	end

	-- Anchored Studio/spec bodies can report non-physical/infinite assembly mass.
	-- Never feed that into VectorForce.
	if self.body.Anchored then
		self.floatForce.Force = Vector3.zero
		return
	end

	local gravityScale = math.clamp(
		PhysicsConfig.BodyDynamics.GravityScale,
		0,
		1
	)
	local compensation = 1 - gravityScale

	-- Recomputed continuously from current AssemblyMass. This keeps the float
	-- behavior correct even if another runtime system changes assembly mass.
	self.floatForce.Force = Vector3.new(
		0,
		self.body.AssemblyMass * Workspace.Gravity * compensation,
		0
	)
end

function LegPairAssembly:_UpdatePreview()
	if self.state ~= STATE_REBUILD or self.stagedShapeSpec == nil then
		return
	end

	local reshape = PhysicsConfig.LegReshape
	local duration = math.clamp(
		reshape.TypicalDuration,
		reshape.MinimumDuration,
		reshape.MaximumDuration
	)
	local progress = math.clamp(
		(os.clock() - self.rebuildStartedAt) / math.max(duration, 1e-4),
		0,
		1
	)

	self.leftLeg:SetPreviewProgress(progress)
	self.rightLeg:SetPreviewProgress(progress)
end

function LegPairAssembly:_UpdateMotorVelocity()
	if self.currentShapeSpec == nil then
		return
	end

	local omega = LegDriveMath.ComputeAngularVelocity(
		self.currentShapeSpec.extent,
		PhysicsConfig.Motor
	)
	self.drive:SetMotorVelocity(omega)
	self.racerModel:SetAttribute("DebugPairPhaseErrorDegrees", 0)
	self.racerModel:SetAttribute("DebugDriveAngularVelocity", omega)
end

function LegPairAssembly:_ApplyMotorState()
	local enabled = self.motorEnabled and self.state == STATE_ACTIVE
	self.drive:SetEnabled(enabled)
	if enabled then
		self:_UpdateMotorVelocity()
	end
end

function LegPairAssembly:_RestoreCurrentGeometry()
	self.leftLeg:CancelPreview()
	self.rightLeg:CancelPreview()
	self.leftLeg:AbortPreparedGeometry()
	self.rightLeg:AbortPreparedGeometry()

	self.leftLeg:ClearCurrentGeometry()
	self.rightLeg:ClearCurrentGeometry()

	if self.currentShapeSpec ~= nil then
		self.leftLeg:InstallGeometryDeferred(self.currentShapeSpec)
		self.rightLeg:InstallGeometryDeferred(self.currentShapeSpec)
	end
end

function LegPairAssembly:GetDrive()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.drive
end

function LegPairAssembly:GetLeftLeg()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.leftLeg
end

function LegPairAssembly:GetRightLeg()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.rightLeg
end

function LegPairAssembly:GetPhaseErrorDegrees(): number
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return 0
end

function LegPairAssembly:Step()
	if self.destroyed then
		return
	end

	self:_UpdateFloatForce()

	if self.state == STATE_REBUILD then
		self:_UpdatePreview()
	else
		self:_UpdateMotorVelocity()
	end

	-- Final geometry is allowed to rotate while collision is disabled. Each
	-- segment becomes collidable exactly once, after it is clear of Track.
	self.leftLeg:ActivateClearColliders()
	self.rightLeg:ActivateClearColliders()
end

function LegPairAssembly:StageRedraw(
	shapeSpec: ShapeSpec
): (boolean, string?)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	validateShapeSpec(shapeSpec)

	if self.state == STATE_REBUILD then
		return false, "REDRAW_PENDING"
	end

	self.state = STATE_REBUILD
	self.stagedShapeSpec = shapeSpec
	self.rebuildStartedAt = os.clock()

	-- Reference sequence:
	-- motor OFF -> old legs gone -> small hop -> visual-only growth.
	self.drive:SetEnabled(false)
	self.leftLeg:ClearCurrentGeometry()
	self.rightLeg:ClearCurrentGeometry()

	applyRedrawHop(self.body)

	self.leftLeg:BeginPreview(shapeSpec)
	self.rightLeg:BeginPreview(shapeSpec)
	self.leftLeg:SetPreviewProgress(0)
	self.rightLeg:SetPreviewProgress(0)

	return true, nil
end

function LegPairAssembly:IsStagedRedrawReady(): boolean
	assert(not self.destroyed, "LegPairAssembly is destroyed")

	if self.state ~= STATE_REBUILD or self.stagedShapeSpec == nil then
		return false
	end

	self:_UpdatePreview()

	local reshape = PhysicsConfig.LegReshape
	local duration = math.clamp(
		reshape.TypicalDuration,
		reshape.MinimumDuration,
		reshape.MaximumDuration
	)

	return os.clock() - self.rebuildStartedAt >= duration
end

function LegPairAssembly:CommitStagedRedraw(): (boolean, string?)
	assert(not self.destroyed, "LegPairAssembly is destroyed")

	local shapeSpec = self.stagedShapeSpec
	if self.state ~= STATE_REBUILD or shapeSpec == nil then
		return false, "NO_PENDING_REDRAW"
	end

	self.leftLeg:SetPreviewProgress(1)
	self.rightLeg:SetPreviewProgress(1)

	-- Never reposition the body for redraw clearance. Build the complete final
	-- shape with collision OFF; the shared motor will rotate embedded segments
	-- out of Track before they are individually enabled.
	local leftPrepared = self.leftLeg:PrepareFinalGeometry(shapeSpec)
	local rightPrepared = self.rightLeg:PrepareFinalGeometry(shapeSpec)

	if not leftPrepared or not rightPrepared then
		self.leftLeg:AbortPreparedGeometry()
		self.rightLeg:AbortPreparedGeometry()
		self:_RestoreCurrentGeometry()

		self.stagedShapeSpec = nil
		self.state = STATE_ACTIVE
		self:_ApplyMotorState()
		return false, "BUILD_FAILED"
	end

	-- Both full geometries already exist with collision OFF. Publish them
	-- back-to-back without yielding; collider activation is deferred per segment.
	local leftActivated = self.leftLeg:ActivatePreparedGeometryDeferred()
	local rightActivated = self.rightLeg:ActivatePreparedGeometryDeferred()

	if not leftActivated or not rightActivated then
		self:_RestoreCurrentGeometry()

		self.stagedShapeSpec = nil
		self.state = STATE_ACTIVE
		self:_ApplyMotorState()
		return false, "BUILD_FAILED"
	end

	self.currentShapeSpec = shapeSpec
	self.stagedShapeSpec = nil
	self.state = STATE_ACTIVE

	self:_UpdateFloatForce()
	self:_ApplyMotorState()
	return true, nil
end

function LegPairAssembly:CancelStagedRedraw()
	if self.destroyed then
		return
	end
	if self.state ~= STATE_REBUILD then
		return
	end

	self:_RestoreCurrentGeometry()
	self.stagedShapeSpec = nil
	self.state = STATE_ACTIVE
	self:_UpdateFloatForce()
	self:_ApplyMotorState()
end

function LegPairAssembly:PrepareForRecovery()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self:CancelStagedRedraw()
end

function LegPairAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self.motorEnabled = enabled
	self:_ApplyMotorState()
end

function LegPairAssembly:Destroy()
	if self.destroyed then
		return
	end

	if self.state == STATE_REBUILD then
		self:CancelStagedRedraw()
	end

	self.destroyed = true

	if self.stepConnection then
		self.stepConnection:Disconnect()
	end
	if self.leftLeg then
		self.leftLeg:Destroy()
	end
	if self.rightLeg then
		self.rightLeg:Destroy()
	end
	if self.drive then
		self.drive:Destroy()
	end

	if self.floatForce then
		self.floatForce:Destroy()
	end
	if self.floatAttachment then
		self.floatAttachment:Destroy()
	end

	self.stepConnection = nil
	self.leftLeg = nil
	self.rightLeg = nil
	self.drive = nil
	self.floatForce = nil
	self.floatAttachment = nil
	self.body = nil
	self.racerModel = nil
	self.currentShapeSpec = nil
	self.stagedShapeSpec = nil
end

return LegPairAssembly
