--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local R17PhaseEvidence = {}

local FIXED_PHASE_TARGET = 180
local MEASURE_SECONDS = 1.25

local function countHinges(model: Model): number
	local count = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

local function sharedMotorSafe(pair: any, model: Model): boolean
	local drive = pair:GetDrive()
	local joint = drive:GetJoint()

	return countHinges(model) == 1
		and joint.Name == "DriveJoint"
		and joint:IsA("HingeConstraint")
		and joint.ActuatorType == Enum.ActuatorType.Motor
		and joint.Enabled
		and math.abs(pair:GetPhaseErrorDegrees()) <= 1e-6
end

local function signedTravelDelta(fromDegrees: number, toDegrees: number): number
	return (toDegrees - fromDegrees + 180) % 360 - 180
end

local function measureWindow(racer: any): (boolean, number)
	local pair = racer:GetLegPair()
	assert(pair ~= nil, "R17 shared-drive pair missing")

	local drive = pair:GetDrive()
	local previous = drive:GetPhaseDegrees()
	local travel = 0
	local safe = sharedMotorSafe(pair, racer:GetModel())
	local elapsed = 0

	while elapsed < MEASURE_SECONDS do
		elapsed += RunService.Heartbeat:Wait()

		local currentPair = racer:GetLegPair()
		if currentPair ~= pair then
			safe = false
			break
		end

		local current = drive:GetPhaseDegrees()
		travel += math.abs(signedTravelDelta(previous, current))
		previous = current

		safe = safe and sharedMotorSafe(pair, racer:GetModel())
	end

	return safe, travel
end

local function runTrial(redraw: boolean): boolean
	local racer = RacerRuntime.new({
		raceId = if redraw
			then "R17_PHASE_REDRAW"
			else "R17_PHASE_SHARED",
		slotIndex = 1,
		laneIndex = 1,
		isBot = true,
		trackId = "R17_PHASE",
		spawnCFrame = CFrame.new(-120, 20, 0),
		laneCenterZ = 0,
	})

	local ok, result = xpcall(function()
		assert(
			PhysicsConfig.LegGeometry.RightLegFixedPhaseDegrees == FIXED_PHASE_TARGET,
			"R17 fixed right phase target drift"
		)

		local body = racer:GetBody()
		body.Anchored = true

		racer:ApplyShape(R16ReferenceShapes.Get("ASYM_01"), true)

		local pair = racer:GetLegPair()
		assert(pair ~= nil, "R17 shared-drive pair missing")
		assert(countHinges(racer:GetModel()) == 1, "R17 requires exactly one physical hinge")
		assert(sharedMotorSafe(pair, racer:GetModel()), "R17 shared motor unsafe")

		if redraw then
			local pairBefore = racer:GetLegPair()
			assert(pairBefore ~= nil)

			local driveBefore = pairBefore:GetDrive()
			local jointBefore = driveBefore:GetJoint()

			racer:ApplyShape(R16ReferenceShapes.Get("HOOK_01"), true)

			local pairAfter = racer:GetLegPair()
			assert(pairAfter == pairBefore, "R17 redraw replaced pair")
			assert(pairAfter:GetDrive() == driveBefore, "R17 redraw replaced SharedLegDrive")
			assert(pairAfter:GetDrive():GetJoint() == jointBefore, "R17 redraw replaced DriveJoint")
			assert(sharedMotorSafe(pairAfter, racer:GetModel()), "R17 redraw left shared motor unsafe")
		end

		local motorSafe, driveTravel = measureWindow(racer)
		local passed = motorSafe and driveTravel > 0.5

		print(string.format(
			"[DrawRacers][R17.5] redraw=%s fixedPhase=%d sharedMotor=%s driveTravel=%.3f %s",
			tostring(redraw),
			FIXED_PHASE_TARGET,
			tostring(motorSafe),
			driveTravel,
			if passed then "PASS" else "FAIL"
		))

		return passed
	end, debug.traceback)

	racer:Destroy()

	if not ok then
		warn(result)
		return false
	end

	return result == true
end

function R17PhaseEvidence.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R17PhaseEvidence is Studio-only")

	print("[DrawRacers][R17.5] one-hinge shared-drive evidence starting")
	local baselinePassed = runTrial(false)
	local redrawPassed = runTrial(true)
	return baselinePassed and redrawPassed
end

return R17PhaseEvidence
