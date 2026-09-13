--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig"))
local LegReshapeMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("LegReshapeMath"))
local StrokeTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes"))
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))

local RACER_LEG_GROUP = "RacerLeg"
local FRONT_VISUAL_COLOR = Color3.fromRGB(23, 32, 51)
local BACK_VISUAL_COLOR = Color3.fromRGB(57, 68, 84)

local LegAssembly = {}
LegAssembly.__index = LegAssembly

type ShapeSpec = StrokeTypes.ShapeSpec
export type BuildParams = { container: Instance, side: string, driveRoot: Part }

local function rotatePoint(point: Vector2, degrees: number): Vector2
	if math.abs(degrees) <= 1e-6 then return point end
	local r = math.rad(degrees)
	local c, s = math.cos(r), math.sin(r)
	return Vector2.new(point.X * c - point.Y * s, point.X * s + point.Y * c)
end

local function segmentFrame(root: CFrame, a: Vector2, b: Vector2): CFrame
	local direction = (b - a).Unit
	local xAxis = Vector3.new(direction.X, direction.Y, 0)
	local zAxis = Vector3.zAxis
	local yAxis = zAxis:Cross(xAxis)
	local midpoint = (a + b) * 0.5
	return root * CFrame.fromMatrix(Vector3.new(midpoint.X, midpoint.Y, 0), xAxis, yAxis, zAxis)
end

local function weld(root: BasePart, child: BasePart, name: string)
	local link = Instance.new("WeldConstraint")
	link.Name = name
	link.Part0 = root
	link.Part1 = child
	link.Parent = child
end

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function configureVisual(visual: Part, color: Color3)
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

local function configurePhysical(part: Part, material: any)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Massless = false
	part.CollisionGroup = RACER_LEG_GROUP
	part.CustomPhysicalProperties = PhysicalProperties.new(
		material.Density, material.Friction, material.Elasticity,
		material.FrictionWeight, material.ElasticityWeight
	)
	part.Transparency = 1
end

