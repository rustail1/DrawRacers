--!strict

local LegCoreConfig = require(script.Parent:WaitForChild("LegCoreConfig"))

local LaneConstraint = {}
LaneConstraint.__index = LaneConstraint

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function configureReference(part: Part)
	part.Name = "LaneReference"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.CastShadow = false
end

function LaneConstraint.new(body: Part, container: Instance, laneCenterZ: number)
	assert(body ~= nil and body:IsA("Part"), "LaneConstraint requires BodyCollider Part")
	assert(container ~= nil, "LaneConstraint requires container")
	assert(type(laneCenterZ) == "number" and isFinite(laneCenterZ), "laneCenterZ must be finite")
	assert(container:FindFirstChild("CoreV3LaneConstraint") == nil, "racer already owns CoreV3LaneConstraint")

	local model = Instance.new("Model")
	model.Name = "CoreV3LaneConstraint"
	model.Parent = container

	local reference = Instance.new("Part")
	configureReference(reference)
	-- PlaneConstraint uses Attachment0's primary axis as its plane normal.
	-- A world-Z normal leaves world X/Y as the two free tangent directions.
	reference.CFrame = CFrame.new(body.Position.X, body.Position.Y, laneCenterZ)
	reference.Parent = model

	local referenceAttachment = Instance.new("Attachment")
	referenceAttachment.Name = "LaneReferenceAttachment"
	referenceAttachment.Axis = Vector3.zAxis
	referenceAttachment.SecondaryAxis = Vector3.xAxis
	referenceAttachment.Parent = reference

	local bodyPlaneAttachment = Instance.new("Attachment")
	bodyPlaneAttachment.Name = "CoreV3LaneBodyAttachment"
	bodyPlaneAttachment.Axis = Vector3.zAxis
	bodyPlaneAttachment.SecondaryAxis = Vector3.xAxis
	bodyPlaneAttachment.Parent = body

	local plane = Instance.new("PlaneConstraint")
	plane.Name = "LanePlane"
	plane.Attachment0 = referenceAttachment
	plane.Attachment1 = bodyPlaneAttachment
	plane.Enabled = true
	plane.Parent = model

	local uprightAttachment = Instance.new("Attachment")
	uprightAttachment.Name = "CoreV3UprightAttachment"
	uprightAttachment.Axis = Vector3.xAxis
	uprightAttachment.SecondaryAxis = Vector3.yAxis
	uprightAttachment.Parent = body

	local upright = Instance.new("AlignOrientation")
	upright.Name = "UprightOrientation"
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.AlignType = Enum.AlignType.AllAxes
	upright.Attachment0 = uprightAttachment
	upright.CFrame = CFrame.new()
	upright.ReactionTorqueEnabled = false
	-- Body-only rigid alignment makes visible chassis tilt negligible. This
	-- constraint owns orientation only; PlaneConstraint still leaves X/Y free,
	-- and the SharedAxle is not attached to this AlignOrientation.
	upright.RigidityEnabled = true
	upright.MaxTorque = LegCoreConfig.Lane.UprightMaxTorque
	upright.MaxAngularVelocity = LegCoreConfig.Lane.UprightMaxAngularVelocity
	upright.Responsiveness = LegCoreConfig.Lane.UprightResponsiveness
	upright.Enabled = true
	upright.Parent = model

	return setmetatable({
		model = model,
		body = body,
		laneCenterZ = laneCenterZ,
		reference = reference,
		referenceAttachment = referenceAttachment,
		bodyPlaneAttachment = bodyPlaneAttachment,
		plane = plane,
		uprightAttachment = uprightAttachment,
		upright = upright,
		destroyed = false,
	}, LaneConstraint)
end

function LaneConstraint:GetLaneCenterZ(): number
	assert(not self.destroyed, "LaneConstraint is destroyed")
	return self.laneCenterZ
end

function LaneConstraint:GetReference(): Part
	assert(not self.destroyed, "LaneConstraint is destroyed")
	return self.reference
end

function LaneConstraint:GetPlaneConstraint(): PlaneConstraint
	assert(not self.destroyed, "LaneConstraint is destroyed")
	return self.plane
end

function LaneConstraint:GetOrientationConstraint(): AlignOrientation
	assert(not self.destroyed, "LaneConstraint is destroyed")
	return self.upright
end

function LaneConstraint:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	if self.model ~= nil then
		self.model:Destroy()
	end
	if self.bodyPlaneAttachment ~= nil then
		self.bodyPlaneAttachment:Destroy()
	end
	if self.uprightAttachment ~= nil then
		self.uprightAttachment:Destroy()
	end

	self.model = nil
	self.body = nil
	self.reference = nil
	self.referenceAttachment = nil
	self.bodyPlaneAttachment = nil
	self.plane = nil
	self.uprightAttachment = nil
	self.upright = nil
end

return LaneConstraint
