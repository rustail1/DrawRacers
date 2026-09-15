--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local LegCoreConfig = require(script.Parent:WaitForChild("LegCoreConfig"))
local CollisionGroups = require(script.Parent.Parent:WaitForChild("CollisionGroups"))

local LegGeometry = {}
LegGeometry.__index = LegGeometry

type ShapeSpec = StrokeTypes.ShapeSpec
type SegmentPlanEntry = StrokeTypes.ShapeSegmentPlanEntry

local LEFT_COLOR = Color3.fromRGB(57, 68, 84)
local RIGHT_COLOR = Color3.fromRGB(23, 32, 51)
local MIN_SEGMENT_LENGTH = 1e-4

local function weld(part0: BasePart, part1: BasePart, name: string): WeldConstraint
	local constraint = Instance.new("WeldConstraint")
	constraint.Name = name
	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Parent = part1
	return constraint
end

local function segmentFrame(root: CFrame, a: Vector2, b: Vector2): CFrame
	local delta = b - a
	local direction = delta.Unit
	local xAxis = Vector3.new(direction.X, direction.Y, 0)
	local zAxis = Vector3.zAxis
	local yAxis = zAxis:Cross(xAxis)
	local midpoint = (a + b) * 0.5

	return root * CFrame.fromMatrix(
		Vector3.new(midpoint.X, midpoint.Y, 0),
		xAxis,
		yAxis,
		zAxis
	)
end

