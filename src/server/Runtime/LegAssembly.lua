--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local LegReshapeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("LegReshapeMath")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))

local RACER_LEG_GROUP = "RacerLeg"
local FRONT_VISUAL_COLOR = Color3.fromRGB(23, 32, 51)
local BACK_VISUAL_COLOR = Color3.fromRGB(57, 68, 84)

local LegAssembly = {}
LegAssembly.__index = LegAssembly

type ShapeSpec = StrokeTypes.ShapeSpec

export type BuildParams = {
	container: Instance,
	side: string,
	driveRoot: Part,
}

local function rotatePoint(point: Vector2, degrees: number): Vector2
	if math.abs(degrees) <= 1e-6 then return point end
	local angle = math.rad(degrees)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return Vector2.new(point.X * c - point.Y * s, point.X * s + point.Y * c)
end

local function makeSegmentCFrame(rootCFrame: CFrame, a: Vector2, b: Vector2): CFrame
	local delta = b - a
	local direction = delta.Unit
	local xAxis = Vector3.new(direction.X, direction.Y, 0)
	local zAxis = Vector3.zAxis
	local yAxis = zAxis:Cross(xAxis)
	local midpoint = (a + b) * 0.5
	return rootCFrame * CFrame.fromMatrix(Vector3.new(midpoint.X, midpoint.Y, 0), xAxis, yAxis, zAxis)
end

local function weldParts(name: string, part0: BasePart, part1: BasePart, parent: Instance)
	local weld = Instance.new("WeldConstraint")
	weld.Name = name
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = parent
	return weld
end

local function configureVisualPart(part: Part, color: Color3)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CollisionGroup = RACER_LEG_GROUP
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.CastShadow = false
end

local function configurePhysicalPart(part: Part, material: any)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Massless = false
	part.CollisionGroup = RACER_LEG_GROUP
	part.CustomPhysicalProperties = PhysicalProperties.new(
		material.Density,
		material.Friction,
		material.Elasticity,
		material.FrictionWeight,
		material.ElasticityWeight
	)
	part.Transparency = 1
end

