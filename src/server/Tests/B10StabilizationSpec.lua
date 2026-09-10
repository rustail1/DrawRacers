--!strict

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B10StabilizationSpec = {}

local RECOVERY_WINDOW = 0.25
local MAX_RECOVERY_SAMPLE_DT = 0.10
local MAX_RECOVERY_ATTEMPTS = 3

local function bodyAngularDeviationDegrees(body: BasePart): number
	local x, y, z = body.CFrame:ToOrientation()
	return math.max(math.abs(math.deg(x)), math.abs(math.deg(y)), math.abs(math.deg(z)))
end

local function runUprightRecoveryAttempt(body: BasePart, recoveryCFrame: CFrame): (boolean, number, number, number?)
	body.Anchored = true
	body.CFrame = recoveryCFrame
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero
	body.Anchored = false

	local peakDeviation = bodyAngularDeviationDegrees(body)
	assert(peakDeviation <= 3.0, string.format("upright body angular deviation peak %.4f", peakDeviation))

	local recoveryElapsed = 0
	local recovered = bodyAngularDeviationDegrees(body) <= 1.0
	while recoveryElapsed < RECOVERY_WINDOW and not recovered do
		local dt = RunService.Heartbeat:Wait()
		if dt > MAX_RECOVERY_SAMPLE_DT then
			return false, recoveryElapsed, bodyAngularDeviationDegrees(body), dt
		end
		recoveryElapsed += dt
		recovered = bodyAngularDeviationDegrees(body) <= 1.0
	end

	return recovered, recoveryElapsed, bodyAngularDeviationDegrees(body), nil
end

