--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegAssembly = require(script.Parent:WaitForChild("LegAssembly"))

local RACER_LEG_GROUP = "RacerLeg"

local LegPairAssembly = {}
LegPairAssembly.__index = LegPairAssembly

type ShapeSpec = StrokeTypes.ShapeSpec

export type BuildParams = {
	racerModel: Model,
	shapeSpec: ShapeSpec,
	motorEnabled: boolean?,
	initialPhaseDegrees: number?,
}

type LegBuildParams = {
	container: Instance,
	axleRoot: Part,
	shapeSpec: ShapeSpec,
	side: string,
	socketZ: number,
	phaseDegrees: number,
}

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function ensureBodyAttachment(body: Part): Attachment
	local existing = body:FindFirstChild("AxleMotorAttachment")
	if existing and existing:IsA("Attachment") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local geometry = PhysicsConfig.LegGeometry
	local attachment = Instance.new("Attachment")
	attachment.Name = "AxleMotorAttachment"
	attachment.Position = Vector3.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)
	attachment.Axis = Vector3.zAxis
	attachment.SecondaryAxis = Vector3.yAxis
	attachment.Parent = body
	return attachment
end

local function axleBaseCFrame(body: Part): CFrame
	local geometry = PhysicsConfig.LegGeometry
	return body.CFrame * CFrame.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)
end

local function buildLeg(params: LegBuildParams)
	local leg = LegAssembly.new({
		container = params.container,
		side = params.side,
		axleRoot = params.axleRoot,
		socketZ = params.socketZ,
		phaseDegrees = params.phaseDegrees,
	})
	leg:ReplaceGeometry(params.shapeSpec)
	leg:CompleteReshape()
	return leg
end

function LegPairAssembly.new(params: BuildParams)
	assert(type(params.shapeSpec) == "table", "LegPairAssembly requires authoritative shapeSpec")
	assert(
		type(params.shapeSpec.segmentPlan) == "table" and #params.shapeSpec.segmentPlan > 0,
		"shapeSpec missing physical segmentPlan"
	)
	CollisionGroups.ensure()

	local racerModel = params.racerModel
	local body = racerModel:FindFirstChild("BodyCollider")
	local legsFolder = racerModel:FindFirstChild("Legs")
	assert(body and body:IsA("Part"), "racerModel missing BodyCollider")
	assert(legsFolder and legsFolder:IsA("Folder"), "racerModel missing Legs folder")

	local geometry = PhysicsConfig.LegGeometry
	local motor = PhysicsConfig.Motor
	local initialPhaseDegrees = params.initialPhaseDegrees or 0
	assert(type(initialPhaseDegrees) == "number" and isFiniteNumber(initialPhaseDegrees), "initial phase must be finite")
	local bodyAttachment = ensureBodyAttachment(body)

	local axleRoot = Instance.new("Part")
	axleRoot.Name = "AxleRoot"
	axleRoot.Size = Vector3.new(0.2, 0.2, 0.2)
	axleRoot.CFrame = axleBaseCFrame(body) * CFrame.Angles(0, 0, math.rad(initialPhaseDegrees))
	axleRoot.Anchored = false
	axleRoot.CanCollide = false
	axleRoot.CanTouch = false
	axleRoot.CanQuery = false
	axleRoot.Transparency = 1
	axleRoot.Massless = true
	axleRoot.CollisionGroup = RACER_LEG_GROUP
	axleRoot.Parent = legsFolder

	local axleAttachment = Instance.new("Attachment")
	axleAttachment.Name = "MotorAttachment"
	axleAttachment.Axis = Vector3.zAxis
	axleAttachment.SecondaryAxis = Vector3.yAxis
	axleAttachment.Parent = axleRoot

	local joint = Instance.new("HingeConstraint")
	joint.Name = "AxleJoint"
	joint.Attachment0 = bodyAttachment
	joint.Attachment1 = axleAttachment
	joint.ActuatorType = Enum.ActuatorType.Motor
	joint.AngularVelocity = motor.AngularVelocity
	joint.MotorMaxTorque = motor.MotorMaxTorque
	joint.MotorMaxAcceleration = motor.MotorMaxAcceleration
	joint.Enabled = false
	joint.Parent = axleRoot

	local reshapeSupportAttachment = Instance.new("Attachment")
	reshapeSupportAttachment.Name = "ReshapeSupportAttachment"
	reshapeSupportAttachment.Parent = body

	local reshapeSupportForce = Instance.new("VectorForce")
	reshapeSupportForce.Name = "ReshapeSupportForce"
	reshapeSupportForce.Attachment0 = reshapeSupportAttachment
	reshapeSupportForce.ApplyAtCenterOfMass = true
	reshapeSupportForce.RelativeTo = Enum.ActuatorRelativeTo.World
	reshapeSupportForce.Force = Vector3.zero
	reshapeSupportForce.Enabled = false
	reshapeSupportForce.Parent = body

	local leftLeg = nil
	local rightLeg = nil
	local sideBuildOk, sideBuildError = pcall(function()
		leftLeg = buildLeg({
			container = legsFolder,
			axleRoot = axleRoot,
			shapeSpec = params.shapeSpec,
			side = "Left",
			socketZ = -geometry.LegSocketZAbs,
			phaseDegrees = 0,
		})
		rightLeg = buildLeg({
			container = legsFolder,
			axleRoot = axleRoot,
			shapeSpec = params.shapeSpec,
			side = "Right",
			socketZ = geometry.LegSocketZAbs,
			phaseDegrees = motor.RightPhaseOffsetDegrees,
		})
	end)
	if not sideBuildOk then
		if leftLeg ~= nil then leftLeg:Destroy() end
		if rightLeg ~= nil then rightLeg:Destroy() end
		reshapeSupportForce:Destroy()
		reshapeSupportAttachment:Destroy()
		axleRoot:Destroy()
		error(sideBuildError)
	end
	assert(leftLeg ~= nil and rightLeg ~= nil, "LegPairAssembly produced incomplete rigid sides")

	local self = setmetatable({
		racerModel = racerModel,
		body = body,
		legsFolder = legsFolder,
		axleRoot = axleRoot,
		joint = joint,
		leftLeg = leftLeg,
		rightLeg = rightLeg,
		reshapeSupportAttachment = reshapeSupportAttachment,
		reshapeSupportForce = reshapeSupportForce,
		reshapeForcedComplete = false,
		initialPhaseDegrees = initialPhaseDegrees,
		motorEverEnabled = false,
		destroyed = false,
	}, LegPairAssembly)

	if params.motorEnabled == true then
		self:SetEnabled(true)
	end
	return self
