--!strict

local RunService = game:GetService("RunService")

local LegCoreConfig = require(script.Parent:WaitForChild("LegCoreConfig"))

local FallRecovery = {}
FallRecovery.__index = FallRecovery

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function clearModelVelocities(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and not descendant.Anchored then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function countHinges(model: Model): number
	local count = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

function FallRecovery.new(racer: any, respawnCFrame: CFrame, laneCenterZ: number)
	assert(racer ~= nil, "FallRecovery requires RacerRuntime")
	assert(typeof(respawnCFrame) == "CFrame", "FallRecovery requires respawn CFrame")
	assert(type(laneCenterZ) == "number" and isFinite(laneCenterZ), "FallRecovery requires finite lane center")

	local respawnPosition = respawnCFrame.Position
	local targetCFrame = CFrame.new(respawnPosition.X, respawnPosition.Y, laneCenterZ) * respawnCFrame.Rotation
	local self = setmetatable({
		racer = racer,
		respawnCFrame = targetCFrame,
		outOfBoundsLatched = false,
		recovering = false,
		recoveryCount = 0,
		connection = nil :: RBXScriptConnection?,
		destroyed = false,
	}, FallRecovery)

	self.connection = RunService.Heartbeat:Connect(function()
		self:_Step()
	end)
	return self
end

function FallRecovery:_Recover()
	local racer = self.racer
	local model = racer:GetModel()
	local body = racer:GetBody()
	local acceptedShape = racer:GetCurrentShapeSpec()
	local core = racer:GetLegCore()
	local lane = racer:GetLaneConstraint()
	local laneReference = lane:GetReference()
	local laneReferenceCFrame = laneReference.CFrame

	racer:SetMotorEnabled(false)
	racer:PrepareForRecovery()
	clearModelVelocities(model)

	-- PivotTo is intentionally restricted to this explicit out-of-bounds
	-- transaction. Restore the anchored lane reference because it is a world
	-- constraint reference, not part of the moving physical assembly.
	model:PivotTo(self.respawnCFrame)
	laneReference.CFrame = laneReferenceCFrame
	clearModelVelocities(model)

	if acceptedShape ~= nil then
		assert(core ~= nil and core:GetState() == "ACTIVE", "FallRecovery requires preserved ACTIVE pair")
		assert(racer:GetCurrentShapeSpec() == acceptedShape, "FallRecovery must preserve accepted ShapeSpec")
		assert(countHinges(model) == 1, "FallRecovery requires exactly one hinge")
		racer:SetMotorEnabled(true)
	end

	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero
	self.recoveryCount += 1
	model:SetAttribute("CoreV3RecoveryCount", self.recoveryCount)
end

function FallRecovery:_Step()
	if self.destroyed or self.recovering then
		return
	end

	local body = self.racer:GetBody()
	local threshold = LegCoreConfig.Recovery.FallThreshold
	if body.Position.Y >= threshold + LegCoreConfig.Recovery.RearmMargin then
		self.outOfBoundsLatched = false
		return
	end
	if body.Position.Y >= threshold or self.outOfBoundsLatched then
		return
	end
	if self.racer:IsRedrawPending() then
		return
	end

	self.outOfBoundsLatched = true
	self.recovering = true
	local ok, failure = xpcall(function()
		self:_Recover()
	end, debug.traceback)
	self.recovering = false
	if not ok then
		warn("[DrawRacers][CoreV3][FallRecovery] failed closed: " .. tostring(failure))
	end
end

function FallRecovery:GetRecoveryCount(): number
	return self.recoveryCount
end

function FallRecovery:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.connection ~= nil then
		self.connection:Disconnect()
		self.connection = nil
	end
	self.racer = nil
end

return FallRecovery