local function validateShape(shapeSpec: ShapeSpec)
	assert(type(shapeSpec) == "table", "LegGeometry requires shapeSpec")
	assert(type(shapeSpec.segmentPlan) == "table", "shapeSpec.segmentPlan required")
	assert(type(shapeSpec.mappedPoints) == "table", "shapeSpec.mappedPoints required")
	assert(#shapeSpec.segmentPlan > 0, "shapeSpec needs segments")
	assert(#shapeSpec.segmentPlan <= LegCoreConfig.Geometry.MaxSegments, "Core V3 segment cap exceeded")

	for _, entry in shapeSpec.segmentPlan do
		assert(typeof(entry.a) == "Vector2" and typeof(entry.b) == "Vector2", "segment endpoints must be Vector2")
		assert((entry.b - entry.a).Magnitude > MIN_SEGMENT_LENGTH, "segment length must be positive")
	end
end

local function copyMappedPoints(points: { Vector2 }): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = point
	end
	return result
end

local function configureVisual(part: Part, color: Color3)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CollisionGroup = CollisionGroups.RacerLeg
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.CastShadow = false
end

local function configurePhysical(part: Part)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Massless = true
	part.CollisionGroup = CollisionGroups.RacerLeg
	local material = LegCoreConfig.Materials.Leg
	part.CustomPhysicalProperties = PhysicalProperties.new(
		material.Density,
		material.Friction,
		material.Elasticity,
		material.FrictionWeight,
		material.ElasticityWeight
	)
	part.Transparency = 1
	part.CastShadow = false
end

local function totalPlanLength(plan: { SegmentPlanEntry }): number
	local total = 0
	for _, entry in plan do
		total += (entry.b - entry.a).Magnitude
	end
	return total
end

local function destroyIfPresent(instance: Instance?)
	if instance ~= nil then
		instance:Destroy()
	end
end

function LegGeometry.new(mount: Part, side: string)
	assert(mount:IsA("Part"), "LegGeometry requires mount Part")
	assert(side == "Left" or side == "Right", "side must be Left or Right")
	CollisionGroups.ensure()

	local model = Instance.new("Model")
	model.Name = if side == "Left" then "LeftLeg" else "RightLeg"
	model:SetAttribute("CoreV3Leg", true)
	model:SetAttribute("Side", side)
	model.Parent = mount

	return setmetatable({
		mount = mount,
		side = side,
		model = model,
		visualColor = if side == "Left" then LEFT_COLOR else RIGHT_COLOR,
		previewFolder = nil :: Folder?,
		previewSegments = {} :: { Part },
		previewPlan = {} :: { SegmentPlanEntry },
		physicalFolder = nil :: Folder?,
		physicalSegments = {} :: { Part },
		physicalPlan = {} :: { SegmentPlanEntry },
		mappedPoints = {} :: { Vector2 },
		destroyed = false,
	}, LegGeometry)
end

function LegGeometry:BuildPreview(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegGeometry is destroyed")
	validateShape(shapeSpec)

	self:DestroyPreview()

	local folder = Instance.new("Folder")
	folder.Name = "Preview"
	folder.Parent = self.model

	local parts = table.create(#shapeSpec.segmentPlan)
	for index, entry in shapeSpec.segmentPlan do
		local length = (entry.b - entry.a).Magnitude
		local part = Instance.new("Part")
		part.Name = string.format("PreviewSegment_%02d", index)
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(
			length + LegCoreConfig.Geometry.SegmentOverlapAllowance,
			LegCoreConfig.Geometry.VisualThickness,
			LegCoreConfig.Geometry.VisualThickness
		)
		part.CFrame = segmentFrame(self.mount.CFrame, entry.a, entry.b)
		part.Transparency = 1
		configureVisual(part, self.visualColor)
		part.Parent = folder
		weld(self.mount, part, "MountWeld")
		parts[index] = part
	end

	self.previewFolder = folder
	self.previewSegments = parts
	self.previewPlan = shapeSpec.segmentPlan
	self.mappedPoints = copyMappedPoints(shapeSpec.mappedPoints)
	self:SetPreviewProgress(0)
end

function LegGeometry:SetPreviewProgress(alpha: number)
	assert(not self.destroyed, "LegGeometry is destroyed")
	assert(type(alpha) == "number", "preview alpha must be number")

	if self.previewFolder == nil then
		return
	end

	alpha = math.clamp(alpha, 0, 1)
	local totalLength = totalPlanLength(self.previewPlan)
	if totalLength <= MIN_SEGMENT_LENGTH then
		return
	end

	local remaining = totalLength * alpha
	for index, entry in self.previewPlan do
		local part = self.previewSegments[index]
		assert(part ~= nil, "preview pool missing segment")
		local length = (entry.b - entry.a).Magnitude

		if remaining <= 0 then
			part.Transparency = 1
		elseif remaining >= length then
			part.Size = Vector3.new(
				length + LegCoreConfig.Geometry.SegmentOverlapAllowance,
				LegCoreConfig.Geometry.VisualThickness,
				LegCoreConfig.Geometry.VisualThickness
			)
			part.CFrame = segmentFrame(self.mount.CFrame, entry.a, entry.b)
			part.Transparency = 0
			remaining -= length
		else
			local segmentAlpha = math.clamp(remaining / length, 0, 1)
			local endpoint = entry.a:Lerp(entry.b, segmentAlpha)
			local visibleLength = (endpoint - entry.a).Magnitude
			part.Size = Vector3.new(
				visibleLength + LegCoreConfig.Geometry.SegmentOverlapAllowance,
				LegCoreConfig.Geometry.VisualThickness,
				LegCoreConfig.Geometry.VisualThickness
			)
			part.CFrame = segmentFrame(self.mount.CFrame, entry.a, endpoint)
			part.Transparency = if visibleLength > MIN_SEGMENT_LENGTH then 0 else 1
			remaining = 0
		end
	end
end

function LegGeometry:BuildPhysical(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegGeometry is destroyed")
	validateShape(shapeSpec)

	self:DestroyPhysical()

	local folder = Instance.new("Folder")
	folder.Name = "Physical"
	folder.Parent = self.model

	local parts = table.create(#shapeSpec.segmentPlan)
	for index, entry in shapeSpec.segmentPlan do
		local length = (entry.b - entry.a).Magnitude
		local part = Instance.new("Part")
		part.Name = string.format("PhysicalSegment_%02d", index)
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(
			length + LegCoreConfig.Geometry.SegmentOverlapAllowance,
			LegCoreConfig.Geometry.PhysicalThickness,
			LegCoreConfig.Geometry.PhysicalThickness
		)
		part.CFrame = segmentFrame(self.mount.CFrame, entry.a, entry.b)
		configurePhysical(part)
		part.Parent = folder
		weld(self.mount, part, "MountWeld")
		parts[index] = part
	end

	self.physicalFolder = folder
	self.physicalSegments = parts
	self.physicalPlan = shapeSpec.segmentPlan
	self.mappedPoints = copyMappedPoints(shapeSpec.mappedPoints)
	self:SetPhysicsEnabled(false)
end

function LegGeometry:SetPhysicsEnabled(enabled: boolean)
	assert(not self.destroyed, "LegGeometry is destroyed")
	assert(type(enabled) == "boolean", "enabled must be boolean")

	for index, part in self.physicalSegments do
		local entry = self.physicalPlan[index]
		local authoritativeEnabled = enabled and entry ~= nil and entry.canCollide == true
		part.CanCollide = authoritativeEnabled
		part.CanTouch = authoritativeEnabled
		part.CanQuery = true
	end
end

function LegGeometry:DestroyPreview()
	if self.destroyed then
		return
	end

	destroyIfPresent(self.previewFolder)
	self.previewFolder = nil
	self.previewSegments = {}
	self.previewPlan = {}
end

function LegGeometry:DestroyPhysical()
	if self.destroyed then
		return
	end

	destroyIfPresent(self.physicalFolder)
	self.physicalFolder = nil
	self.physicalSegments = {}
	self.physicalPlan = {}
end

function LegGeometry:Destroy()
	if self.destroyed then
		return
	end

	self:DestroyPreview()
	self:DestroyPhysical()
	self.destroyed = true
	self.mappedPoints = {}
	self.model:Destroy()
	self.model = nil
	self.mount = nil
end

function LegGeometry:GetPhysicalSegments(): { BasePart }
	assert(not self.destroyed, "LegGeometry is destroyed")
	local result = table.create(#self.physicalSegments)
	for index, part in self.physicalSegments do
		result[index] = part
	end
	return result
end

function LegGeometry:GetCollisionSegments(): { BasePart }
	assert(not self.destroyed, "LegGeometry is destroyed")
	local result = {} :: { BasePart }
	for index, part in self.physicalSegments do
		local entry = self.physicalPlan[index]
		if entry ~= nil and entry.canCollide == true then
			table.insert(result, part)
		end
	end
	return result
end

function LegGeometry:GetMappedPoints(): { Vector2 }
	assert(not self.destroyed, "LegGeometry is destroyed")
	return copyMappedPoints(self.mappedPoints)
end

return LegGeometry