function B10StabilizationSpec.run()
	local config = PhysicsConfig.Stabilization
	local laneCenterZ = 2.5
	local racer = RacerRuntime.new({
		raceId = "B10_TEST",
		slotIndex = 3,
		laneIndex = 3,
		isBot = true,
		trackId = "B10_FLAT",
		spawnCFrame = CFrame.new(-18, 8, laneCenterZ),
		laneCenterZ = laneCenterZ,
	})

	assert(PhysicsService:CollisionGroupsAreCollidable("Default", "RacerBody") == false, "Default must not collide with RacerBody")
	assert(PhysicsService:CollisionGroupsAreCollidable("Default", "RacerLeg") == false, "Default must not collide with RacerLeg")
	assert(PhysicsService:CollisionGroupsAreCollidable("Track", "RacerBody") == true, "Track must collide with RacerBody")
	assert(PhysicsService:CollisionGroupsAreCollidable("Track", "RacerLeg") == true, "Track must collide with RacerLeg")

	local body = racer:GetBody()
	body.Anchored = true
	local model = racer:GetModel()
	local stabilizer = racer:GetStabilizer()
	local lanePlane = stabilizer:GetLaneConstraint()
	local orientationAlign = stabilizer:GetOrientationAlign()

	assert(lanePlane:IsA("PlaneConstraint"), "B10 lane lock must use a mechanical PlaneConstraint")
	assert(lanePlane.Enabled == true, "lane plane must remain continuously enabled")
	assert(lanePlane.Attachment0 ~= nil and lanePlane.Attachment1 ~= nil, "lane plane requires both attachments")
	local laneReference = lanePlane.Attachment0.Parent
	assert(laneReference ~= nil and laneReference:IsA("BasePart"), "lane plane Attachment0 must live on an anchored reference")
	assert(laneReference.Anchored == true, "lane plane reference must be anchored")
	assert(laneReference.CanCollide == false and laneReference.CanTouch == false and laneReference.CanQuery == false, "lane plane reference must be non-physical")
	assert(math.abs(lanePlane.Attachment0.WorldPosition.Z - laneCenterZ) <= 1e-6, "lane plane reference must stay on canonical lane center Z")

	assert(orientationAlign.Mode == Enum.OrientationAlignmentMode.OneAttachment)
	assert(orientationAlign.AlignType == Enum.AlignType.AllAxes)
	assert(orientationAlign.CFrame == CFrame.identity)
	assert(orientationAlign.Responsiveness == config.OrientationResponsiveness)
	assert(orientationAlign.RigidityEnabled == false)
	assert(orientationAlign.Enabled == true, "upright orientation correction must remain continuously enabled")
	local orientationAttachment = orientationAlign.Attachment0
	assert(orientationAttachment ~= nil, "orientation align requires Attachment0")
	assert(orientationAttachment.Axis == Vector3.xAxis, "orientation attachment X axis must stay canonical")
	assert(orientationAttachment.SecondaryAxis == Vector3.yAxis, "orientation attachment Y axis must stay canonical")

	-- Real physics regression for the Studio lateral failure that escaped the old property-only B10.
	body.CFrame = CFrame.new(-18, 8, laneCenterZ)
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero
	body.Anchored = false
	RunService.Heartbeat:Wait()
	body:ApplyImpulse(Vector3.new(0, 0, body.AssemblyMass * 120))
	local maxObservedLaneDeviation = 0
	for _ = 1, 6 do
		RunService.Heartbeat:Wait()
		maxObservedLaneDeviation = math.max(maxObservedLaneDeviation, math.abs(body.Position.Z - laneCenterZ))
	end
	assert(
		maxObservedLaneDeviation <= config.LaneHardBound,
		string.format("lateral impulse escaped the hard gameplay plane: %.6f", maxObservedLaneDeviation)
	)

	-- Reference-parity body contract: disturb the cube but keep it upright while the legs
	-- remain the only rotating locomotion assemblies. A Heartbeat sample larger than the
	-- measurement resolution cannot prove how long recovery took, so discard that attempt
	-- and retry instead of misclassifying a Studio scheduler stall as a physics failure.
	local recoveryCFrame = CFrame.new(-18, 8, laneCenterZ) * CFrame.Angles(0, 0, math.rad(2.5))
	local recoveryElapsed = 0
	local recoveryDeviation = math.huge
	local recovered = false
	local validRecoveryEvidence = false
	local lastStallDt: number? = nil

	for attempt = 1, MAX_RECOVERY_ATTEMPTS do
		local attemptRecovered, attemptElapsed, attemptDeviation, stallDt = runUprightRecoveryAttempt(body, recoveryCFrame)
		recovered = attemptRecovered
		recoveryElapsed = attemptElapsed
		recoveryDeviation = attemptDeviation
		if stallDt == nil then
			validRecoveryEvidence = true
			break
		end
		lastStallDt = stallDt
	end

	assert(
		validRecoveryEvidence,
		string.format(
			"upright recovery evidence invalidated by Heartbeat stalls: attempts=%d lastDt=%.4f",
			MAX_RECOVERY_ATTEMPTS,
			lastStallDt or -1
		)
	)
	assert(
		recovered and recoveryElapsed <= RECOVERY_WINDOW,
		string.format(
			"upright recovery exceeded 0.25 s: elapsed=%.4f deviation=%.4f",
			recoveryElapsed,
			recoveryDeviation
		)
	)

	-- Upright correction must not accidentally become an X/Y position lock.
	local freeStart = body.Position
	body:ApplyImpulse(Vector3.new(body.AssemblyMass * 25, body.AssemblyMass * 12, 0))
	for _ = 1, 6 do
		RunService.Heartbeat:Wait()
	end
	local freeDelta = body.Position - freeStart
	assert(
		math.abs(freeDelta.X) > 0.01 or math.abs(freeDelta.Y) > 0.01,
		"x/y translation must remain physically free"
	)
	assert(math.abs(body.Position.Z - laneCenterZ) <= config.LaneHardBound, "upright correction escaped lane plane")

	stabilizer:Step()
	assert(model:GetAttribute("LaneHardBoundExceeded") == false, "mechanical plane lock must recover within the hard lane bound")

	racer:Destroy()
	assert(model.Parent == nil, "B10 RacerRuntime destroy left stabilized model behind")

	print("[DrawRacers][B10] stabilization/lane tests PASS")
end

return B10StabilizationSpec