local function validateShape(shapeSpec: ShapeSpec)
	assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table", "shapeSpec required")
	assert(#shapeSpec.segmentPlan > 0, "shapeSpec needs segments")
	assert(#shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg, "segment cap exceeded")
end

local function transformPlan(shapeSpec: ShapeSpec, offset: number): { any }
	local plan = table.create(#shapeSpec.segmentPlan)
	for index, source in shapeSpec.segmentPlan do
		plan[index] = {
			index = source.index,
			a = rotatePoint(source.a, offset),
			b = rotatePoint(source.b, offset),
			canCollide = source.canCollide,
		}
	end
	return plan
end

local function transformPoints(shapeSpec: ShapeSpec, offset: number): { Vector2 }
	local result = table.create(#shapeSpec.mappedPoints)
	for index, point in shapeSpec.mappedPoints do result[index] = rotatePoint(point, offset) end
	return result
end

local function buildVisualSegment(self: any, parent: Instance, a: Vector2, b: Vector2, name: string)
	local length = (b - a).Magnitude
	if length <= 1e-4 then return end
	local geometry = PhysicsConfig.LegGeometry
	local visual = Instance.new("Part")
	visual.Name = name
	visual.Shape = Enum.PartType.Cylinder
	visual.Size = Vector3.new(length + geometry.SegmentOverlapAllowance, geometry.VisualLegSegmentThickness, geometry.VisualLegSegmentThickness)
	visual.CFrame = segmentFrame(self.root.CFrame, a, b)
	configureVisual(visual, self.visualColor)
	visual.Parent = parent
	weld(self.root, visual, "RootWeld")
end

local function buildVisualJoint(self: any, parent: Instance, point: Vector2, index: number)
	local thickness = PhysicsConfig.LegGeometry.VisualLegSegmentThickness
	local visual = Instance.new("Part")
	visual.Name = string.format("VisualJoint_%02d", index)
	visual.Shape = Enum.PartType.Ball
	visual.Size = Vector3.new(thickness, thickness, thickness)
	visual.CFrame = self.root.CFrame * CFrame.new(point.X, point.Y, 0)
	configureVisual(visual, self.visualColor)
	visual.Parent = parent
	weld(self.root, visual, "RootWeld")
end

local function buildFull(self: any, shapeSpec: ShapeSpec, offset: number, pending: boolean)
	local geometry = PhysicsConfig.LegGeometry
	local plan = transformPlan(shapeSpec, offset)
	local segmentsFolder = makeFolder(if pending then "PendingSegments" else "Segments", self.model)
	local visualFolder = makeFolder(if pending then "PendingVisual" else "Visual", self.model)
	local parts = table.create(#plan)
	for index, entry in plan do
		local length = (entry.b - entry.a).Magnitude
		local part = Instance.new("Part")
		part.Name = string.format("Segment_%02d", index)
		part.Size = Vector3.new(length + geometry.SegmentOverlapAllowance, geometry.PhysicalLegSegmentThickness, geometry.PhysicalLegSegmentThickness)
		part.CFrame = segmentFrame(self.root.CFrame, entry.a, entry.b)
		configurePhysical(part, self.legMaterial)
		part.Parent = segmentsFolder
		weld(self.root, part, "RootWeld")
		parts[index] = part
		buildVisualSegment(self, visualFolder, entry.a, entry.b, string.format("VisualSegment_%02d", index))
	end
	for index, point in transformPoints(shapeSpec, offset) do buildVisualJoint(self, visualFolder, point, index) end
	return segmentsFolder, visualFolder, parts, plan
end

local function setPhysicalEnabled(parts: { Part }, plan: { any }, enabled: boolean)
	for index, part in parts do
		local entry = plan[index]
		part.CanCollide = enabled and entry ~= nil and entry.canCollide == true
		part.CanTouch = enabled
		part.CanQuery = true
	end
end

local function clearStage(self: any)
	if self.stageVisualFolder then self.stageVisualFolder:Destroy() end
	self.stageVisualFolder = nil
end

function LegAssembly.new(params: BuildParams)
	assert(params.side == "Left" or params.side == "Right", "side must be Left/Right")
	assert(params.driveRoot:IsA("Part"), "driveRoot required")
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
	weld(params.driveRoot, root, "DriveWeld")
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

function LegAssembly:GetModel(): Model assert(not self.destroyed); return self.model end
function LegAssembly:GetRoot(): Part assert(not self.destroyed); return self.root end
function LegAssembly:GetSegments(): { Part } assert(not self.destroyed); return self.segments end
function LegAssembly:GetMappedPoints(): { Vector2 } assert(not self.destroyed); return self.mappedPoints end

function LegAssembly:InstallGeometry(shapeSpec: ShapeSpec, mountOffsetDegrees: number?)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShape(shapeSpec)
	local offset = mountOffsetDegrees or 0
	if self.segmentsFolder then self.segmentsFolder:Destroy() end
	if self.visualFolder then self.visualFolder:Destroy() end
	clearStage(self)
	local segmentsFolder, visualFolder, parts, plan = buildFull(self, shapeSpec, offset, false)
	setPhysicalEnabled(parts, plan, true)
	self.segmentsFolder, self.visualFolder, self.segments, self.segmentPlan = segmentsFolder, visualFolder, parts, plan
	self.mappedPoints = transformPoints(shapeSpec, offset)
	self.mountOffsetDegrees = offset
end

function LegAssembly:StageGeometry(shapeSpec: ShapeSpec, mountOffsetDegrees: number?)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShape(shapeSpec)
	self.stageShapeSpec = shapeSpec
	self.stageOffsetDegrees = mountOffsetDegrees or 0
	self:SetStageProgress(0)
end

function LegAssembly:SetStageProgress(progress: number)
	assert(not self.destroyed, "LegAssembly is destroyed")
	local shapeSpec = self.stageShapeSpec
	if shapeSpec == nil then return end
	clearStage(self)
	local folder = makeFolder("StageVisual", self.model)
	self.stageVisualFolder = folder
	local plan = transformPlan(shapeSpec, self.stageOffsetDegrees)
	local state = LegReshapeMath.Evaluate(plan, math.clamp(progress, 0, 1))
	for index = 1, state.completeSegments do
		local entry = plan[index]
		buildVisualSegment(self, folder, entry.a, entry.b, string.format("StageSegment_%02d", index))
	end
	if state.partialSegmentIndex ~= nil and state.partialEndpoint ~= nil then
		local entry = plan[state.partialSegmentIndex]
		local endpoint = state.partialEndpoint
		if entry ~= nil and (endpoint - entry.a).Magnitude > 1e-4 then
			buildVisualSegment(self, folder, entry.a, endpoint, "StageTipVisual")
		end
	end
end

function LegAssembly:CommitStagedGeometry(): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")
	local shapeSpec = self.stageShapeSpec
	if shapeSpec == nil then return false end
	local offset = self.stageOffsetDegrees
	local pendingSegments, pendingVisual, pendingParts, pendingPlan = buildFull(self, shapeSpec, offset, true)
	setPhysicalEnabled(self.segments, self.segmentPlan, false)
	setPhysicalEnabled(pendingParts, pendingPlan, true)
	if self.segmentsFolder then self.segmentsFolder:Destroy() end
	if self.visualFolder then self.visualFolder:Destroy() end
	pendingSegments.Name = "Segments"
	pendingVisual.Name = "Visual"
	self.segmentsFolder, self.visualFolder, self.segments, self.segmentPlan = pendingSegments, pendingVisual, pendingParts, pendingPlan
	self.mappedPoints = transformPoints(shapeSpec, offset)
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
