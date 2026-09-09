--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)

local RacerStabilizer = {}
RacerStabilizer.__index = RacerStabilizer

export type Params = {
	racerModel: Model,
	body: Part,
	laneCenterZ: number,
}

local function takeAttachment(runtimeAttachments: Instance, body: Part, name: string): Attachment
	local attachment = runtimeAttachments:FindFirstChild(name)
	assert(attachment and attachment:IsA("Attachment"), string.format("missing %s", name))
	attachment.Parent = body
	return attachment
end

local function createLaneReference(model: Model, body: Part, laneCenterZ: number): (Part, Attachment)
	local racersRoot = Workspace:WaitForChild("Runtime"):WaitForChild("Racers")
	local laneReference = Instance.new("Part")
	laneReference.Name = "LanePlaneReference"
	laneReference.Size = Vector3.new(0.1, 0.1, 0.1)
	laneReference.CFrame = CFrame.new(body.Position.X, body.Position.Y, laneCenterZ)
	laneReference.Anchored = true
	laneReference.CanCollide = false
	laneReference.CanTouch = false
	laneReference.CanQuery = false
	laneReference.CastShadow = false
	laneReference.Transparency = 1
	laneReference.Parent = racersRoot
	laneReference:SetAttribute("RacerModelName", model.Name)

	local laneReferenceAttachment = Instance.new("Attachment")
	laneReferenceAttachment.Name = "LanePlaneReferenceAttachment"
	laneReferenceAttachment.Axis = Vector3.zAxis
	laneReferenceAttachment.SecondaryAxis = Vector3.yAxis
	laneReferenceAttachment.Parent = laneReference

	return laneReference, laneReferenceAttachment
end

function RacerStabilizer.new(params: Params)
	local config = PhysicsConfig.Stabilization
	local model = params.racerModel
	local body = params.body
	local runtimeAttachments = model:FindFirstChild("RuntimeAttachments")
	assert(runtimeAttachments and runtimeAttachments:IsA("Folder"), "racerModel missing RuntimeAttachments")

	local laneAttachment = takeAttachment(runtimeAttachments, body, "LaneAlignAttachment")
	local orientationAttachment = takeAttachment(runtimeAttachments, body, "OrientationAttachment")
	orientationAttachment.Axis = Vector3.zAxis
	-- RuntimeAttachments is a template staging container only. Once the attachments
	-- are owned by BodyCollider, remove the empty helper so spawned racers match doc 65.
	runtimeAttachments:Destroy()

	local laneReference, laneReferenceAttachment = createLaneReference(model, body, params.laneCenterZ)
	local lanePlane = Instance.new("PlaneConstraint")
	lanePlane.Name = "LanePlane"
	lanePlane.Attachment0 = laneReferenceAttachment
	lanePlane.Attachment1 = laneAttachment
	lanePlane.Enabled = true
	lanePlane.Parent = body

	local orientationAlign = Instance.new("AlignOrientation")
	orientationAlign.Name = "OrientationAlign"
	orientationAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientationAlign.Attachment0 = orientationAttachment
	orientationAlign.AlignType = Enum.AlignType.PrimaryAxisParallel
	orientationAlign.PrimaryAxis = Vector3.zAxis
	orientationAlign.RigidityEnabled = false
	orientationAlign.ReactionTorqueEnabled = false
	orientationAlign.Responsiveness = config.OrientationResponsiveness
	orientationAlign.MaxTorque = config.OrientationMaxTorque
	orientationAlign.MaxAngularVelocity = config.OrientationMaxAngularVelocity
	orientationAlign.Enabled = true
	orientationAlign.Parent = body

	model:SetAttribute("LaneHardBoundExceeded", false)
	model:SetAttribute("LaneNormalBoundExceeded", false)

	local self = setmetatable({
		model = model,
		body = body,
		laneCenterZ = params.laneCenterZ,
		laneReference = laneReference,
		lanePlane = lanePlane,
		orientationAlign = orientationAlign,
		connection = nil,
		destroyed = false,
	}, RacerStabilizer)

	self.connection = RunService.Heartbeat:Connect(function()
		self:Step()
	end)

	return self
end

function RacerStabilizer:Step()
	if self.destroyed or self.body == nil or self.body.Parent == nil then
		return
	end

	local config = PhysicsConfig.Stabilization
	local body = self.body
	local errorZ = body.Position.Z - self.laneCenterZ
	local absoluteError = math.abs(errorZ)

	self.lanePlane.Enabled = true
	self.orientationAlign.Enabled = true
	self.model:SetAttribute("LaneNormalBoundExceeded", absoluteError > config.LaneNormalError)
	self.model:SetAttribute("LaneHardBoundExceeded", absoluteError > config.LaneHardBound)
end

function RacerStabilizer:GetLaneConstraint(): PlaneConstraint
	assert(not self.destroyed, "RacerStabilizer is destroyed")
	return self.lanePlane
end

function RacerStabilizer:GetOrientationAlign(): AlignOrientation
	assert(not self.destroyed, "RacerStabilizer is destroyed")
	return self.orientationAlign
end

function RacerStabilizer:GetLaneCenterZ(): number
	assert(not self.destroyed, "RacerStabilizer is destroyed")
	return self.laneCenterZ
end

function RacerStabilizer:Destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.lanePlane then
		self.lanePlane:Destroy()
	end
	if self.orientationAlign then
		self.orientationAlign:Destroy()
	end
	if self.laneReference then
		self.laneReference:Destroy()
	end
	self.lanePlane = nil
	self.orientationAlign = nil
	self.laneReference = nil
	self.body = nil
	self.model = nil
end

return RacerStabilizer
