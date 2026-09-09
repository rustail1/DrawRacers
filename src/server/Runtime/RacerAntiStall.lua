--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)

local RacerAntiStall = {}
RacerAntiStall.__index = RacerAntiStall

export type Params = {
	racerModel: Model,
	body: BasePart,
}

local function hasRecoverySurfaceTag(instance: Instance): boolean
	local cursor: Instance? = instance
	while cursor ~= nil do
		if CollectionService:HasTag(cursor, "RecoverySurface") then
			return true
		end
		cursor = cursor.Parent
	end
	return false
end

local function getRequirementTag(instance: Instance): string?
	local cursor: Instance? = instance
	while cursor ~= nil do
		local requirementTag = cursor:GetAttribute("RequirementTag")
		if type(requirementTag) == "string" then
			return requirementTag
		end
		if requirementTag ~= nil then
			return "__INVALID__"
		end
		cursor = cursor.Parent
	end
	return nil
end

local function classifyContactSurface(surface: BasePart): string
	local requirementTag = getRequirementTag(surface)
	-- An explicit obstacle RequirementTag always wins. RecoverySurface is an assist
	-- affordance, never permission to override geometry authored to test adaptation.
	if requirementTag ~= nil and requirementTag ~= "FAST_ROLL" then
		return "OBSTACLE"
	end
	if requirementTag == "FAST_ROLL" or hasRecoverySurfaceTag(surface) then
		return "ELIGIBLE"
	end

	if surface.CanCollide then
		return "UNKNOWN_COLLIDABLE"
	end
	return "IGNORE"
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
	if self.destroyed or self.force == nil or self.model == nil or self.body == nil then
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

function RacerAntiStall:_eligibleContact(): boolean
	local hasEligibleContact = false
	for _, descendant in self.model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.CanCollide and descendant.CanTouch then
			for _, touchingPart in descendant:GetTouchingParts() do
				if not touchingPart:IsDescendantOf(self.model) then
					local classification = classifyContactSurface(touchingPart)
					if classification == "OBSTACLE" or classification == "UNKNOWN_COLLIDABLE" then
						return false
					end
					if classification == "ELIGIBLE" then
						hasEligibleContact = true
					end
				end
			end
		end
	end
	return hasEligibleContact
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
	if speedX >= config.DisableForwardSpeed then
		self:_resetEpisode()
		return
	end
	if not self:_eligibleContact() then
		self:_resetEpisode()
		return
	end

	if self.model:GetAttribute("AntiStallActive") == true then
		self.assistDuration += dt
		if self.assistDuration >= config.MaxAssistDuration then
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
