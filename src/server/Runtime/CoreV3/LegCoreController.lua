--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LegCoreConfig = require(script.Parent:WaitForChild("LegCoreConfig"))
local SharedAxle = require(script.Parent:WaitForChild("SharedAxle"))
local LegGeometry = require(script.Parent:WaitForChild("LegGeometry"))
local LegClearanceController = require(script.Parent:WaitForChild("LegClearanceController"))

local LegCoreController = {}
LegCoreController.__index = LegCoreController

local STATE_EMPTY = "EMPTY"
local STATE_PREVIEW = "PREVIEW"
local STATE_WAIT_CLEAR = "WAIT_CLEAR"
local STATE_ACTIVE = "ACTIVE"
local STATE_DESTROYED = "DESTROYED"

local function resolveTracksRoot(): Instance?
	local runtime = Workspace:FindFirstChild("Runtime")
	if runtime == nil then
		return nil
	end
	return runtime:FindFirstChild("Tracks")
end

local function computeAngularVelocity(shapeSpec: any): number
	local extent = shapeSpec.extent
	assert(type(extent) == "number" and extent > 0, "Core V3 shape extent must be positive")
	local radius = math.max(extent, LegCoreConfig.Motor.MinimumDriveRadius)
	local omega = LegCoreConfig.Motor.TargetTipSpeed / radius
	omega = math.clamp(
		omega,
		LegCoreConfig.Motor.MinAngularVelocity,
		LegCoreConfig.Motor.MaxAngularVelocity
	)
	return omega * LegCoreConfig.Motor.RotationSign
end

local function destroyLeg(leg: any?)
	if leg ~= nil then
		leg:Destroy()
	end
end

local function configureBodyForCoreV3(body: Part)
	local material = LegCoreConfig.Materials.Body
	body.CustomPhysicalProperties = PhysicalProperties.new(
		material.Density,
		material.Friction,
		material.Elasticity,
		material.FrictionWeight,
		material.ElasticityWeight
	)
end

function LegCoreController.new(
	racerModel: Model,
	beforePhysicalActivation: (() -> ())?,
	setInitialHoldLift: ((number) -> ())?
)
	assert(racerModel ~= nil and racerModel:IsA("Model"), "LegCoreController requires racer Model")
	assert(
		beforePhysicalActivation == nil or type(beforePhysicalActivation) == "function",
		"beforePhysicalActivation must be a function or nil"
	)
	assert(
		setInitialHoldLift == nil or type(setInitialHoldLift) == "function",
		"setInitialHoldLift must be a function or nil"
	)
	local body = racerModel:FindFirstChild("BodyCollider")
	assert(body ~= nil and body:IsA("Part"), "LegCoreController requires BodyCollider Part")
	configureBodyForCoreV3(body)

	local existing = racerModel:FindFirstChild("CoreV3Runtime")
	assert(existing == nil, "racer already owns CoreV3Runtime")

	local container = Instance.new("Folder")
	container.Name = "CoreV3Runtime"
	container.Parent = racerModel

	local sharedAxle = SharedAxle.new(body, container)
	sharedAxle:SetEnabled(false)

	local self = setmetatable({
		racerModel = racerModel,
		body = body,
		container = container,
		sharedAxle = sharedAxle,
		leftLeg = nil :: any?,
		rightLeg = nil :: any?,
		state = STATE_EMPTY,
		requestedMotorEnabled = false,
		previewElapsed = 0,
		waitClearElapsed = 0,
		waitClearStartY = 0,
		waitClearTargetY = 0,
		pendingShapeSpec = nil :: any?,
		currentShapeSpec = nil :: any?,
		beforePhysicalActivation = beforePhysicalActivation,
		setInitialHoldLift = setInitialHoldLift,
		initialHoldLift = 0,
		lastRebuildFailureReason = nil :: string?,
		liftAttachment = nil :: Attachment?,
		liftForce = nil :: VectorForce?,
		heartbeatConnection = nil :: RBXScriptConnection?,
		destroyed = false,
	}, LegCoreController)

	self.heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if self.destroyed then
			return
		end

		local ok, failure = xpcall(function()
			self:_Step(dt)
		end, debug.traceback)

		if not ok then
			warn("[DrawRacers][CoreV3] controller step failed: " .. tostring(failure))
			if self.state == STATE_PREVIEW or self.state == STATE_WAIT_CLEAR then
				self:_FailRebuild("BUILD_FAILED")
			end
		end
	end)

	return self
