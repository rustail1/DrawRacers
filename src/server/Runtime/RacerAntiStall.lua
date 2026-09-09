--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)

local RacerAntiStall = {}
RacerAntiStall.__index = RacerAntiStall

export type Params = {
	racerModel: Model,
	body: BasePart,
}

local function makeRaycastParams(model: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	params.IgnoreWater = true
	return params
end

function RacerAntiStall.new(params: Params)
	local body = params.body
	local attachment = Instance.new("Attachment")
	attachment.Name = "AntiStallAttachment"
	attachment.Parent = body

	local force = Instance.new("VectorForce")
	force.Name = "AntiStallForce"
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Force = Vector3.zero
	force.Parent = body

	params.racerModel:SetAttribute("AntiStallActive", false)

	local self = setmetatable({
		model = params.racerModel,
		body = body,
		attachment = attachment,
		force = force,
		raycastParams = makeRaycastParams(params.racerModel),
		stallDuration = 0,
		assistDuration = 0,
		pulseSpent = false,
		lastShapeVersion = 0,
		connection = nil,
		destroyed = false,
	}, RacerAntiStall)

	self.connection = RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)

	return self
end

function RacerAntiStall:_setActive(active: boolean)
	if self.destroyed or self.force == nil or self.model == nil then
		return
	end

	local config = PhysicsConfig.AntiStall
	if active then
		self.force.Force = Vector3.new(self.body.AssemblyMass * config.MaxAccelerationX, 0, 0)
	else
		self.force.Force = Vector3.zero
	end
	self.model:SetAttribute("AntiStallActive", active)
end

function RacerAntiStall:_eligibleSurface(): boolean
	local config = PhysicsConfig.AntiStall
	local body = self.body
	local result = Workspace:Raycast(
		body.Position,
		Vector3.new(0, -config.GroundProbeDistance, 0),
		self.raycastParams
	)
	if result == nil then
		return false
	end
	return result.Instance:GetAttribute("AntiStallSurface") == true
end

function RacerAntiStall:_resetEpisode()
	self.stallDuration = 0
	self.assistDuration = 0
	self.pulseSpent = false
	self:_setActive(false)
end

function RacerAntiStall:Step(dt: number)
	if self.destroyed or self.body == nil or self.body.Parent == nil or self.model == nil then
		return
	end

	local config = PhysicsConfig.AntiStall
	if config.Enabled ~= true then
		self:_resetEpisode()
		return
	end

	local shapeVersion = self.model:GetAttribute("ShapeVersion")
	if type(shapeVersion) ~= "number" or shapeVersion <= 0 then
		self:_resetEpisode()
		self.lastShapeVersion = 0
		return
	end
	if shapeVersion ~= self.lastShapeVersion then
		self:_resetEpisode()
		self.lastShapeVersion = shapeVersion
	end

	local speedX = self.body.AssemblyLinearVelocity.X
	local eligibleSurface = self:_eligibleSurface()
	if not eligibleSurface or speedX >= config.DisableForwardSpeed then
		self:_resetEpisode()
		return
	end

	if self.model:GetAttribute("AntiStallActive") == true then
		self.assistDuration += dt
		if self.assistDuration >= config.MaxAssistDuration or speedX >= config.DisableForwardSpeed then
			self.pulseSpent = true
			self:_setActive(false)
		end
		return
	end

	if self.pulseSpent then
		return
	end

	if speedX < config.ActivationForwardSpeed then
		self.stallDuration += dt
	else
		self.stallDuration = 0
		return
	end

	if self.stallDuration >= config.ActivationDelay then
		self.assistDuration = 0
		self:_setActive(true)
	end
end

function RacerAntiStall:Destroy()
	if self.destroyed then
		return
	end
	self:_setActive(false)
	self.destroyed = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.force then
		self.force:Destroy()
		self.force = nil
	end
	if self.attachment then
		self.attachment:Destroy()
		self.attachment = nil
	end
	self.body = nil
	self.model = nil
end

return RacerAntiStall
