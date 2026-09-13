--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegAssembly = require(script.Parent:WaitForChild("LegAssembly"))

local RACER_LEG_GROUP = "RacerLeg"

local LegDriveAssembly = {}
LegDriveAssembly.__index = LegDriveAssembly

export type BuildParams = {
	body: Part,
	bodyMount: Attachment,
	container: Instance,
	side: string,
	initialPhaseDegrees: number,
}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function configureRoot(root: Part)
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Transparency = 1
	root.Massless = true
	root.CollisionGroup = RACER_LEG_GROUP
end

function LegDriveAssembly.new(params: BuildParams)
	assert(params.side == "Left" or params.side == "Right", "LegDriveAssembly side must be Left or Right")
	assert(params.body:IsA("Part"), "LegDriveAssembly requires BodyCollider Part")
	assert(params.bodyMount:IsA("Attachment"), "LegDriveAssembly requires explicit body mount")
	assert(params.bodyMount.Parent == params.body, "LegDriveAssembly body mount must belong to BodyCollider")
	assert(type(params.initialPhaseDegrees) == "number" and isFinite(params.initialPhaseDegrees), "initial phase must be finite")
	CollisionGroups.ensure()

	local body = params.body
	local bodyMount = params.bodyMount
	local side = params.side
	local model = Instance.new("Model")
	model.Name = side .. "Drive"
	model:SetAttribute("Side", side)
	model.Parent = params.container

	local driveRoot = Instance.new("Part")
	driveRoot.Name = "DriveRoot"
	configureRoot(driveRoot)
	driveRoot.CFrame = bodyMount.WorldCFrame * CFrame.Angles(0, 0, math.rad(params.initialPhaseDegrees))
	driveRoot.Parent = model

	local driveAttachment = Instance.new("Attachment")
	driveAttachment.Name = "DriveAttachment"
	driveAttachment.Axis = Vector3.zAxis
	driveAttachment.SecondaryAxis = Vector3.xAxis
	driveAttachment.Parent = driveRoot

	local motor = PhysicsConfig.Motor
	local joint = Instance.new("HingeConstraint")
	joint.Name = "DriveJoint"
	joint.Attachment0 = bodyMount
	joint.Attachment1 = driveAttachment
	joint.ActuatorType = Enum.ActuatorType.Motor
	joint.AngularVelocity = 0
	joint.MotorMaxTorque = motor.MotorMaxTorque
	joint.MotorMaxAcceleration = motor.MotorMaxAcceleration
	joint.Enabled = false
	joint.Parent = model

	local leg = LegAssembly.new({
		container = model,
		side = side,
		driveRoot = driveRoot,
	})

	return setmetatable({
		model = model,
		body = body,
		bodyMount = bodyMount,
		side = side,
		driveRoot = driveRoot,
		driveAttachment = driveAttachment,
		joint = joint,
		leg = leg,
		destroyed = false,
	}, LegDriveAssembly)
end

function LegDriveAssembly:GetRoot(): Part
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.driveRoot
end

function LegDriveAssembly:GetJoint(): HingeConstraint
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.joint
end

function LegDriveAssembly:GetLeg()
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return self.leg
end

function LegDriveAssembly:GetPhaseDegrees(): number
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	return math.deg(self.joint.CurrentAngle)
end

function LegDriveAssembly:SetMotorVelocity(radPerSec: number)
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	assert(type(radPerSec) == "number" and isFinite(radPerSec), "motor velocity must be finite")
	self.joint.AngularVelocity = radPerSec
end

function LegDriveAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegDriveAssembly is destroyed")
	self.joint.Enabled = enabled
end

function LegDriveAssembly:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	if self.leg then self.leg:Destroy() end
	if self.model then self.model:Destroy() end
	self.leg = nil
	self.bodyMount = nil
	self.driveAttachment = nil
	self.driveRoot = nil
	self.joint = nil
	self.body = nil
	self.model = nil
end

return LegDriveAssembly