end

function LegCoreController:_StopLiftAssist()
	if self.liftForce ~= nil then
		self.liftForce:Destroy()
		self.liftForce = nil
	end
	if self.liftAttachment ~= nil then
		self.liftAttachment:Destroy()
		self.liftAttachment = nil
	end
end

function LegCoreController:_EnsureLiftAssist(dt: number)
	if self.liftAttachment == nil then
		local attachment = Instance.new("Attachment")
		attachment.Name = "CoreV3ClearanceLiftAttachment"
		attachment.Parent = self.body
		self.liftAttachment = attachment
	end

	if self.liftForce == nil then
		local force = Instance.new("VectorForce")
		force.Name = "CoreV3ClearanceLift"
		force.Attachment0 = self.liftAttachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.ApplyAtCenterOfMass = true
		force.Parent = self.body
		self.liftForce = force
	end

	local force = self.liftForce
	assert(force ~= nil, "Core V3 lift force missing")
	local currentYVelocity = self.body.AssemblyLinearVelocity.Y
	local remainingLift = math.max(0, self.waitClearTargetY - self.body.Position.Y)
	local targetYVelocity = math.min(
		LegCoreConfig.Rebuild.LiftTargetVelocity,
		remainingLift * 8
	)
	local response = 20
	local desiredAcceleration = math.clamp((targetYVelocity - currentYVelocity) * response, -60, 60)
	local drivenMass = self.body.AssemblyMass + self.sharedAxle:GetAxleRoot().AssemblyMass
	local yForce = drivenMass * (Workspace.Gravity + desiredAcceleration)
	force.Force = Vector3.new(0, yForce, 0)

	-- dt is intentionally consumed by the controller step even though the
	-- force target itself is velocity-based. Keep the guard here so invalid
	-- Heartbeat input can never silently drive the lift path.
	assert(dt >= 0, "Core V3 Heartbeat dt must be non-negative")
end

function LegCoreController:_DestroyCurrentPair()
	if self.leftLeg ~= nil then
		self.leftLeg:SetPhysicsEnabled(false)
	end
	if self.rightLeg ~= nil then
		self.rightLeg:SetPhysicsEnabled(false)
	end

	destroyLeg(self.leftLeg)
	destroyLeg(self.rightLeg)
	self.leftLeg = nil
	self.rightLeg = nil
end

function LegCoreController:_ApplyRedrawHop()
	local targetY = LegCoreConfig.Rebuild.HopTargetVelocity
	local maxDelta = LegCoreConfig.Rebuild.MaxHopDeltaVelocity

	-- One external hop impulse only. The hinge stays physically enabled and
	-- carries AxleRoot with BodyCollider; separately impulsing both assemblies
	-- over-constrains the redraw transition and can create a solver kick.
	local wantedDelta = targetY - self.body.AssemblyLinearVelocity.Y
	local deltaY = math.clamp(wantedDelta, 0, maxDelta)
	if deltaY > 0 then
		self.body:ApplyImpulse(Vector3.new(0, self.body.AssemblyMass * deltaY, 0))
	end
end

function LegCoreController:_FailRebuild(reason: string)
	if self.initialHoldLift > 0 and self.setInitialHoldLift ~= nil then
		local restored, restoreFailure = xpcall(function()
			self.setInitialHoldLift(0)
		end, debug.traceback)
		if not restored then
			warn("[DrawRacers][CoreV3] initial hold restore failed: " .. tostring(restoreFailure))
		end
	end
	self.initialHoldLift = 0
	self.lastRebuildFailureReason = reason
	self.sharedAxle:SetEnabled(false)
	self:_StopLiftAssist()
	self:_DestroyCurrentPair()
	self.pendingShapeSpec = nil
	self.currentShapeSpec = nil
	self.previewElapsed = 0
	self.waitClearElapsed = 0
	self.waitClearTargetY = 0
	self.state = STATE_EMPTY
	warn("[DrawRacers][CoreV3] redraw failed closed: " .. reason)
end