local function validateShapeSpec(shapeSpec: ShapeSpec)
	assert(type(shapeSpec) == "table", "LegAssembly requires authoritative shapeSpec")
	assert(type(shapeSpec.segmentPlan) == "table" and #shapeSpec.segmentPlan > 0, "shapeSpec missing segmentPlan")
	assert(#shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg, "segment cap exceeded")
end

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function transformedPlan(shapeSpec: ShapeSpec, mountOffsetDegrees: number): { any }
	local result = table.create(#shapeSpec.segmentPlan)
	for index, planned in shapeSpec.segmentPlan do
		result[index] = {
			index = planned.index,
			a = rotatePoint(planned.a, mountOffsetDegrees),
			b = rotatePoint(planned.b, mountOffsetDegrees),
			canCollide = planned.canCollide,
		}
	end
	return result
end

local function transformedPoints(shapeSpec: ShapeSpec, mountOffsetDegrees: number): { Vector2 }
	local result = table.create(#shapeSpec.mappedPoints)
	for index, point in shapeSpec.mappedPoints do
		result[index] = rotatePoint(point, mountOffsetDegrees)
	end
	return result
end

local function buildVisualSegment(root: Part, folder: Instance, a: Vector2, b: Vector2, name: string, color: Color3)
	local length = (b - a).Magnitude
	if length <= 1e-4 then return end
	local geometry = PhysicsConfig.LegGeometry
	local visual = Instance.new("Part")
	visual.Name = name
	visual.Shape = Enum.PartType.Cylinder
	visual.Size = Vector3.new(length + geometry.SegmentOverlapAllowance, geometry.VisualLegSegmentThickness, geometry.VisualLegSegmentThickness)
	visual.CFrame = makeSegmentCFrame(root.CFrame, a, b)
	configureVisualPart(visual, color)
	visual.Parent = folder
	weldParts("RootWeld", root, visual, visual)
end

local function buildVisualJoint(root: Part, folder: Instance, point: Vector2, name: string, color: Color3)
	local thickness = PhysicsConfig.LegGeometry.VisualLegSegmentThickness
	local joint = Instance.new("Part")
	joint.Name = name
	joint.Shape = Enum.PartType.Ball
	joint.Size = Vector3.new(thickness, thickness, thickness)
	joint.CFrame = root.CFrame * CFrame.new(point.X, point.Y, 0)
	configureVisualPart(joint, color)
	joint.Parent = folder
	weldParts("RootWeld", root, joint, joint)
end

local function buildCompleteGeometry(self: any, shapeSpec: ShapeSpec, mountOffsetDegrees: number, pending: boolean)
	local geometry = PhysicsConfig.LegGeometry
	local plan = transformedPlan(shapeSpec, mountOffsetDegrees)
	local segmentFolder = makeFolder(if pending then "PendingSegments" else "Segments", self.model)
	local visualFolder = makeFolder(if pending then "PendingVisual" else "Visual", self.model)
	local parts = table.create(#plan)
	for index, planned in plan do
		local length = (planned.b - planned.a).Magnitude
		local segment = Instance.new("Part")
		segment.Name = string.format("Segment_%02d", index)
		segment.Size = Vector3.new(length + geometry.SegmentOverlapAllowance, geometry.PhysicalLegSegmentThickness, geometry.PhysicalLegSegmentThickness)
		segment.CFrame = makeSegmentCFrame(self.root.CFrame, planned.a, planned.b)
		configurePhysicalPart(segment, self.legMaterial)
		segment.Parent = segmentFolder
		weldParts("RootWeld", self.root, segment, segment)
		parts[index] = segment
		buildVisualSegment(self.root, visualFolder, planned.a, planned.b, string.format("VisualSegment_%02d", index), self.visualColor)
	end
	for index, point in transformedPoints(shapeSpec, mountOffsetDegrees) do
		buildVisualJoint(self.root, visualFolder, point, string.format("VisualJoint_%02d", index), self.visualColor)
	end
	return segmentFolder, visualFolder, parts, plan
end

local function enablePhysical(parts: { Part }, plan: { any })
	for index, part in parts do
		local planned = plan[index]
		part.CanCollide = planned ~= nil and planned.canCollide == true
		part.CanTouch = true
		part.CanQuery = true
	end
end

local function disablePhysical(parts: { Part })
	for _, part in parts do
		part.CanCollide = false
		part.CanTouch = false
	end
end

local function clearStage(self: any)
	if self.stageVisualFolder then self.stageVisualFolder:Destroy() end
	self.stageVisualFolder = nil
end

function LegAssembly.new(params: BuildParams)
	assert(params.side == "Left" or params.side == "Right", "LegAssembly side must be Left or Right")
	assert(params.driveRoot:IsA("Part"), "LegAssembly requires driveRoot")
	CollisionGroups.ensure()

	local model = Instance.new("Model")
	model.Name = if params.side == "Left" then "LeftLeg" else "RightLeg"
	model:SetAttribute("Side", params.side)
	model.Parent = params.container

	local root = Instance.new("Part")
	root.Name = "LegRoot"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = params.driveRoot.CFrame
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Transparency = 1
	root.Massless = true
	root.CollisionGroup = RACER_LEG_GROUP
	root.Parent = model
	weldParts("DriveWeld", params.driveRoot, root, root)

	return setmetatable({
		model = model,
		root = root,
		driveRoot = params.driveRoot,
		segmentsFolder = nil,
		visualFolder = nil,
		segments = {},
		segmentPlan = {},
		mappedPoints = {},
		mountOffsetDegrees = 0,
		stageShapeSpec = nil,
		stageOffsetDegrees = 0,
		stageVisualFolder = nil,
		visualColor = if params.side == "Left" then BACK_VISUAL_COLOR else FRONT_VISUAL_COLOR,
		legMaterial = PhysicsConfig.PhysicalMaterials.LegSegment,
		destroyed = false,
	}, LegAssembly)
end

function LegAssembly:GetModel(): Model
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.model
end

function LegAssembly:GetRoot(): Part
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.root
end

function LegAssembly:GetSegments(): { Part }
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.segments
end

function LegAssembly:GetMappedPoints(): { Vector2 }
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.mappedPoints
end

function LegAssembly:InstallGeometry(shapeSpec: ShapeSpec, mountOffsetDegrees: number?)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShapeSpec(shapeSpec)
	local offset = mountOffsetDegrees or 0
	if self.segmentsFolder then self.segmentsFolder:Destroy() end
	if self.visualFolder then self.visualFolder:Destroy() end
	clearStage(self)
	local segmentsFolder, visualFolder, parts, plan = buildCompleteGeometry(self, shapeSpec, offset, false)
	enablePhysical(parts, plan)
	self.segmentsFolder = segmentsFolder
	self.visualFolder = visualFolder
	self.segments = parts
	self.segmentPlan = plan
	self.mappedPoints = transformedPoints(shapeSpec, offset)
	self.mountOffsetDegrees = offset
end

function LegAssembly:StageGeometry(shapeSpec: ShapeSpec, mountOffsetDegrees: number?)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShapeSpec(shapeSpec)
	clearStage(self)
	self.stageShapeSpec = shapeSpec
	self.stageOffsetDegrees = mountOffsetDegrees or 0
	self.stageVisualFolder = makeFolder("StageVisual", self.model)
	self:SetStageProgress(0)
end

function LegAssembly:SetStageProgress(progress: number)
	assert(not self.destroyed, "LegAssembly is destroyed")
	local shapeSpec = self.stageShapeSpec
	if shapeSpec == nil then return end
	clearStage(self)
	local folder = makeFolder("StageVisual", self.model)
	self.stageVisualFolder = folder
	local plan = transformedPlan(shapeSpec, self.stageOffsetDegrees)
	local state = LegReshapeMath.Evaluate(plan, math.clamp(progress, 0, 1))
	for index = 1, state.completeSegments do
		local planned = plan[index]
		buildVisualSegment(self.root, folder, planned.a, planned.b, string.format("StageSegment_%02d", index), self.visualColor)
	end
	if state.partialSegmentIndex ~= nil and state.partialEndpoint ~= nil then
		local planned = plan[state.partialSegmentIndex]
		local endpoint = rotatePoint(state.partialEndpoint, self.stageOffsetDegrees)
		if planned ~= nil and (endpoint - planned.a).Magnitude > 1e-4 then
			buildVisualSegment(self.root, folder, planned.a, endpoint, "StageTipVisual", self.visualColor)
		end
	end
end

function LegAssembly:CommitStagedGeometry(): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")
	local shapeSpec = self.stageShapeSpec
	if shapeSpec == nil then return false end
	local offset = self.stageOffsetDegrees
	local pendingSegments, pendingVisual, pendingParts, pendingPlan = buildCompleteGeometry(self, shapeSpec, offset, true)

	-- Synchronous collision handoff: new colliders are fully built while disabled,
	-- then old support is disabled and the new set is enabled before old Instances die.
	disablePhysical(self.segments)
	enablePhysical(pendingParts, pendingPlan)
	if self.segmentsFolder then self.segmentsFolder:Destroy() end
	if self.visualFolder then self.visualFolder:Destroy() end
	pendingSegments.Name = "Segments"
	pendingVisual.Name = "Visual"
	self.segmentsFolder = pendingSegments
	self.visualFolder = pendingVisual
	self.segments = pendingParts
	self.segmentPlan = pendingPlan
	self.mappedPoints = transformedPoints(shapeSpec, offset)
	self.mountOffsetDegrees = offset
	self.stageShapeSpec = nil
	clearStage(self)
	return true
end

function LegAssembly:CancelStagedGeometry()
	if self.destroyed then return end
	self.stageShapeSpec = nil
	clearStage(self)
end

function LegAssembly:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	if self.model then self.model:Destroy() end
	self.model = nil
	self.root = nil
	self.driveRoot = nil
	self.segmentsFolder = nil
	self.visualFolder = nil
	self.segments = nil
	self.segmentPlan = nil
	self.mappedPoints = nil
	self.stageShapeSpec = nil
	self.stageVisualFolder = nil
end

return LegAssembly
