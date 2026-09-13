--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local R17PhaseEvidence = {}

local PHASE_TARGET_DEGREES = 180
local PHASE_ERROR_LIMIT_DEGREES = 12.0
local MEASURE_SECONDS = 1.25

local function angularDistanceDegrees(a: number, b: number): number
	local delta = (b - a + 180) % 360 - 180
	return math.abs(delta)
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

local function twinMotorsSafe(pair: any, model: Model): boolean
	local leftDrive = pair:GetLeftDrive()
	local rightDrive = pair:GetRightDrive()
	local leftJoint = leftDrive:GetJoint()
	local rightJoint = rightDrive:GetJoint()
	return countHinges(model) == 2
		and leftJoint.Name == "DriveJoint"
		and rightJoint.Name == "DriveJoint"
		and leftJoint:IsA("HingeConstraint")
		and rightJoint:IsA("HingeConstraint")
		and leftJoint.ActuatorType == Enum.ActuatorType.Motor
		and rightJoint.ActuatorType == Enum.ActuatorType.Motor
		and leftJoint.Enabled
		and rightJoint.Enabled
end

local function measureWindow(racer: any): (number, boolean, number)
	local pair = racer:GetLegPair()
	assert(pair ~= nil, "R17 CR2 pair missing")
	local leftDrive = pair:GetLeftDrive()
	local rightDrive = pair:GetRightDrive()
	local previousLeft = leftDrive:GetPhaseDegrees()
	local previousRight = rightDrive:GetPhaseDegrees()
	local leftTravel = 0
	local rightTravel = 0
	local maxPhaseError = math.abs(pair:GetPhaseErrorDegrees())
	local twinMotorSafe = twinMotorsSafe(pair, racer:GetModel())
	local elapsed = 0

	while elapsed < MEASURE_SECONDS do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local currentPair = racer:GetLegPair()
		if currentPair ~= pair then
			twinMotorSafe = false
			break
		end
		local currentLeft = leftDrive:GetPhaseDegrees()
		local currentRight = rightDrive:GetPhaseDegrees()
		leftTravel += angularDistanceDegrees(previousLeft, currentLeft)
		rightTravel += angularDistanceDegrees(previousRight, currentRight)
		previousLeft = currentLeft
		previousRight = currentRight
		maxPhaseError = math.max(maxPhaseError, math.abs(pair:GetPhaseErrorDegrees()))
		twinMotorSafe = twinMotorSafe and twinMotorsSafe(pair, racer:GetModel())
	end

	return maxPhaseError, twinMotorSafe, math.min(leftTravel, rightTravel)
end

local function runTrial(redraw: boolean): boolean
	local racer = RacerRuntime.new({
		raceId = if redraw then "R17_PHASE_REDRAW" else "R17_PHASE_TWIN",
		slotIndex = 1,
		laneIndex = 1,
		isBot = true,
		trackId = "R17_PHASE",
		spawnCFrame = CFrame.new(-120, 20, 0),
		laneCenterZ = 0,
	})

	local ok, result = xpcall(function()
		assert(PhysicsConfig.Motor.RightPhaseOffsetDegrees == PHASE_TARGET_DEGREES, "R17 CR2 phase target drift")
		local body = racer:GetBody()
		body.Anchored = true
		racer:ApplyShape(R16ReferenceShapes.Get("ASYM_01"), true)
		local pair = racer:GetLegPair()
		assert(pair ~= nil, "R17 CR2 pair missing")
		assert(countHinges(racer:GetModel()) == 2, "R17 CR2 must have exactly two physical hinges")
		assert(math.abs(pair:GetPhaseErrorDegrees()) <= PHASE_ERROR_LIMIT_DEGREES, "R17 CR2 initial twin-drive phase error too large")

		if redraw then
			local waitElapsed = 0
			while waitElapsed < 0.35 do
				waitElapsed += RunService.Heartbeat:Wait()
			end
			local pairBefore = racer:GetLegPair()
			assert(pairBefore ~= nil)
			local leftBefore = pairBefore:GetLeftDrive()
			local rightBefore = pairBefore:GetRightDrive()
			local leftJointBefore = leftBefore:GetJoint()
			local rightJointBefore = rightBefore:GetJoint()

			racer:ApplyShape(R16ReferenceShapes.Get("HOOK_01"), true)

			local pairAfter = racer:GetLegPair()
			assert(pairAfter == pairBefore, "R17 CR2 redraw replaced pair")
			local leftAfter = pairAfter:GetLeftDrive()
			local rightAfter = pairAfter:GetRightDrive()
			assert(leftAfter == leftBefore, "R17 CR2 redraw replaced LeftDrive")
			assert(rightAfter == rightBefore, "R17 CR2 redraw replaced RightDrive")
			assert(leftAfter:GetJoint() == leftJointBefore, "R17 CR2 redraw replaced left DriveJoint")
			assert(rightAfter:GetJoint() == rightJointBefore, "R17 CR2 redraw replaced right DriveJoint")
			assert(math.abs(pairAfter:GetPhaseErrorDegrees()) <= PHASE_ERROR_LIMIT_DEGREES, "R17 CR2 redraw phase error too large")
		end

		local maxPhaseError, twinMotorSafe, minimumDriveTravel = measureWindow(racer)
		local passed = maxPhaseError <= PHASE_ERROR_LIMIT_DEGREES and twinMotorSafe and minimumDriveTravel > 0.5
		print(string.format(
			"[DrawRacers][R17.5] redraw=%s phaseTarget=%d maxPhaseError=%.3f twinMotors=%s minDriveTravel=%.3f %s",
			tostring(redraw),
			PHASE_TARGET_DEGREES,
			maxPhaseError,
			tostring(twinMotorSafe),
			minimumDriveTravel,
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
	print("[DrawRacers][R17.5] CR2 twin-drive opposed-phase evidence starting")
	local baselinePassed = runTrial(false)
	local redrawPassed = runTrial(true)
	return baselinePassed and redrawPassed
end

return R17PhaseEvidence