function LegCoreController:_BeginRebuild(shapeSpec: any, motorEnabled: boolean)
	local isRedraw = self.state == STATE_ACTIVE
	self.initialHoldLift = 0
	self.lastRebuildFailureReason = nil
	self.sharedAxle:SetEnabled(false)
	self:_StopLiftAssist()
	self:_DestroyCurrentPair()
	self.currentShapeSpec = nil

	local leftLeg = LegGeometry.new(self.sharedAxle:GetLeftMount(), "Left")
	local rightLeg = LegGeometry.new(self.sharedAxle:GetRightMount(), "Right")

	local ok, failure = xpcall(function()
		leftLeg:BuildPreview(shapeSpec)
		rightLeg:BuildPreview(shapeSpec)
		leftLeg:BuildPhysical(shapeSpec)
		rightLeg:BuildPhysical(shapeSpec)
		leftLeg:SetPhysicsEnabled(false)
		rightLeg:SetPhysicsEnabled(false)
	end, debug.traceback)
	if not ok then
		leftLeg:Destroy()
		rightLeg:Destroy()
		error(failure)
	end

	self.leftLeg = leftLeg
	self.rightLeg = rightLeg
	self.pendingShapeSpec = shapeSpec
	self.requestedMotorEnabled = motorEnabled
	self.previewElapsed = 0
	self.waitClearElapsed = 0
	self.waitClearStartY = self.body.Position.Y
	self.waitClearTargetY = self.waitClearStartY

	local tracksRoot = resolveTracksRoot()
	if tracksRoot == nil then
		error("Core V3 Track root missing during redraw preparation")
	end
	local initialClearance = LegClearanceController.Evaluate(
		self.body,
		leftLeg,
		rightLeg,
		tracksRoot
	)
	if not initialClearance.clear then
		self.waitClearTargetY = math.min(
			self.waitClearStartY + LegCoreConfig.Rebuild.MaxLift,
			self.waitClearStartY + initialClearance.requiredLift + LegCoreConfig.Rebuild.ClearancePadding
		)
	end

	if isRedraw then
		self:_ApplyRedrawHop()
	end
	self.sharedAxle:SetAngularVelocity(computeAngularVelocity(shapeSpec))
	self.state = STATE_PREVIEW
end

function LegCoreController:_ActivatePair()
	assert(self.leftLeg ~= nil and self.rightLeg ~= nil, "Core V3 activation requires complete pair")
	self:_StopLiftAssist()

	self.currentShapeSpec = self.pendingShapeSpec
	self.pendingShapeSpec = nil
	self.lastRebuildFailureReason = nil
	self.waitClearElapsed = 0
	self.state = STATE_ACTIVE

	-- The first release is part of this same activation callback. Keep the pair
	-- ghosted and the motor OFF until RacerRuntime has zeroed and released the
	-- held assembly, so no solver step can preload the axle against an anchor.
	local beforePhysicalActivation = self.beforePhysicalActivation
	if beforePhysicalActivation ~= nil then
		local released, releaseFailure = xpcall(beforePhysicalActivation, debug.traceback)
		if not released then
			self:_FailRebuild("BUILD_FAILED")
			warn("[DrawRacers][CoreV3] initial release failed: " .. tostring(releaseFailure))
			return
		end
		self.beforePhysicalActivation = nil
		self.setInitialHoldLift = nil
		self.initialHoldLift = 0
	end

	-- Both sides are enabled from the same Heartbeat callback. There is no
	-- progressive segment or per-side activation state in Core V3.
	self.leftLeg:SetPhysicsEnabled(true)
	self.rightLeg:SetPhysicsEnabled(true)
	self.sharedAxle:SetEnabled(self.requestedMotorEnabled)
end

function LegCoreController:_StepPreview(dt: number)
	assert(self.leftLeg ~= nil and self.rightLeg ~= nil, "PREVIEW requires complete leg owners")
	assert(self.pendingShapeSpec ~= nil, "PREVIEW requires pending shape")

	self.sharedAxle:SetEnabled(false)
	self.previewElapsed += dt
	local duration = math.max(LegCoreConfig.Rebuild.PreviewDuration, 1e-4)
	local progress = math.clamp(self.previewElapsed / duration, 0, 1)
	self.leftLeg:SetPreviewProgress(progress)
	self.rightLeg:SetPreviewProgress(progress)

	if progress < 1 then
		return
	end

	self.waitClearElapsed = 0
	self.state = STATE_WAIT_CLEAR
