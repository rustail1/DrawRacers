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
	staged: boolean?,
}

type LegBuildParams = {
	racerModel: Model,
	axleRoot: Part,
	shapeSpec: ShapeSpec,
	side: string,
	socketZ: number,
	phaseDegrees: number,
	staged: boolean,
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

local function buildLeg(params: LegBuildParams)
	return LegAssembly.new({
		racerModel = params.racerModel,
		side = params.side,
		shapeSpec = params.shapeSpec,
		axleRoot = params.axleRoot,
		socketZ = params.socketZ,
		phaseDegrees = params.phaseDegrees,
		staged = params.staged,
	})
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

	-- BG-04: human Studio evidence showed a real support hole during the 0.08-0.15s
	-- HUB->TIP transition: old colliders retire immediately while the new pair starts
	-- at zero length. Counter only gravity during that short interval; do not anchor,
	-- teleport, or apply horizontal propulsion.
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
			racerModel = racerModel,
			axleRoot = axleRoot,
			shapeSpec = params.shapeSpec,
			side = "Left",
			socketZ = -geometry.LegSocketZAbs,
			phaseDegrees = 0,
			staged = staged,
		})
		rightLeg = buildLeg({
			racerModel = racerModel,
			axleRoot = axleRoot,
			shapeSpec = params.shapeSpec,
			side = "Right",
			socketZ = geometry.LegSocketZAbs,
			phaseDegrees = motor.RightPhaseOffsetDegrees,
			staged = staged,
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

	return setmetatable({
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
		committed = not staged,
		destroyed = false,
	}, LegPairAssembly)
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
	if self.committed then return end
	assert(self.axleRoot.Parent == nil, "staged axle root already has a parent")
	assert(not self.leftLeg:IsCommitted() and not self.rightLeg:IsCommitted(), "staged sides unexpectedly committed")
	self.axleRoot.Parent = self.legsFolder
	self.leftLeg:Commit()
	self.rightLeg:Commit()
	self.committed = true
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

local function buildStagedSides(self: any, shapeSpec: ShapeSpec)
	local geometry = PhysicsConfig.LegGeometry
	local motor = PhysicsConfig.Motor
	-- BG-01: the shared axle keeps its live phase, but a freshly drawn shape is
	-- mounted with the inverse live phase so its first rendered world frame has
	-- the same orientation the player just saw on the canonical canvas. The
	-- Right copy retains the fixed 180-degree structural opposition.
	local currentAxlePhaseDegrees = self:GetPhaseDegrees()
	local redrawBasePhaseDegrees = -currentAxlePhaseDegrees
	local stagedLeft = nil
	local stagedRight = nil
	local buildOk, buildError = pcall(function()
		stagedLeft = buildLeg({
			racerModel = self.racerModel,
			axleRoot = self.axleRoot,
			shapeSpec = shapeSpec,
			side = "Left",
			socketZ = -geometry.LegSocketZAbs,
			phaseDegrees = redrawBasePhaseDegrees,
			staged = true,
		})
		stagedRight = buildLeg({
			racerModel = self.racerModel,
			axleRoot = self.axleRoot,
			shapeSpec = shapeSpec,
			side = "Right",
			socketZ = geometry.LegSocketZAbs,
			phaseDegrees = redrawBasePhaseDegrees + motor.RightPhaseOffsetDegrees,
			staged = true,
		})
	end)
	if not buildOk then
		if stagedLeft ~= nil then stagedLeft:Destroy() end
		if stagedRight ~= nil then stagedRight:Destroy() end
		error(buildError)
	end
	assert(stagedLeft ~= nil and stagedRight ~= nil, "geometry replacement produced incomplete staged sides")
	return stagedLeft, stagedRight
end

function LegPairAssembly:ReplaceGeometry(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	assert(self.committed, "ReplaceGeometry requires a committed stable axle")
	assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table" and #shapeSpec.segmentPlan > 0, "shapeSpec missing physical segmentPlan")

	self.reshapeForcedComplete = false
	self:_SetReshapeSupportEnabled(false)
	local stagedLeft, stagedRight = buildStagedSides(self, shapeSpec)
	local oldLeft = self.leftLeg
	local oldRight = self.rightLeg
	oldLeft:SetRetiring(true)
	oldRight:SetRetiring(true)

	local commitOk, commitError = pcall(function()
		stagedLeft:Commit()
		stagedRight:Commit()
	end)
	if not commitOk then
		stagedLeft:Destroy()
		stagedRight:Destroy()
		oldLeft:SetRetiring(false)
		oldRight:SetRetiring(false)
		error(commitError)
	end

	self.leftLeg = stagedLeft
	self.rightLeg = stagedRight
	oldLeft:Destroy()
	oldRight:Destroy()
	return self.leftLeg, self.rightLeg
end

function LegPairAssembly:BeginGeometryReshape(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	assert(self.committed, "BeginGeometryReshape requires a committed stable axle")
	assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table" and #shapeSpec.segmentPlan > 0, "shapeSpec missing physical segmentPlan")

	local stagedLeft, stagedRight = buildStagedSides(self, shapeSpec)
	stagedLeft:SetReshapeProgress(0)
	stagedRight:SetReshapeProgress(0)
	self.reshapeForcedComplete = false
	self:_SetReshapeSupportEnabled(true)

	local oldLeft = self.leftLeg
	local oldRight = self.rightLeg
	oldLeft:SetRetiring(true)
	oldRight:SetRetiring(true)

	local commitOk, commitError = pcall(function()
		stagedLeft:Commit()
		stagedRight:Commit()
	end)
	if not commitOk then
		self:_SetReshapeSupportEnabled(false)
		stagedLeft:Destroy()
		stagedRight:Destroy()
		oldLeft:SetRetiring(false)
		oldRight:SetRetiring(false)
		error(commitError)
	end

	self.leftLeg = stagedLeft
	self.rightLeg = stagedRight
	oldLeft:Destroy()
	oldRight:Destroy()
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
	self.joint.Enabled = enabled
end

function LegPairAssembly:SetRetiring(retiring: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self.axleRoot.Name = if retiring then "AxleRoot_Retiring" else "AxleRoot"
	self.leftLeg:SetRetiring(retiring)
	self.rightLeg:SetRetiring(retiring)
end

function LegPairAssembly:Destroy()
	if self.destroyed then return end
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
