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
local MIN_DYNAMIC_LENGTH = 0.001

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

local function configurePhysicalPart(segment: Part, legMaterial: any)
	segment.Anchored = false
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
end

local function weldParts(name: string, part0: BasePart, part1: BasePart, parent: Instance)
	local weld = Instance.new("WeldConstraint")
	weld.Name = name
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = parent
	return weld
end

local function dynamicWeld(name: string, root: BasePart, part: BasePart): Weld
	local weld = Instance.new("Weld")
	weld.Name = name
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = root.CFrame:ToObjectSpace(part.CFrame)
	weld.C1 = CFrame.identity
	weld.Parent = part
	return weld
end

local function setDynamicFrame(root: Part, part: Part, weld: Weld, a: Vector2, b: Vector2)
	part.CFrame = makeSegmentCFrame(root.CFrame, a, b)
	weld.C0 = root.CFrame:ToObjectSpace(part.CFrame)
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
	local visualThickness = geometry.VisualLegSegmentThickness

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
	local segmentCanCollide = {}
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
		configurePhysicalPart(segment, legMaterial)
		segment.CanCollide = planned.canCollide == true
		segment.Parent = segmentsFolder
		weldParts("RootWeld", root, segment, segment)
		table.insert(segments, segment)
		table.insert(segmentCanCollide, planned.canCollide == true)
	end

	assert(#segments > 0, "LegAssembly produced no legal physical segments")

	local mappedPoints = params.shapeSpec.mappedPoints or {}
	local visualJoints = {}
	for index, point in mappedPoints do
		local visual = Instance.new("Part")
		visual.Name = string.format("VisualJoint_%02d", index)
		visual.Shape = Enum.PartType.Ball
		visual.Size = Vector3.new(visualThickness, visualThickness, visualThickness)
		visual.CFrame = root.CFrame * CFrame.new(point.X, point.Y, 0)
		configureVisualPart(visual, visualColor)
		visual.Parent = visualFolder
		weldParts("RootWeld", root, visual, visual)
		table.insert(visualJoints, visual)
	end

	local visualSegments = {}
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
		table.insert(visualSegments, visual)
	end

	-- RCP-04 keeps full completed segments rigid and uses one temporary tip segment
	-- for the only segment currently growing. This avoids mutating WeldConstraint
	-- offsets on already-completed geometry while still producing true a->endpoint growth.
	local partialCollider = Instance.new("Part")
	partialCollider.Name = "ReshapeTipCollider"
	partialCollider.Size = Vector3.new(MIN_DYNAMIC_LENGTH, geometry.PhysicalLegSegmentThickness, geometry.PhysicalLegSegmentThickness)
	partialCollider.CFrame = root.CFrame
	configurePhysicalPart(partialCollider, legMaterial)
	partialCollider.CanCollide = false
	partialCollider.CanTouch = false
	partialCollider.CanQuery = false
	partialCollider.Massless = true
	partialCollider.Parent = segmentsFolder
	local partialColliderWeld = dynamicWeld("ReshapeTipWeld", root, partialCollider)

	local partialVisual = Instance.new("Part")
	partialVisual.Name = "ReshapeTipVisual"
	partialVisual.Shape = Enum.PartType.Cylinder
	partialVisual.Size = Vector3.new(MIN_DYNAMIC_LENGTH, visualThickness, visualThickness)
	partialVisual.CFrame = root.CFrame
	configureVisualPart(partialVisual, visualColor)
	partialVisual.Transparency = 1
	partialVisual.Parent = visualFolder
	local partialVisualWeld = dynamicWeld("ReshapeTipVisualWeld", root, partialVisual)

	local self = setmetatable({
		model = model,
		root = root,
		segments = segments,
		segmentCanCollide = segmentCanCollide,
		segmentPlan = params.shapeSpec.segmentPlan,
		visualSegments = visualSegments,
		visualJoints = visualJoints,
		partialCollider = partialCollider,
		partialColliderWeld = partialColliderWeld,
		partialVisual = partialVisual,
		partialVisualWeld = partialVisualWeld,
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

function LegAssembly:SetReshapeProgress(progress: number)
	assert(not self.destroyed, "LegAssembly is destroyed")
	local state = LegReshapeMath.Evaluate(self.segmentPlan, progress)
	local geometry = PhysicsConfig.LegGeometry

	for index, segment in self.segments do
		local complete = index <= state.completeSegments
		segment.CanCollide = complete and self.segmentCanCollide[index] == true
		segment.CanTouch = complete
		segment.CanQuery = complete
		segment.Massless = not complete
		self.visualSegments[index].Transparency = if complete then 0 else 1
	end

	for index, joint in self.visualJoints do
		-- point 1 is the hub. Each later point appears only when the preceding
		-- canonical segment has completed, so no future geometry flashes early.
		joint.Transparency = if index == 1 or (index - 1) <= state.completeSegments then 0 else 1
	end

	local partialIndex = state.partialSegmentIndex
	local endpoint = state.partialEndpoint
	if partialIndex ~= nil and endpoint ~= nil then
		local planned = self.segmentPlan[partialIndex]
		local a = planned.a
		local visibleLength = (endpoint - a).Magnitude
		if visibleLength > MIN_DYNAMIC_LENGTH then
			local segment = self.partialCollider
			segment.Size = Vector3.new(
				visibleLength,
				geometry.PhysicalLegSegmentThickness,
				geometry.PhysicalLegSegmentThickness
			)
			setDynamicFrame(self.root, segment, self.partialColliderWeld, a, endpoint)
			segment.CanCollide = visibleLength > MIN_DYNAMIC_LENGTH and planned.canCollide == true
			segment.CanTouch = true
			segment.CanQuery = true
			segment.Massless = false

			self.partialVisual.Size = Vector3.new(visibleLength, geometry.VisualLegSegmentThickness, geometry.VisualLegSegmentThickness)
			setDynamicFrame(self.root, self.partialVisual, self.partialVisualWeld, a, endpoint)
			self.partialVisual.Transparency = 0
		else
			self.partialCollider.CanCollide = false
			self.partialCollider.CanTouch = false
			self.partialCollider.CanQuery = false
			self.partialCollider.Massless = true
			self.partialVisual.Transparency = 1
		end
	else
		self.partialCollider.CanCollide = false
		self.partialCollider.CanTouch = false
		self.partialCollider.CanQuery = false
		self.partialCollider.Massless = true
		self.partialVisual.Transparency = 1
	end

	return state
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
	self.partialCollider = nil
	self.partialVisual = nil
	self.partialColliderWeld = nil
	self.partialVisualWeld = nil
	table.clear(self.segments)
	table.clear(self.segmentCanCollide)
	table.clear(self.segmentPlan)
	table.clear(self.visualSegments)
	table.clear(self.visualJoints)
	table.clear(self.mappedPoints)
end

return LegAssembly
