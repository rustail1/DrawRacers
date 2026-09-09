--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))

local RACER_LEG_GROUP = "RacerLeg"

local LegAssembly = {}
LegAssembly.__index = LegAssembly

type ShapeSpec = StrokeTypes.ShapeSpec

export type BuildParams = {
	racerModel: Model,
	side: string,
	shapeSpec: ShapeSpec,
	motorEnabled: boolean?,
	initialPhaseDegrees: number?,
	staged: boolean?,
}

local function makeSegmentCFrame(rootCFrame: CFrame, a: Vector2, b: Vector2): CFrame
	local delta = b - a
	local direction = delta.Unit
	local xAxis = Vector3.new(direction.X, direction.Y, 0)
	local zAxis = Vector3.zAxis
	local yAxis = zAxis:Cross(xAxis)
	local midpoint = (a + b) * 0.5
	local localFrame = CFrame.fromMatrix(Vector3.new(midpoint.X, midpoint.Y, 0), xAxis, yAxis, zAxis)
	return rootCFrame * localFrame
end

function LegAssembly.new(params: BuildParams)
	assert(params.side == "Left" or params.side == "Right", "LegAssembly side must be Left or Right")
	assert(type(params.shapeSpec) == "table", "LegAssembly requires authoritative shapeSpec")
	assert(type(params.shapeSpec.segmentPlan) == "table", "shapeSpec missing segmentPlan")
	assert(#params.shapeSpec.segmentPlan > 0, "LegAssembly requires at least one planned segment")
	assert(#params.shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg, "shapeSpec segmentPlan exceeds collider cap")

	CollisionGroups.ensure()

	local geometry = PhysicsConfig.LegGeometry
	local motor = PhysicsConfig.Motor
	local racerModel = params.racerModel
	local legsFolder = racerModel:FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"), "racerModel missing Legs folder")

	local side = params.side
	local hubName = if side == "Left" then "LeftHub" else "RightHub"
	local legName = if side == "Left" then "LeftLeg" else "RightLeg"
	local initialPhaseDegrees = params.initialPhaseDegrees or 0
	local staged = params.staged == true

	local hub = racerModel:FindFirstChild(hubName)
	assert(hub and hub:IsA("Part"), string.format("racerModel missing %s", hubName))
	local hubAttachment = hub:FindFirstChild("MotorAttachment")
	assert(hubAttachment and hubAttachment:IsA("Attachment"), string.format("%s missing MotorAttachment", hubName))
	hubAttachment.Axis = Vector3.zAxis
	hubAttachment.SecondaryAxis = Vector3.yAxis

	if not staged then
		local existing = legsFolder:FindFirstChild(legName)
		if existing then
			existing:Destroy()
		end
	end

	local model = Instance.new("Model")
	model.Name = legName
	model:SetAttribute("Side", side)
	model:SetAttribute("InitialPhaseDegrees", initialPhaseDegrees)
	if not staged then
		model.Parent = legsFolder
	end

	local root = Instance.new("Part")
	root.Name = "LegRoot"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = hub.CFrame * CFrame.Angles(0, 0, math.rad(initialPhaseDegrees))
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Transparency = 1
	root.Massless = true
	root.CollisionGroup = RACER_LEG_GROUP
	root.Parent = model

	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "MotorAttachment"
	rootAttachment.Axis = Vector3.zAxis
	rootAttachment.SecondaryAxis = Vector3.yAxis
	rootAttachment.Parent = root

	local joint = Instance.new("HingeConstraint")
	joint.Name = "HubJoint"
	joint.Attachment0 = hubAttachment
	joint.Attachment1 = rootAttachment
	joint.ActuatorType = Enum.ActuatorType.Motor
	joint.AngularVelocity = motor.AngularVelocity
	joint.MotorMaxTorque = motor.MotorMaxTorque
	joint.MotorMaxAcceleration = motor.MotorMaxAcceleration
	joint.Enabled = params.motorEnabled == true
	joint.Parent = model

	local segmentsFolder = Instance.new("Folder")
	segmentsFolder.Name = "Segments"
	segmentsFolder.Parent = model

	local visualFolder = Instance.new("Folder")
	visualFolder.Name = "Visual"
	visualFolder.Parent = model

	local segments = {}
	for _, planned in params.shapeSpec.segmentPlan do
		local a = planned.a
		local b = planned.b
		assert(typeof(a) == "Vector2" and typeof(b) == "Vector2", "shapeSpec segmentPlan contains invalid endpoints")
		local mappedLength = (b - a).Magnitude
		assert(mappedLength >= geometry.MinimumMappedSegmentLength, "shapeSpec contains sub-minimum segment")

		local segment = Instance.new("Part")
		segment.Name = string.format("Segment_%02d", planned.index)
		segment.Size = Vector3.new(
			mappedLength + geometry.SegmentOverlapAllowance,
			geometry.PhysicalLegSegmentThickness,
			geometry.PhysicalLegSegmentThickness
		)
		segment.CFrame = makeSegmentCFrame(root.CFrame, a, b)
		segment.Anchored = false
		segment.CanCollide = planned.canCollide == true
		segment.CanTouch = true
		segment.CanQuery = true
		segment.Massless = false
		segment.CollisionGroup = RACER_LEG_GROUP
		segment.CustomPhysicalProperties = PhysicalProperties.new(1.0, 1.0, 0.02, 100, 100)
		if RunService:IsStudio() then
			segment.Transparency = 0.08
			segment.Color = if side == "Left" then Color3.fromRGB(60, 205, 255) else Color3.fromRGB(110, 235, 255)
			segment.Material = Enum.Material.Neon
		else
			segment.Transparency = 1
		end
		segment.Parent = segmentsFolder

		local weld = Instance.new("WeldConstraint")
		weld.Name = "RootWeld"
		weld.Part0 = root
		weld.Part1 = segment
		weld.Parent = segment

		table.insert(segments, segment)
	end

	assert(#segments > 0, "LegAssembly produced no legal physical segments")

	local mappedPoints = params.shapeSpec.mappedPoints or {}
	local self = setmetatable({
		model = model,
		root = root,
		joint = joint,
		segments = segments,
		mappedPoints = mappedPoints,
		initialPhaseDegrees = initialPhaseDegrees,
		legsFolder = legsFolder,
		committed = not staged,
		destroyed = false,
	}, LegAssembly)

	return self
end

function LegAssembly:GetModel(): Model
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.model
end

function LegAssembly:GetRoot(): Part
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.root
end

function LegAssembly:GetJoint(): HingeConstraint
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.joint
end

function LegAssembly:GetSegments(): { Part }
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.segments
end

function LegAssembly:GetMappedPoints(): { Vector2 }
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.mappedPoints
end

function LegAssembly:GetInitialPhaseDegrees(): number
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.initialPhaseDegrees
end

function LegAssembly:IsCommitted(): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.committed
end

function LegAssembly:Commit()
	assert(not self.destroyed, "LegAssembly is destroyed")
	if self.committed then
		return
	end
	assert(self.model.Parent == nil, "staged LegAssembly already has a parent")
	self.model.Parent = self.legsFolder
	self.committed = true
end

function LegAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegAssembly is destroyed")
	self.joint.Enabled = enabled
end

function LegAssembly:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.model then
		self.model:Destroy()
	end
	self.model = nil
	self.root = nil
	self.joint = nil
	self.legsFolder = nil
	table.clear(self.segments)
	table.clear(self.mappedPoints)
end

return LegAssembly
