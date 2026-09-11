--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
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
	racerModel: Model,
	side: string,
	shapeSpec: ShapeSpec,
	axleRoot: Part,
	socketZ: number,
	phaseDegrees: number?,
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

local function configureVisualPart(visual: Part, color: Color3)
	visual.Anchored = false
	visual.CanCollide = false
	visual.CanTouch = false
	visual.CanQuery = false
	visual.Massless = true
	visual.CollisionGroup = RACER_LEG_GROUP
	visual.Material = Enum.Material.SmoothPlastic
	visual.Color = color
	visual.CastShadow = false
end

local function weldParts(name: string, part0: BasePart, part1: BasePart, parent: Instance)
	local weld = Instance.new("WeldConstraint")
	weld.Name = name
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = parent
	return weld
end

function LegAssembly.new(params: BuildParams)
	assert(params.side == "Left" or params.side == "Right", "LegAssembly side must be Left or Right")
	assert(type(params.shapeSpec) == "table", "LegAssembly requires authoritative shapeSpec")
	assert(type(params.shapeSpec.segmentPlan) == "table", "shapeSpec missing segmentPlan")
	assert(#params.shapeSpec.segmentPlan > 0, "LegAssembly requires at least one planned segment")
	assert(#params.shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg, "shapeSpec segmentPlan exceeds collider cap")
	assert(params.axleRoot:IsA("Part"), "LegAssembly requires shared axle root")

	CollisionGroups.ensure()

	local geometry = PhysicsConfig.LegGeometry
	local legMaterial = PhysicsConfig.PhysicalMaterials.LegSegment
	local racerModel = params.racerModel
	local legsFolder = racerModel:FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"), "racerModel missing Legs folder")

	local side = params.side
	local legName = if side == "Left" then "LeftLeg" else "RightLeg"
	local phaseDegrees = params.phaseDegrees or 0
	local staged = params.staged == true
	local visualColor = if side == "Left" then BACK_VISUAL_COLOR else FRONT_VISUAL_COLOR
	local visualThickness = geometry.PhysicalLegSegmentThickness * 0.78

	if not staged then
		local existing = legsFolder:FindFirstChild(legName)
		if existing then
			existing:Destroy()
		end
	end

	local model = Instance.new("Model")
	model.Name = legName
	model:SetAttribute("Side", side)
	model:SetAttribute("StructuralPhaseDegrees", phaseDegrees)
	if not staged then
		model.Parent = legsFolder
	end

	local root = Instance.new("Part")
	root.Name = "LegRoot"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = params.axleRoot.CFrame
		* CFrame.Angles(0, 0, math.rad(phaseDegrees))
		* CFrame.new(0, 0, params.socketZ)
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Transparency = 1
	root.Massless = true
	root.CollisionGroup = RACER_LEG_GROUP
	root.Parent = model

	weldParts("AxleWeld", params.axleRoot, root, root)

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
		segment.CustomPhysicalProperties = PhysicalProperties.new(
			legMaterial.Density,
			legMaterial.Friction,
			legMaterial.Elasticity,
			legMaterial.FrictionWeight,
			legMaterial.ElasticityWeight
		)
		segment.Transparency = 1
		segment.Parent = segmentsFolder
		weldParts("RootWeld", root, segment, segment)
		table.insert(segments, segment)
	end

	assert(#segments > 0, "LegAssembly produced no legal physical segments")

	local mappedPoints = params.shapeSpec.mappedPoints or {}
	for index, point in mappedPoints do
		local visual = Instance.new("Part")
		visual.Name = string.format("VisualJoint_%02d", index)
		visual.Shape = Enum.PartType.Ball
		visual.Size = Vector3.new(visualThickness, visualThickness, visualThickness)
		visual.CFrame = root.CFrame * CFrame.new(point.X, point.Y, 0)
		configureVisualPart(visual, visualColor)
		visual.Parent = visualFolder
		weldParts("RootWeld", root, visual, visual)
	end

	for _, planned in params.shapeSpec.segmentPlan do
		local a = planned.a
		local b = planned.b
		local mappedLength = (b - a).Magnitude
		local visual = Instance.new("Part")
		visual.Name = string.format("VisualSegment_%02d", planned.index)
		visual.Shape = Enum.PartType.Cylinder
		visual.Size = Vector3.new(mappedLength + geometry.SegmentOverlapAllowance, visualThickness, visualThickness)
		visual.CFrame = makeSegmentCFrame(root.CFrame, a, b)
		configureVisualPart(visual, visualColor)
		visual.Parent = visualFolder
		weldParts("RootWeld", root, visual, visual)
	end

	local self = setmetatable({
		model = model,
		root = root,
		segments = segments,
		mappedPoints = mappedPoints,
		phaseDegrees = phaseDegrees,
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

function LegAssembly:GetSegments(): { Part }
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.segments
end

function LegAssembly:GetMappedPoints(): { Vector2 }
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.mappedPoints
end

function LegAssembly:GetStructuralPhaseDegrees(): number
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.phaseDegrees
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

function LegAssembly:SetRetiring(retiring: boolean)
	assert(not self.destroyed, "LegAssembly is destroyed")
	local baseName = if self.model:GetAttribute("Side") == "Left" then "LeftLeg" else "RightLeg"
	self.model.Name = if retiring then baseName .. "_Retiring" else baseName
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
	self.legsFolder = nil
	table.clear(self.segments)
	table.clear(self.mappedPoints)
end

return LegAssembly
