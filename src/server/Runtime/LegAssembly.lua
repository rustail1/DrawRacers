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
	container: Instance,
	side: string,
	axleRoot: Part,
	socketZ: number,
	phaseDegrees: number?,
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

local function destroyIfPresent(instance: Instance?)
	if instance ~= nil then
		instance:Destroy()
	end
end

local function clearGeometry(self: any)
	for _, child in self.segmentsFolder:GetChildren() do
		child:Destroy()
	end
	for _, child in self.visualFolder:GetChildren() do
		child:Destroy()
	end

	self.segments = {}
	self.visualSegments = {}
	self.visualJoints = {}
	self.partialCollider = nil
	self.partialColliderWeld = nil
	self.partialVisual = nil
	self.partialVisualWeld = nil
	self.materializedCompleteSegments = 0
end

local function ensureVisualJoint(self: any, index: number, point: Vector2)
	if self.visualJoints[index] ~= nil then
		return self.visualJoints[index]
	end

	local thickness = PhysicsConfig.LegGeometry.VisualLegSegmentThickness
	local joint = Instance.new("Part")
	joint.Name = string.format("VisualJoint_%02d", index)
	joint.Shape = Enum.PartType.Ball
	joint.Size = Vector3.new(thickness, thickness, thickness)
	joint.CFrame = self.root.CFrame * CFrame.new(point.X, point.Y, 0)
	configureVisualPart(joint, self.visualColor)
	joint.Parent = self.visualFolder
	weldParts("RootWeld", self.root, joint, joint)
	self.visualJoints[index] = joint
	return joint
end

local function materializeCompleteSegment(self: any, index: number)
	local planned = self.segmentPlan[index]
	assert(planned ~= nil, "missing canonical segment")
	local a = planned.a
	local b = planned.b
	local mappedLength = (b - a).Magnitude
	local geometry = PhysicsConfig.LegGeometry

	local segment = Instance.new("Part")
	segment.Name = string.format("Segment_%02d", index)
	segment.Size = Vector3.new(
		mappedLength + geometry.SegmentOverlapAllowance,
		geometry.PhysicalLegSegmentThickness,
		geometry.PhysicalLegSegmentThickness
	)
	segment.CFrame = makeSegmentCFrame(self.root.CFrame, a, b)
	configurePhysicalPart(segment, self.legMaterial)
	segment.CanCollide = planned.canCollide == true
	segment.Parent = self.segmentsFolder
	weldParts("RootWeld", self.root, segment, segment)
	self.segments[index] = segment

	local visual = Instance.new("Part")
	visual.Name = string.format("VisualSegment_%02d", index)
	visual.Shape = Enum.PartType.Cylinder
	visual.Size = Vector3.new(
		mappedLength + geometry.SegmentOverlapAllowance,
		geometry.VisualLegSegmentThickness,
		geometry.VisualLegSegmentThickness
	)
	visual.CFrame = makeSegmentCFrame(self.root.CFrame, a, b)
	configureVisualPart(visual, self.visualColor)
	visual.Parent = self.visualFolder
	weldParts("RootWeld", self.root, visual, visual)
	self.visualSegments[index] = visual

	ensureVisualJoint(self, index, a)
	ensureVisualJoint(self, index + 1, b)
end

local function destroyPartialTip(self: any)
	destroyIfPresent(self.partialCollider)
	destroyIfPresent(self.partialVisual)
	self.partialCollider = nil
	self.partialColliderWeld = nil
	self.partialVisual = nil
	self.partialVisualWeld = nil
end

local function ensurePartialTip(self: any)
	if self.partialCollider == nil then
		local geometry = PhysicsConfig.LegGeometry
		local collider = Instance.new("Part")
		collider.Name = "ReshapeTipCollider"
		collider.Size = Vector3.new(
			MIN_DYNAMIC_LENGTH,
			geometry.PhysicalLegSegmentThickness,
			geometry.PhysicalLegSegmentThickness
		)
		collider.CFrame = self.root.CFrame
		configurePhysicalPart(collider, self.legMaterial)
		collider.CanCollide = false
		collider.Parent = self.segmentsFolder
		self.partialCollider = collider
		self.partialColliderWeld = dynamicWeld("ReshapeTipWeld", self.root, collider)
	end

	if self.partialVisual == nil then
		local geometry = PhysicsConfig.LegGeometry
		local visual = Instance.new("Part")
		visual.Name = "ReshapeTipVisual"
		visual.Shape = Enum.PartType.Cylinder
		visual.Size = Vector3.new(
			MIN_DYNAMIC_LENGTH,
			geometry.VisualLegSegmentThickness,
			geometry.VisualLegSegmentThickness
		)
		visual.CFrame = self.root.CFrame
		configureVisualPart(visual, self.visualColor)
		visual.Parent = self.visualFolder
		self.partialVisual = visual
		self.partialVisualWeld = dynamicWeld("ReshapeTipVisualWeld", self.root, visual)
	end
end