end

function LegCoreController:_StepWaitClear(dt: number)
	assert(self.leftLeg ~= nil and self.rightLeg ~= nil, "WAIT_CLEAR requires complete pair")
	self.sharedAxle:SetEnabled(false)
	self.leftLeg:SetPhysicsEnabled(false)
	self.rightLeg:SetPhysicsEnabled(false)

	local tracksRoot = resolveTracksRoot()
	if tracksRoot == nil then
		self:_FailRebuild("TRACK_ROOT_MISSING")
		return
	end

	local result = LegClearanceController.Evaluate(
		self.body,
		self.leftLeg,
		self.rightLeg,
		tracksRoot
	)

	-- EMPTY begins with the cube itself just above the Track. The actual first
	-- drawing, rather than the global maximum shape cap, determines how far the
	-- held assembly must move upward. Apply that one bounded +Y placement while
	-- BodyCollider is still anchored, then re-evaluate the whole ghost pair on
	-- the next Heartbeat. The callback is cleared after the first ACTIVE commit,
	-- so redraw never enters this initialization path.
	if self.body.Anchored and self.setInitialHoldLift ~= nil and not result.clear then
		if self.initialHoldLift > 0
			or result.requiredLift >= LegCoreConfig.Rebuild.MaxLift
		then
			self:_FailRebuild("CLEARANCE_FAILED")
			return
		end

		local placed, placementFailure = xpcall(function()
			self.setInitialHoldLift(result.requiredLift)
		end, debug.traceback)
		if not placed then
			warn("[DrawRacers][CoreV3] initial support placement failed: " .. tostring(placementFailure))
			self:_FailRebuild("BUILD_FAILED")
			return
		end

		self.initialHoldLift = result.requiredLift
		self.waitClearStartY = self.body.Position.Y
		self.waitClearTargetY = self.body.Position.Y
		self.waitClearElapsed = 0
		return
	end

	local maxLiftY = self.waitClearStartY + LegCoreConfig.Rebuild.MaxLift
	if not result.clear then
		local requestedTargetY = self.body.Position.Y
			+ result.requiredLift
			+ LegCoreConfig.Rebuild.ClearancePadding
		self.waitClearTargetY = math.max(
			self.waitClearTargetY,
			math.min(maxLiftY, requestedTargetY)
		)
	end

	local positionSettled = self.body.Position.Y
		>= self.waitClearTargetY - LegCoreConfig.Rebuild.ClearanceSettlePositionTolerance
	local verticalSpeedSettled = math.abs(self.body.AssemblyLinearVelocity.Y)
		<= LegCoreConfig.Rebuild.ClearanceSettleVerticalSpeed
	if result.clear and positionSettled and verticalSpeedSettled then
		self:_ActivatePair()
		return
	end

	self.waitClearElapsed += dt

	local minimumTimeout = LegCoreConfig.Rebuild.MaxLift
		/ math.max(LegCoreConfig.Rebuild.LiftTargetVelocity, 1e-3)
		+ 0.35
	local timeout = math.max(LegCoreConfig.Rebuild.ClearanceTimeout, minimumTimeout)
	local exhaustedLift = not result.clear and self.body.Position.Y >= maxLiftY - 0.02
	if self.waitClearElapsed >= timeout or exhaustedLift then
		self:_FailRebuild("CLEARANCE_FAILED")
		return
	end

	-- Redraw uses the existing force-based +Y clearance owner. A fresh racer is
	-- still anchored here; its one-time initialization placement is handled by
	-- the bounded branch above without creating a mover or persistent force.
	if not self.body.Anchored then
		self:_EnsureLiftAssist(dt)
	end
end

function LegCoreController:_Step(dt: number)
	if self.state == STATE_PREVIEW then
		self:_StepPreview(dt)
	elseif self.state == STATE_WAIT_CLEAR then
		self:_StepWaitClear(dt)
	end
end

