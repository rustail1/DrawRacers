--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	staged: boolean?,
}

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

function LegPairAssembly.new(params: BuildParams)
	assert(type(params.shapeSpec) == "table", "LegPairAssembly requires authoritative shapeSpec")
	assert(type(params.shapeSpec.segmentPlan) == "table" and #params.shapeSpec.segmentPlan > 0, "shapeSpec missing physical segmentPlan")
	CollisionGroups.ensure()

	local racerModel = params.racerModel
	local body = racerModel:FindFirstChild("BodyCollider")
	local legsFolder = racerModel:FindFirstChild("Legs")
	assert(body and body:IsA("Part"), "racerModel missing BodyCollider")
	assert(legsFolder and legsFolder:IsA("Folder"), "racerModel missing Legs folder")

	local geometry = PhysicsConfig.LegGeometry
	local motor = PhysicsConfig.Motor
	local staged = params.staged == true
	local initialPhaseDegrees = params.initialPhaseDegrees or 0
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
	if not staged then
		axleRoot.Parent = legsFolder
	end

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
	joint.AngularVelocity = PhysicsConfig.Motor.AngularVelocity
	joint.MotorMaxTorque = motor.MotorMaxTorque
	joint.MotorMaxAcceleration = motor.MotorMaxAcceleration
	joint.Enabled = if staged then false else params.motorEnabled == true
	joint.Parent = axleRoot

	local leftLeg = LegAssembly.new({
		racerModel = racerModel,
		side = "Left",
		shapeSpec = params.shapeSpec,
		axleRoot = axleRoot,
		socketZ = -geometry.LegSocketZAbs,
		phaseDegrees = 0,
		staged = staged,
	})
	local rightLeg = LegAssembly.new({
		racerModel = racerModel,
		side = "Right",
		shapeSpec = params.shapeSpec,
		axleRoot = axleRoot,
		socketZ = geometry.LegSocketZAbs,
		phaseDegrees = motor.RightPhaseOffsetDegrees,
		staged = staged,
	})

	local self = setmetatable({
		racerModel = racerModel,
		body = body,
		legsFolder = legsFolder,
		axleRoot = axleRoot,
		joint = joint,
		leftLeg = leftLeg,
		rightLeg = rightLeg,
		initialPhaseDegrees = initialPhaseDegrees,
		committed = not staged,
		destroyed = false,
	}, LegPairAssembly)
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

function LegPairAssembly:IsCommitted(): boolean
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.committed
end

function LegPairAssembly:Commit()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	if self.committed then
		return
	end
	assert(self.axleRoot.Parent == nil, "staged axle root already has a parent")
	assert(not self.leftLeg:IsCommitted() and not self.rightLeg:IsCommitted(), "staged sides unexpectedly committed")
	self.axleRoot.Parent = self.legsFolder
	self.leftLeg:Commit()
	self.rightLeg:Commit()
	self.committed = true
end

function LegPairAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self.joint.Enabled = enabled
end

function LegPairAssembly:SetRetiring(retiring: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self.axleRoot.Name = if retiring then "AxleRoot_Retiring" else "AxleRoot"
	self.leftLeg:SetRetiring(retiring)
	self.rightLeg:SetRetiring(retiring)
end

function LegPairAssembly:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.leftLeg then
		self.leftLeg:Destroy()
	end
	if self.rightLeg then
		self.rightLeg:Destroy()
	end
	if self.axleRoot then
		self.axleRoot:Destroy()
	end
	self.leftLeg = nil
	self.rightLeg = nil
	self.axleRoot = nil
	self.joint = nil
	self.body = nil
	self.legsFolder = nil
	self.racerModel = nil
end

return LegPairAssembly