end

function LegPairAssembly:GetRoot(): Part
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.axleRoot
end

function LegPairAssembly:GetJoint(): HingeConstraint
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.joint
end

function LegPairAssembly:GetLeftLeg()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.leftLeg
end

function LegPairAssembly:GetRightLeg()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.rightLeg
end

function LegPairAssembly:GetPhaseDegrees(): number
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	local relative = axleBaseCFrame(self.body):ToObjectSpace(self.axleRoot.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
end

function LegPairAssembly:SetInitialPhaseDegrees(phaseDegrees: number)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	assert(type(phaseDegrees) == "number" and isFiniteNumber(phaseDegrees), "initial phase must be finite")
	assert(not self.motorEverEnabled, "initial phase is locked after motor activation")
	assert(not self.joint.Enabled, "initial phase requires disabled motor")
	self.initialPhaseDegrees = phaseDegrees
	self.axleRoot.CFrame = axleBaseCFrame(self.body) * CFrame.Angles(0, 0, math.rad(phaseDegrees))
end

function LegPairAssembly:_SetReshapeSupportEnabled(enabled: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	local force = self.reshapeSupportForce
	if not enabled then
		force.Force = Vector3.zero
		force.Enabled = false
		return
	end

	local fraction = math.clamp(PhysicsConfig.LegReshape.GravityCompensationFraction or 0, 0, 1)
	if fraction <= 0 then
		force.Force = Vector3.zero
		force.Enabled = false
		return
	end

	local supportedMass = self.body.AssemblyMass + self.axleRoot.AssemblyMass
	force.Force = Vector3.new(0, supportedMass * Workspace.Gravity * fraction, 0)
	force.Enabled = true
end

function LegPairAssembly:BeginGeometryReshape(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	assert(
		type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table" and #shapeSpec.segmentPlan > 0,
		"shapeSpec missing physical segmentPlan"
	)

	self.reshapeForcedComplete = false
	self:_SetReshapeSupportEnabled(true)
	self.leftLeg:ReplaceGeometry(shapeSpec)
	self.rightLeg:ReplaceGeometry(shapeSpec)
	self.leftLeg:SetReshapeProgress(0)
	self.rightLeg:SetReshapeProgress(0)
	return self.leftLeg, self.rightLeg
end

function LegPairAssembly:SetReshapeProgress(progress: number)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	local effectiveProgress = if self.reshapeForcedComplete then 1 else math.clamp(progress, 0, 1)
	if self.reshapeSupportForce.Enabled then
		self:_SetReshapeSupportEnabled(true)
	end
	self.leftLeg:SetReshapeProgress(effectiveProgress)
	self.rightLeg:SetReshapeProgress(effectiveProgress)
	if effectiveProgress >= 1 then
		self:_SetReshapeSupportEnabled(false)
	end
end

function LegPairAssembly:CompleteReshapeForRecovery()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self.reshapeForcedComplete = true
	self:SetReshapeProgress(1)
end

function LegPairAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	if enabled then
		self.motorEverEnabled = true
	end
	self.joint.Enabled = enabled
end

function LegPairAssembly:Destroy()
	if self.destroyed then
		return
	end
	self:_SetReshapeSupportEnabled(false)
	self.destroyed = true
	if self.leftLeg then self.leftLeg:Destroy() end
	if self.rightLeg then self.rightLeg:Destroy() end
	if self.reshapeSupportForce then self.reshapeSupportForce:Destroy() end
	if self.reshapeSupportAttachment then self.reshapeSupportAttachment:Destroy() end
	if self.axleRoot then self.axleRoot:Destroy() end
	self.leftLeg = nil
	self.rightLeg = nil
	self.reshapeSupportForce = nil
	self.reshapeSupportAttachment = nil
	self.axleRoot = nil
	self.joint = nil
	self.body = nil
	self.legsFolder = nil
	self.racerModel = nil
end

return LegPairAssembly