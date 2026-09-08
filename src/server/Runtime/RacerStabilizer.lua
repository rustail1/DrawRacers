--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

function RacerStabilizer.new(params: Params)
	local config = PhysicsConfig.Stabilization
	local model = params.racerModel
	local body = params.body
	local runtimeAttachments = model:FindFirstChild("RuntimeAttachments")
	assert(runtimeAttachments and runtimeAttachments:IsA("Folder"), "racerModel missing RuntimeAttachments")

	local laneAttachment = takeAttachment(runtimeAttachments, body, "LaneAlignAttachment")
	local orientationAttachment = takeAttachment(runtimeAttachments, body, "OrientationAttachment")

	local laneAlign = Instance.new("AlignPosition")
	laneAlign.Name = "LaneAlign"
	laneAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
	laneAlign.Attachment0 = laneAttachment
	laneAlign.ApplyAtCenterOfMass = true
	laneAlign.RigidityEnabled = false
	laneAlign.ReactionForceEnabled = false
	laneAlign.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	laneAlign.ForceRelativeTo = Enum.ActuatorRelativeTo.World
	laneAlign.MaxAxesForce = Vector3.new(0, 0, config.LaneMaxForceZ)
	laneAlign.MaxVelocity = config.LaneMaxVelocity
	laneAlign.Responsiveness = config.LaneResponsiveness
	laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, params.laneCenterZ)
	laneAlign.Enabled = false
	laneAlign.Parent = body

	local orientationAlign = Instance.new("AlignOrientation")
	orientationAlign.Name = "OrientationAlign"
	orientationAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientationAlign.Attachment0 = orientationAttachment
	orientationAlign.RigidityEnabled = false
	orientationAlign.ReactionTorqueEnabled = false
	orientationAlign.Responsiveness = config.OrientationResponsiveness
	orientationAlign.MaxTorque = config.OrientationMaxTorque
	orientationAlign.MaxAngularVelocity = config.OrientationMaxAngularVelocity
	orientationAlign.CFrame = CFrame.identity
	orientationAlign.Enabled = true
	orientationAlign.Parent = body

	model:SetAttribute("LaneHardBoundExceeded", false)
	model:SetAttribute("LaneNormalBoundExceeded", false)

	local self = setmetatable({
		model = model,
		body = body,
		laneCenterZ = params.laneCenterZ,
		laneAlign = laneAlign,
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

	self.laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, self.laneCenterZ)
	self.laneAlign.Enabled = absoluteError > config.LaneCorrectionDeadzone
	self.model:SetAttribute("LaneNormalBoundExceeded", absoluteError > config.LaneNormalError)
	self.model:SetAttribute("LaneHardBoundExceeded", absoluteError > config.LaneHardBound)
end

function RacerStabilizer:GetLaneAlign(): AlignPosition
	assert(not self.destroyed, "RacerStabilizer is destroyed")
	return self.laneAlign
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
	if self.laneAlign then
		self.laneAlign:Destroy()
	end
	if self.orientationAlign then
		self.orientationAlign:Destroy()
	end
	self.laneAlign = nil
	self.orientationAlign = nil
	self.body = nil
	self.model = nil
end

return RacerStabilizer
