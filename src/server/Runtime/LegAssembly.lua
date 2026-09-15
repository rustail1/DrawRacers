--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local CollisionGroups = require(script.Parent:WaitForChild("CollisionGroups"))
local LegCollisionSafety = require(script.Parent:WaitForChild("LegCollisionSafety"))

local RACER_LEG_GROUP = "RacerLeg"
local LEFT_COLOR = Color3.fromRGB(57, 68, 84)
local RIGHT_COLOR = Color3.fromRGB(23, 32, 51)

local LegAssembly = {}
LegAssembly.__index = LegAssembly

type ShapeSpec = StrokeTypes.ShapeSpec

export type BuildParams = {
	container: Instance,
	side: string,
	driveRoot: Part,
}

local function weld(part0: BasePart, part1: BasePart, name: string)
	local link = Instance.new("WeldConstraint")
	link.Name = name
	link.Part0 = part0
	link.Part1 = part1
	link.Parent = part1
end

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
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
	assert(
		type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table",
		"shapeSpec required"
	)
	assert(#shapeSpec.segmentPlan > 0, "shapeSpec needs segments")
	assert(
		#shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg,
		"segment cap exceeded"
	)
end

local function configureVisual(part: Part, color: Color3)
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

local function configurePhysical(part: Part)
	local material = PhysicsConfig.PhysicalMaterials.LegSegment

	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true

	-- Drawn shape must not change racer mass when the player redraws.
	part.Massless = true
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

local function setPhysicalEnabled(
	parts: { Part },
	plan: { any },
	enabled: boolean
)
	for index, part in parts do
		local entry = plan[index]
		part.CanCollide = enabled
			and entry ~= nil
			and entry.canCollide == true
		part.CanTouch = enabled
		part.CanQuery = true
	end
end

local function setVisualVisible(folder: Instance?, visible: boolean)
	if folder == nil then
		return
	end

	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if visible then 0 else 1
		end
	end
end

local function destroyIfPresent(value: Instance?)
	if value ~= nil and value.Parent ~= nil then
		value:Destroy()
	end
end

local function buildVisualSegment(
	self: any,
	parent: Instance,
	a: Vector2,
	b: Vector2,
	name: string
): Part?
	local length = (b - a).Magnitude
	if length <= 1e-4 then
		return nil
	end

	local geometry = PhysicsConfig.LegGeometry
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(
		length + geometry.SegmentOverlapAllowance,
		geometry.VisualLegSegmentThickness,
		geometry.VisualLegSegmentThickness
	)
	part.CFrame = segmentFrame(self.root.CFrame, a, b)
	configureVisual(part, self.visualColor)
	part.Parent = parent
	weld(self.root, part, "RootWeld")
	return part
end

local function buildVisualJoint(
	self: any,
	parent: Instance,
	point: Vector2,
	name: string
): Part
	local thickness = PhysicsConfig.LegGeometry.VisualLegSegmentThickness
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(thickness, thickness, thickness)
	part.CFrame = self.root.CFrame * CFrame.new(point.X, point.Y, 0)
	configureVisual(part, self.visualColor)
	part.Parent = parent
	weld(self.root, part, "RootWeld")
	return part
end

local function updatePreviewSegment(
	self: any,
	part: Part,
	a: Vector2,
	b: Vector2,
	visible: boolean
)
	if not visible then
		part.Transparency = 1
		return
	end

	local length = (b - a).Magnitude
	if length <= 1e-4 then
		part.Transparency = 1
		return
	end

	local geometry = PhysicsConfig.LegGeometry
	part.Size = Vector3.new(
		length + geometry.SegmentOverlapAllowance,
		geometry.VisualLegSegmentThickness,
		geometry.VisualLegSegmentThickness
	)
	part.CFrame = segmentFrame(self.root.CFrame, a, b)
	part.Transparency = 0
end

local function totalPlanLength(plan: { any }): number
	local total = 0
	for _, entry in plan do
		total += (entry.b - entry.a).Magnitude
	end
	return total
end

local function buildFinalPackage(self: any, shapeSpec: ShapeSpec)
	local segmentFolder = makeFolder("BuildSegments", self.model)
	local visualFolder = makeFolder("BuildVisual", self.model)
	local parts = table.create(#shapeSpec.segmentPlan)

	for index, entry in shapeSpec.segmentPlan do
		local length = (entry.b - entry.a).Magnitude
		assert(length > 1e-4, "final segment length must be positive")

		local collider = Instance.new("Part")
		collider.Name = string.format("Segment_%02d", index)
		collider.Size = Vector3.new(
			length + PhysicsConfig.LegGeometry.SegmentOverlapAllowance,
			PhysicsConfig.LegGeometry.PhysicalLegSegmentThickness,
			PhysicsConfig.LegGeometry.PhysicalLegSegmentThickness
		)
		collider.CFrame = segmentFrame(self.root.CFrame, entry.a, entry.b)
		configurePhysical(collider)
		collider.Parent = segmentFolder
		weld(self.root, collider, "RootWeld")
		parts[index] = collider

		buildVisualSegment(
			self,
			visualFolder,
			entry.a,
			entry.b,
			string.format("VisualSegment_%02d", index)
		)
	end

	for index, point in shapeSpec.mappedPoints do
		buildVisualJoint(
			self,
			visualFolder,
			point,
			string.format("VisualJoint_%02d", index)
		)
	end

	setPhysicalEnabled(parts, shapeSpec.segmentPlan, false)
	setVisualVisible(visualFolder, false)

	return {
		shapeSpec = shapeSpec,
		segmentsFolder = segmentFolder,
		visualFolder = visualFolder,
		segments = parts,
		segmentPlan = shapeSpec.segmentPlan,
		mappedPoints = shapeSpec.mappedPoints,
	}
end

function LegAssembly.new(params: BuildParams)
	assert(
		params.side == "Left" or params.side == "Right",
		"side must be Left or Right"
	)
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
		visualColor = if params.side == "Left" then LEFT_COLOR else RIGHT_COLOR,

		segmentsFolder = nil :: Folder?,
		visualFolder = nil :: Folder?,
		segments = {} :: { Part },
		segmentPlan = {} :: { any },
		mappedPoints = {} :: { Vector2 },

		previewFolder = nil :: Folder?,
		previewShapeSpec = nil :: ShapeSpec?,
		previewSegments = {} :: { Part },
		previewTip = nil :: Part?,

		prepared = nil :: any,
		pendingColliderActivation = false,
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

function LegAssembly:ClearCurrentGeometry()
	assert(not self.destroyed, "LegAssembly is destroyed")

	destroyIfPresent(self.segmentsFolder)
	destroyIfPresent(self.visualFolder)

	self.segmentsFolder = nil
	self.visualFolder = nil
	self.segments = {}
	self.segmentPlan = {}
	self.mappedPoints = {}
	self.pendingColliderActivation = false
end

function LegAssembly:InstallGeometry(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShape(shapeSpec)

	self:CancelPreview()
	self:AbortPreparedGeometry()
	self:ClearCurrentGeometry()

	local package = buildFinalPackage(self, shapeSpec)
	setPhysicalEnabled(package.segments, package.segmentPlan, true)
	setVisualVisible(package.visualFolder, true)

	package.segmentsFolder.Name = "Segments"
	package.visualFolder.Name = "Visual"

	self.segmentsFolder = package.segmentsFolder
	self.visualFolder = package.visualFolder
	self.segments = package.segments
	self.segmentPlan = package.segmentPlan
	self.mappedPoints = package.mappedPoints
	self.pendingColliderActivation = false
end

function LegAssembly:InstallGeometryDeferred(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShape(shapeSpec)

	self:CancelPreview()
	self:AbortPreparedGeometry()
	self:ClearCurrentGeometry()

	local package = buildFinalPackage(self, shapeSpec)
	setPhysicalEnabled(package.segments, package.segmentPlan, false)
	setVisualVisible(package.visualFolder, true)

	package.segmentsFolder.Name = "Segments"
	package.visualFolder.Name = "Visual"

	self.segmentsFolder = package.segmentsFolder
	self.visualFolder = package.visualFolder
	self.segments = package.segments
	self.segmentPlan = package.segmentPlan
	self.mappedPoints = package.mappedPoints
	self.pendingColliderActivation = true

	-- Activate anything that is already clear immediately; deeply embedded
	-- segments remain disabled until rotation carries them out of Track.
	self:ActivateClearColliders()
end

function LegAssembly:BeginPreview(shapeSpec: ShapeSpec)
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShape(shapeSpec)

	self:CancelPreview()

	local folder = makeFolder("Preview", self.model)
	local previewSegments = table.create(#shapeSpec.segmentPlan)

	for index, entry in shapeSpec.segmentPlan do
		local part = buildVisualSegment(
			self,
			folder,
			entry.a,
			entry.b,
			string.format("PreviewSegment_%02d", index)
		)
		assert(part ~= nil, "preview segment length must be positive")
		part.Transparency = 1
		previewSegments[index] = part
	end

	local tip = buildVisualJoint(
		self,
		folder,
		shapeSpec.segmentPlan[1].a,
		"PreviewTip"
	)
	tip.Transparency = 1

	self.previewFolder = folder
	self.previewShapeSpec = shapeSpec
	self.previewSegments = previewSegments
	self.previewTip = tip

	self:SetPreviewProgress(0)
end

function LegAssembly:SetPreviewProgress(progress: number)
	assert(not self.destroyed, "LegAssembly is destroyed")

	local shapeSpec = self.previewShapeSpec
	if shapeSpec == nil then
		return
	end

	progress = math.clamp(progress, 0, 1)
	local plan = shapeSpec.segmentPlan
	local totalLength = totalPlanLength(plan)

	if totalLength <= 1e-5 then
		return
	end

	local remaining = totalLength * progress
	local lastPoint: Vector2? = nil

	for index, entry in plan do
		local part = self.previewSegments[index]
		assert(part ~= nil, "preview pool missing segment")

		local length = (entry.b - entry.a).Magnitude

		if remaining <= 0 then
			updatePreviewSegment(self, part, entry.a, entry.b, false)
		elseif remaining >= length then
			updatePreviewSegment(self, part, entry.a, entry.b, true)
			lastPoint = entry.b
			remaining -= length
		else
			local alpha = math.clamp(remaining / math.max(length, 1e-5), 0, 1)
			local endpoint = entry.a:Lerp(entry.b, alpha)
			updatePreviewSegment(self, part, entry.a, endpoint, alpha > 1e-4)
			lastPoint = endpoint
			remaining = 0
		end
	end

	if self.previewTip ~= nil then
		if lastPoint == nil then
			self.previewTip.Transparency = 1
		else
			self.previewTip.CFrame = self.root.CFrame
				* CFrame.new(lastPoint.X, lastPoint.Y, 0)
			self.previewTip.Transparency = 0
		end
	end
end

function LegAssembly:CancelPreview()
	if self.destroyed then
		return
	end

	destroyIfPresent(self.previewFolder)
	self.previewFolder = nil
	self.previewShapeSpec = nil
	self.previewSegments = {}
	self.previewTip = nil
end

function LegAssembly:PrepareFinalGeometry(shapeSpec: ShapeSpec): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")
	validateShape(shapeSpec)

	self:AbortPreparedGeometry()

	local ok, package = pcall(function()
		return buildFinalPackage(self, shapeSpec)
	end)

	if not ok then
		local leakedSegments = self.model:FindFirstChild("BuildSegments")
		if leakedSegments then
			leakedSegments:Destroy()
		end
		local leakedVisual = self.model:FindFirstChild("BuildVisual")
		if leakedVisual then
			leakedVisual:Destroy()
		end
		return false
	end

	self.prepared = package
	return true
end

function LegAssembly:ActivatePreparedGeometryDeferred(): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")

	local package = self.prepared
	if package == nil then
		return false
	end

	self:ClearCurrentGeometry()

	-- Final geometry becomes visible immediately, but all colliders remain OFF.
	-- The shared axle may rotate it out of Track without solver impulses.
	setPhysicalEnabled(package.segments, package.segmentPlan, false)
	setVisualVisible(package.visualFolder, true)

	package.segmentsFolder.Name = "Segments"
	package.visualFolder.Name = "Visual"

	self.segmentsFolder = package.segmentsFolder
	self.visualFolder = package.visualFolder
	self.segments = package.segments
	self.segmentPlan = package.segmentPlan
	self.mappedPoints = package.mappedPoints
	self.prepared = nil
	self.pendingColliderActivation = true

	self:CancelPreview()
	self:ActivateClearColliders()
	return true
end

function LegAssembly:ActivatePreparedGeometry(): boolean
	-- Compatibility for direct unit use: install first, then enable only segments
	-- which are already clear of Track. Runtime uses the deferred method above.
	return self:ActivatePreparedGeometryDeferred()
end

function LegAssembly:ActivateClearColliders(): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")

	if not self.pendingColliderActivation then
		return true
	end

	local stillPending = false

	for index, part in self.segments do
		local entry = self.segmentPlan[index]

		if entry == nil or entry.canCollide ~= true then
			part.CanCollide = false
			part.CanTouch = false
		elseif part.CanCollide then
			-- Once a segment becomes live it stays live; normal wheel/track
			-- collision is allowed from this point onward.
			part.CanTouch = true
		elseif LegCollisionSafety.IsSegmentClearOfTrack(part) then
			part.CanCollide = true
			part.CanTouch = true
		else
			part.CanCollide = false
			part.CanTouch = false
			stillPending = true
		end
	end

	self.pendingColliderActivation = stillPending
	return not stillPending
end

function LegAssembly:HasPendingColliderActivation(): boolean
	assert(not self.destroyed, "LegAssembly is destroyed")
	return self.pendingColliderActivation
end

function LegAssembly:AbortPreparedGeometry()
	if self.destroyed then
		return
	end

	local package = self.prepared
	if package ~= nil then
		destroyIfPresent(package.segmentsFolder)
		destroyIfPresent(package.visualFolder)
	end
	self.prepared = nil
end

function LegAssembly:Destroy()
	if self.destroyed then
		return
	end

	self:CancelPreview()
	self:AbortPreparedGeometry()
	self:ClearCurrentGeometry()
	self.destroyed = true

	if self.model then
		self.model:Destroy()
	end

	self.model = nil
	self.root = nil
	self.driveRoot = nil
	self.segmentsFolder = nil
	self.visualFolder = nil
	self.segments = nil
	self.segmentPlan = nil
	self.mappedPoints = nil
	self.previewFolder = nil
	self.previewShapeSpec = nil
	self.previewSegments = nil
	self.previewTip = nil
	self.prepared = nil
	self.pendingColliderActivation = false
end

return LegAssembly
