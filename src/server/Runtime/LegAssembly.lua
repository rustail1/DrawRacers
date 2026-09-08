--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))

local RACER_LEG_GROUP = "RacerLeg"

local LegAssembly = {}
LegAssembly.__index = LegAssembly

export type BuildParams = {
	racerModel: Model,
	side: string,
	normalizedPoints: { Vector2 },
	motorEnabled: boolean?,
	initialPhaseDegrees: number?,
}

local function mapPoint(point: Vector2): Vector2
	local geometry = PhysicsConfig.LegGeometry
	local clamped = Vector2.new(math.clamp(point.X, -1, 1), math.clamp(point.Y, -1, 1))
	local mapped = clamped * geometry.LegCanvasHalfSpan
	local magnitude = mapped.Magnitude
	if magnitude > geometry.MaxLegExtentFromHub and magnitude > 0 then
		mapped *= geometry.MaxLegExtentFromHub / magnitude
	end
	return mapped
end

local function distanceFromOriginToSegment(a: Vector2, b: Vector2): number
	local ab = b - a
	local lengthSquared = ab:Dot(ab)
	if lengthSquared <= 0 then
		return a.Magnitude
	end

	local t = math.clamp((-a):Dot(ab) / lengthSquared, 0, 1)
	return (a + ab * t).Magnitude
end

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
	assert(#params.normalizedPoints >= 2, "LegAssembly requires at least two normalized points")

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

	local hub = racerModel:FindFirstChild(hubName)
	assert(hub and hub:IsA("Part"), string.format("racerModel missing %s", hubName))
	local hubAttachment = hub:FindFirstChild("MotorAttachment")
	assert(hubAttachment and hubAttachment:IsA("Attachment"), string.format("%s missing MotorAttachment", hubName))
	hubAttachment.Axis = Vector3.zAxis
	hubAttachment.SecondaryAxis = Vector3.yAxis

	local existing = legsFolder:FindFirstChild(legName)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = legName
	model:SetAttribute("Side", side)
	model:SetAttribute("InitialPhaseDegrees", initialPhaseDegrees)
	model.Parent = legsFolder

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

	local mappedPoints = table.create(#params.normalizedPoints)
	for index, point in params.normalizedPoints do
		mappedPoints[index] = mapPoint(point)
	end

	local segments = {}
	local segmentIndex = 0
	for index = 2, #mappedPoints do
		if segmentIndex >= geometry.MaxColliderSegmentsPerLeg then
			break
		end

		local a = mappedPoints[index - 1]
		local b = mappedPoints[index]
		local mappedLength = (b - a).Magnitude
		if mappedLength >= geometry.MinimumMappedSegmentLength then
			segmentIndex += 1

			local segment = Instance.new("Part")
			segment.Name = string.format("Segment_%02d", segmentIndex)
			segment.Size = Vector3.new(
				mappedLength + geometry.SegmentOverlapAllowance,
				geometry.PhysicalLegSegmentThickness,
				geometry.PhysicalLegSegmentThickness
			)
			segment.CFrame = makeSegmentCFrame(root.CFrame, a, b)
			segment.Anchored = false
			segment.CanCollide = distanceFromOriginToSegment(a, b) >= geometry.InnerHubNoCollisionRadius
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
	end

	assert(#segments > 0, "LegAssembly produced no legal physical segments")

	local self = setmetatable({
		model = model,
		root = root,
		joint = joint,
		segments = segments,
		mappedPoints = mappedPoints,
		initialPhaseDegrees = initialPhaseDegrees,
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
	table.clear(self.segments)
	table.clear(self.mappedPoints)
end

return LegAssembly
