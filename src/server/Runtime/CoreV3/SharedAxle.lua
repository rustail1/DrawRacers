--!strict

local LegCoreConfig = require(script.Parent:WaitForChild("LegCoreConfig"))
local CollisionGroups = require(script.Parent.Parent:WaitForChild("CollisionGroups"))

local SharedAxle = {}
SharedAxle.__index = SharedAxle

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function configureInvisiblePart(part: Part, massless: boolean)
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Massless = massless
	part.CollisionGroup = CollisionGroups.RacerLeg
end

local function weld(part0: BasePart, part1: BasePart, name: string): WeldConstraint
	local constraint = Instance.new("WeldConstraint")
	constraint.Name = name
	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Parent = part1
	return constraint
end

local function createBodyMount(body: Part): Attachment
	local existing = body:FindFirstChild("LegDriveMount")
	if existing ~= nil then
		existing:Destroy()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "LegDriveMount"
	attachment.Position = Vector3.new(
		0,
		body.Size.Y * 0.5 * LegCoreConfig.Mount.VerticalFraction,
		0
	)
	attachment.Axis = Vector3.zAxis
	attachment.SecondaryAxis = Vector3.xAxis
	attachment.Parent = body
	return attachment
end

local function createMount(
	parent: Instance,
	axleRoot: Part,
	name: string,
	zOffset: number,
	phaseDegrees: number
): Part
	local mount = Instance.new("Part")
	mount.Name = name
	configureInvisiblePart(mount, true)
	mount.CFrame = axleRoot.CFrame
		* CFrame.new(0, 0, zOffset)
		* CFrame.Angles(0, 0, math.rad(phaseDegrees))
	mount.Parent = parent
	weld(axleRoot, mount, "AxleMountWeld")
	return mount
end

function SharedAxle.new(body: Part, container: Instance)
	assert(body:IsA("Part"), "SharedAxle requires BodyCollider Part")
	assert(container ~= nil, "SharedAxle requires container")
	CollisionGroups.ensure()

	local model = Instance.new("Model")
	model.Name = "SharedAxle"
	model.Parent = container

	local bodyMount = createBodyMount(body)

	local axleRoot = Instance.new("Part")
	axleRoot.Name = "AxleRoot"
	configureInvisiblePart(axleRoot, false)
	local axleRootSize = LegCoreConfig.Mount.AxleRootSize
	assert(type(axleRootSize) == "number" and axleRootSize >= 1.0, "Core V3 AxleRootSize must be >= 1")
	axleRoot.Size = Vector3.new(axleRootSize, axleRootSize, axleRootSize)
	local axleMaterial = LegCoreConfig.Materials.Axle
	axleRoot.CustomPhysicalProperties = PhysicalProperties.new(
		axleMaterial.Density,
		axleMaterial.Friction,
		axleMaterial.Elasticity,
		axleMaterial.FrictionWeight,
		axleMaterial.ElasticityWeight
	)
	axleRoot.CFrame = body.CFrame * CFrame.new(bodyMount.Position)
	axleRoot.Parent = model

	local axleAttachment = Instance.new("Attachment")
	axleAttachment.Name = "AxleAttachment"
	axleAttachment.Axis = Vector3.zAxis
	axleAttachment.SecondaryAxis = Vector3.xAxis
	axleAttachment.Parent = axleRoot

	local sideOffset = body.Size.Z * 0.5 + LegCoreConfig.Mount.SideOutset
	local leftMount = createMount(model, axleRoot, "LeftMount", -sideOffset, 0)
	local rightMount = createMount(
		model,
		axleRoot,
		"RightMount",
		sideOffset,
		LegCoreConfig.Mount.RightPhaseDegrees
	)

	local joint = Instance.new("HingeConstraint")
	joint.Name = "DriveJoint"
	joint.Attachment0 = bodyMount
	joint.Attachment1 = axleAttachment
	joint.ActuatorType = Enum.ActuatorType.Motor
	joint.AngularVelocity = 0
	joint.MotorMaxTorque = LegCoreConfig.Motor.Torque
	joint.MotorMaxAcceleration = LegCoreConfig.Motor.Acceleration
	-- The hinge is the structural connection between BodyCollider and AxleRoot.
	-- It must stay enabled even while the motor actuator is OFF during redraw.
	joint.Enabled = true
	joint.Parent = model

	return setmetatable({
		model = model,
		body = body,
		bodyMount = bodyMount,
		axleRoot = axleRoot,
		axleAttachment = axleAttachment,
		leftMount = leftMount,
		rightMount = rightMount,
		joint = joint,
		destroyed = false,
	}, SharedAxle)
end

function SharedAxle:GetJoint(): HingeConstraint
	assert(not self.destroyed, "SharedAxle is destroyed")
	return self.joint
end

function SharedAxle:GetAxleRoot(): Part
	assert(not self.destroyed, "SharedAxle is destroyed")
	return self.axleRoot
end

function SharedAxle:GetLeftMount(): Part
	assert(not self.destroyed, "SharedAxle is destroyed")
	return self.leftMount
end

function SharedAxle:GetRightMount(): Part
	assert(not self.destroyed, "SharedAxle is destroyed")
	return self.rightMount
end

function SharedAxle:GetPhaseDegrees(): number
	assert(not self.destroyed, "SharedAxle is destroyed")
	return self.joint.CurrentAngle
end

function SharedAxle:SetAngularVelocity(radPerSec: number)
	assert(not self.destroyed, "SharedAxle is destroyed")
	assert(type(radPerSec) == "number" and isFinite(radPerSec), "angular velocity must be finite")
	self.joint.AngularVelocity = radPerSec
end

function SharedAxle:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "SharedAxle is destroyed")
	assert(type(enabled) == "boolean", "enabled must be boolean")

	-- IMPORTANT: never disable HingeConstraint.Enabled here. Doing so physically
	-- disconnects the axle from the body, allowing the redraw hop/lift to move
	-- the body while the legs remain behind. Motor OFF means actuator OFF only.
	self.joint.Enabled = true
	if enabled then
		self.joint.ActuatorType = Enum.ActuatorType.Motor
		self.joint.MotorMaxTorque = LegCoreConfig.Motor.Torque
		self.joint.MotorMaxAcceleration = LegCoreConfig.Motor.Acceleration
	else
		self.joint.ActuatorType = Enum.ActuatorType.None
	end
end

function SharedAxle:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	if self.model ~= nil then
		self.model:Destroy()
	end
	if self.bodyMount ~= nil then
		self.bodyMount:Destroy()
	end

	self.model = nil
	self.body = nil
	self.bodyMount = nil
	self.axleRoot = nil
	self.axleAttachment = nil
	self.leftMount = nil
	self.rightMount = nil
	self.joint = nil
end

return SharedAxle