function LegCoreController:ApplyShape(shapeSpec: any, motorEnabled: boolean): (boolean, string?)
	assert(not self.destroyed, "ApplyShape requires live LegCoreController")
	assert(type(shapeSpec) == "table", "Core V3 ApplyShape requires shapeSpec")
	assert(type(motorEnabled) == "boolean", "Core V3 motorEnabled must be boolean")

	if self.state == STATE_PREVIEW or self.state == STATE_WAIT_CLEAR then
		return false, "REDRAW_PENDING"
	end
	if self.state ~= STATE_EMPTY and self.state ~= STATE_ACTIVE then
		return false, "INVALID_STATE"
	end

	local ok, failure = xpcall(function()
		self:_BeginRebuild(shapeSpec, motorEnabled)
	end, debug.traceback)
	if not ok then
		self:_FailRebuild("BUILD_FAILED")
		warn("[DrawRacers][CoreV3] ApplyShape failed: " .. tostring(failure))
		return false, "BUILD_FAILED"
	end

	return true, nil
end

function LegCoreController:WaitForRebuildResult(): (boolean, string?)
	assert(not self.destroyed, "WaitForRebuildResult requires live LegCoreController")

	local minimumClearanceTimeout = LegCoreConfig.Rebuild.MaxLift
		/ math.max(LegCoreConfig.Rebuild.LiftTargetVelocity, 1e-3)
		+ 0.35
	local timeout = LegCoreConfig.Rebuild.PreviewDuration
		+ math.max(LegCoreConfig.Rebuild.ClearanceTimeout, minimumClearanceTimeout)
		+ 0.75
	local deadline = os.clock() + timeout

	while self.state == STATE_PREVIEW or self.state == STATE_WAIT_CLEAR do
		if os.clock() >= deadline then
			self:_FailRebuild("REBUILD_TIMEOUT")
			return false, "REBUILD_TIMEOUT"
		end
		RunService.Heartbeat:Wait()
	end

	if self.state == STATE_ACTIVE then
		return true, nil
	end
	if self.state == STATE_EMPTY then
		return false, self.lastRebuildFailureReason or "BUILD_FAILED"
	end
	if self.state == STATE_DESTROYED then
		return false, "DESTROYED"
	end

	return false, "INVALID_STATE"
end

function LegCoreController:SetMotorEnabled(enabled: boolean)
	assert(not self.destroyed, "SetMotorEnabled requires live LegCoreController")
	assert(type(enabled) == "boolean", "enabled must be boolean")
	self.requestedMotorEnabled = enabled
	if self.state == STATE_ACTIVE then
		self.sharedAxle:SetEnabled(enabled)
	else
		self.sharedAxle:SetEnabled(false)
	end
end

function LegCoreController:PrepareForRecovery()
	assert(not self.destroyed, "PrepareForRecovery requires live LegCoreController")
	self.sharedAxle:SetEnabled(false)
	self.requestedMotorEnabled = false
	self:_StopLiftAssist()

	if self.state == STATE_PREVIEW or self.state == STATE_WAIT_CLEAR then
		self:_DestroyCurrentPair()
		self.pendingShapeSpec = nil
		self.currentShapeSpec = nil
		self.lastRebuildFailureReason = "RECOVERY_CANCELLED"
		self.state = STATE_EMPTY
	end
end

function LegCoreController:GetState(): string
	return self.state
end

function LegCoreController:GetLeftLeg()
	assert(not self.destroyed, "LegCoreController is destroyed")
	return self.leftLeg
end

function LegCoreController:GetRightLeg()
	assert(not self.destroyed, "LegCoreController is destroyed")
	return self.rightLeg
end

function LegCoreController:GetSharedAxle()
	assert(not self.destroyed, "LegCoreController is destroyed")
	return self.sharedAxle
end

function LegCoreController:Destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true
	self.state = STATE_DESTROYED

	if self.heartbeatConnection ~= nil then
		self.heartbeatConnection:Disconnect()
		self.heartbeatConnection = nil
	end

	self:_StopLiftAssist()
	self:_DestroyCurrentPair()
	self.pendingShapeSpec = nil
	self.currentShapeSpec = nil

	if self.sharedAxle ~= nil then
		self.sharedAxle:Destroy()
	end
	if self.container ~= nil then
		self.container:Destroy()
	end

end

return LegCoreController
