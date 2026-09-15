--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))

local RACER_LEG_GROUP = "RacerLeg"

local LegDriveAssembly = {}
LegDriveAssembly.__index = LegDriveAssembly

export type BuildParams = {
	body: Part,
	container: Instance,
	initialPhaseDegrees: number,
}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function weld(part0: BasePart, part1: BasePart, name: string)
	local link = Instance.new("WeldConstraint")
	link.Name = name
	link.Part0 = part0
	link.Part1 = part1
	link.Parent = part1
end

local function configureSideRoot(root: Part)
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Transparency = 1
	root.Massless = true
	root.CollisionGroup = RACER_LEG_GROUP
end

local function ensureBodyMount(body: Part): Attachment
	local old = body:FindFirstChild("LegDriveMount")
	if old ~= nil and not old:IsA("Attachment") then
		old:Destroy()
		old = nil
	end

	local mount = old :: Attachment?
	if mount == nil then
		mount = Instance.new("Attachment")
		mount.Name = "LegDriveMount"
		mount.Parent = body
	end

	local geometry = PhysicsConfig.LegGeometry
	mount.Position = Vector3.new(
		0,
		body.Size.Y * 0.5 * geometry.LegMountVerticalFraction,
		0
	)
	mount.Axis = Vector3.zAxis
	mount.SecondaryAxis = Vector3.xAxis
	return mount
end

local function createSideRoot(
	parent: Instance,
	axleRoot: Part,
	name: string,
	zOffset: number,
	phaseDegrees: number
): Part
	local root = Instance.new("Part")
	root.Name = name
	configureSideRoot(root)
	root.CFrame = axleRoot.CFrame
		* CFrame.new(0, 0, zOffset)
		* CFrame.Angles(0, 0, math.rad(phaseDegrees))
	root.Parent = parent
	weld(axleRoot, root, "AxleWeld")
	return root
end

function LegDriveAssembly.new(params: BuildParams)
	assert(params.body:IsA("Part"), "LegDriveAssembly requires BodyCollider Part")
	assert(
		type(params.initialPhaseDegrees) == "number"
			and isFinite(params.initialPhaseDegrees),
		"initial phase must be finite"
	)

	CollisionGroups.ensure()

	local body = params.body
	local geometry = PhysicsConfig.LegGeometry
	local motor = PhysicsConfig.Motor

	local model = Instance.new("Model")
	model.Name = "SharedLegDrive"
	model.Parent = params.container

	local bodyMount = ensureBodyMount(body)

	-- The axle is the only non-massless part on the driven side of the hinge.
	-- Its density is intentionally tiny; drawn leg segments are massless.
	local axleRoot = Instance.new("Part")
	axleRoot.Name = "AxleRoot"
	axleRoot.Size = Vector3.new(0.2, 0.2, 0.2)
	axleRoot.Anchored = false
	axleRoot.CanCollide = false
	axleRoot.CanTouch = false
	axleRoot.CanQuery = false
	axleRoot.Transparency = 1
	axleRoot.Massless = false
	axleRoot.CollisionGroup = RACER_LEG_GROUP

	local axleMaterial = PhysicsConfig.PhysicalMaterials.Axle
	axleRoot.CustomPhysicalProperties = PhysicalProperties.new(
		axleMaterial.Density,
		axleMaterial.Friction,
		axleMaterial.Elasticity,
		axleMaterial.FrictionWeight,
		axleMaterial.ElasticityWeight
	)

	axleRoot.CFrame = bodyMount.WorldCFrame
		* CFrame.Angles(0, 0, math.rad(params.initialPhaseDegrees))
	axleRoot.Parent = model

	local axleAttachment = Instance.new("Attachment")
	axleAttachment.Name = "AxleAttachment"
	axleAttachment.Axis = Vector3.zAxis
	axleAttachment.SecondaryAxis = Vector3.xAxis
	axleAttachment.Parent = axleRoot

	local joint = Instance.new("HingeConstraint")
	joint.Name = "DriveJoint"
	joint.Attachment0 = bodyMount
	joint.Attachment1 = axleAttachment
	joint.ActuatorType = Enum.ActuatorType.Motor
	joint.AngularVelocity = 0
	joint.MotorMaxTorque = motor.MotorMaxTorque
	joint.MotorMaxAcceleration = motor.MotorMaxAcceleration
	joint.Enabled = false
	joint.Parent = model

	local sideOffset = body.Size.Z * 0.5 + geometry.LegMountOutset

	local leftRoot = createSideRoot(
		model,
		axleRoot,
		"LeftDriveRoot",
		-sideOffset,
		0
	)

	local rightRoot = createSideRoot(
		model,
		axleRoot,
		"RightDriveRoot",
		sideOffset,
		geometry.RightLegFixedPhaseDegrees
	)

	return setmetatable({
		model = model,
		body = body,
		bodyMount = bodyMount,
		axleRoot = axleRoot,
		axleAttachment = axleAttachment,
		joint = joint,
		leftRoot = leftRoot,
		rightRoot = rightRoot,
		destroyed = false,
	}, LegDriveAssembly)
end

function LegDriveAssembly:GetModel(): Model
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.model
end

function LegDriveAssembly:GetJoint(): HingeConstraint
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.joint
end

function LegDriveAssembly:GetPhaseDegrees(): number
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return math.deg(self.joint.CurrentAngle)
end

function LegDriveAssembly:GetLeftRoot(): Part
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.leftRoot
end

function LegDriveAssembly:GetRightRoot(): Part
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.rightRoot
end

function LegDriveAssembly:SetMotorVelocity(radPerSec: number)
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	assert(
		type(radPerSec) == "number" and isFinite(radPerSec),
		"motor velocity must be finite"
	)
	self.joint.AngularVelocity = radPerSec
end

function LegDriveAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	self.joint.Enabled = enabled
end

function LegDriveAssembly:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	if self.model then
		self.model:Destroy()
	end
	if self.bodyMount then
		self.bodyMount:Destroy()
	end

	self.leftRoot = nil
	self.rightRoot = nil
	self.axleAttachment = nil
	self.axleRoot = nil
	self.joint = nil
	self.bodyMount = nil
	self.body = nil
	self.model = nil
end

return LegDriveAssembly