local function updatePartialTip(self: any, index: number?, endpoint: Vector2?)
	if index == nil or endpoint == nil then
		destroyPartialTip(self)
		return
	end

	local planned = self.segmentPlan[index]
	assert(planned ~= nil, "partial reshape references missing canonical segment")
	local a = planned.a
	local visibleLength = (endpoint - a).Magnitude
	if visibleLength <= MIN_DYNAMIC_LENGTH then
		destroyPartialTip(self)
		return
	end

	ensurePartialTip(self)
	local geometry = PhysicsConfig.LegGeometry
	local collider = self.partialCollider :: Part
	local colliderWeld = self.partialColliderWeld :: Weld
	collider.Size = Vector3.new(
		visibleLength,
		geometry.PhysicalLegSegmentThickness,
		geometry.PhysicalLegSegmentThickness
	)
	setDynamicFrame(self.root, collider, colliderWeld, a, endpoint)
	collider.CanCollide = planned.canCollide == true
	collider.CanTouch = true
	collider.CanQuery = true
	collider.Massless = false

	local visual = self.partialVisual :: Part
	local visualWeld = self.partialVisualWeld :: Weld
	visual.Size = Vector3.new(
		visibleLength,
		geometry.VisualLegSegmentThickness,
		geometry.VisualLegSegmentThickness
	)
	setDynamicFrame(self.root, visual, visualWeld, a, endpoint)
end

local function validateShapeSpec(shapeSpec: ShapeSpec)
	assert(type(shapeSpec) == "table", "LegAssembly requires authoritative shapeSpec")
	assert(type(shapeSpec.segmentPlan) == "table", "shapeSpec missing segmentPlan")
	assert(#shapeSpec.segmentPlan > 0, "LegAssembly requires at least one planned segment")
	assert(
		#shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg,
		"shapeSpec segmentPlan exceeds collider cap"
	)
	assert(type(shapeSpec.mappedPoints) == "table", "shapeSpec missing mappedPoints")

	for _, planned in shapeSpec.segmentPlan do
		local a = planned.a
		local b = planned.b
		assert(typeof(a) == "Vector2" and typeof(b) == "Vector2", "shapeSpec segmentPlan contains invalid endpoints")
		assert(
			(b - a).Magnitude >= PhysicsConfig.LegGeometry.MinimumMappedSegmentLength,
			"shapeSpec contains sub-minimum segment"
		)
	end
end

function LegAssembly.new(params: BuildParams)
	assert(params.side == "Left" or params.side == "Right", "LegAssembly side must be Left or Right")
	assert(params.container ~= nil, "LegAssembly requires a container")
	assert(params.axleRoot:IsA("Part"), "LegAssembly requires shared axle root")

	CollisionGroups.ensure()

	local side = params.side
	local legName = if side == "Left" then "LeftLeg" else "RightLeg"
	assert(params.container:FindFirstChild(legName) == nil, "LegAssembly side already exists in container")

	local phaseDegrees = params.phaseDegrees or 0
	local visualColor = if side == "Left" then BACK_VISUAL_COLOR else FRONT_VISUAL_COLOR
	local model = Instance.new("Model")
	model.Name = legName
	model:SetAttribute("Side", side)
	model:SetAttribute("StructuralPhaseDegrees", phaseDegrees)
	model.Parent = params.container

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

	return setmetatable({
		model = model,
		root = root,
		segmentsFolder = segmentsFolder,
		visualFolder = visualFolder,
		segments = {},
		visualSegments = {},
		visualJoints = {},
		partialCollider = nil,
		partialColliderWeld = nil,
		partialVisual = nil,
		partialVisualWeld = nil,
		segmentPlan = nil,
		mappedPoints = {},
		materializedCompleteSegments = 0,
		phaseDegrees = phaseDegrees,
		visualColor = visualColor,
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

function LegAssembly:GetStructuralPhaseDegrees(): number
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.phaseDegrees
end

function LegAssembly:ReplaceGeometry(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShapeSpec(shapeSpec)

	clearGeometry(self)
	self.segmentPlan = shapeSpec.segmentPlan
	self.mappedPoints = shapeSpec.mappedPoints
	self.materializedCompleteSegments = 0
	return self:SetReshapeProgress(0)
end

function LegAssembly:SetReshapeProgress(progress: number)
	assert(not self.destroyed, "LegAssembly is destroyed")
	assert(type(self.segmentPlan) == "table" and #self.segmentPlan > 0, "LegAssembly has no geometry")

	local state = LegReshapeMath.Evaluate(self.segmentPlan, progress)
	if state.completeSegments < self.materializedCompleteSegments then
		clearGeometry(self)
	end

	local firstSegment = self.segmentPlan[1]
	if firstSegment ~= nil then
		ensureVisualJoint(self, 1, firstSegment.a)
	end

	for index = self.materializedCompleteSegments + 1, state.completeSegments do
		materializeCompleteSegment(self, index)
	end
	self.materializedCompleteSegments = state.completeSegments

	updatePartialTip(self, state.partialSegmentIndex, state.partialEndpoint)
	return state
end

function LegAssembly:CompleteReshape()
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self:SetReshapeProgress(1)
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
	self.segmentsFolder = nil
	self.visualFolder = nil
	self.segments = nil
	self.visualSegments = nil
	self.visualJoints = nil
	self.partialCollider = nil
	self.partialColliderWeld = nil
	self.partialVisual = nil
	self.partialVisualWeld = nil
	self.segmentPlan = nil
	self.mappedPoints = nil
end

return LegAssembly
