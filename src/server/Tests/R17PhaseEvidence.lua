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
local STEADY_ERROR_LIMIT = 5
local EXCURSION_ERROR_LIMIT = 10
local MAX_EXCURSION_SECONDS = 0.25
local MEASURE_SECONDS = 1.25

local function phaseDegrees(hub: BasePart, root: BasePart): number
	local relative = hub.CFrame:ToObjectSpace(root.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
end

local function phaseErrorDegrees(leftHub: BasePart, leftRoot: BasePart, rightHub: BasePart, rightRoot: BasePart): number
	local left = phaseDegrees(leftHub, leftRoot)
	local right = phaseDegrees(rightHub, rightRoot)
	local difference = (right - left + 360) % 360
	local signed = (difference - PHASE_TARGET_DEGREES + 180) % 360 - 180
	return math.abs(signed)
end

local function injectDrift(leftHub: BasePart, leftRoot: BasePart, rightHub: BasePart, rightRoot: BasePart)
	leftRoot.CFrame = leftHub.CFrame * CFrame.Angles(0, 0, math.rad(15))
	rightRoot.CFrame = rightHub.CFrame * CFrame.Angles(0, 0, math.rad(105))
	leftRoot.AssemblyAngularVelocity = Vector3.zero
	rightRoot.AssemblyAngularVelocity = Vector3.zero
end

local function measurePhaseWindow(
	leftHub: BasePart,
	leftRoot: BasePart,
	leftJoint: HingeConstraint,
	rightHub: BasePart,
	rightRoot: BasePart,
	rightJoint: HingeConstraint
): (number, number, boolean, number)
	local elapsed = 0
	local maxError = 0
	local currentExcursion = 0
	local longestExcursion = 0
	local motorSignSafe = true
	local velocityIntegral = 0
	local samples = 0

	while elapsed < MEASURE_SECONDS do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local errorDegrees = phaseErrorDegrees(leftHub, leftRoot, rightHub, rightRoot)
		maxError = math.max(maxError, errorDegrees)
		if errorDegrees > EXCURSION_ERROR_LIMIT then
			currentExcursion += dt
			longestExcursion = math.max(longestExcursion, currentExcursion)
		else
			currentExcursion = 0
		end

		local baseVelocity = PhysicsConfig.Motor.AngularVelocity
		motorSignSafe = motorSignSafe
			and leftJoint.AngularVelocity * baseVelocity > 0
			and rightJoint.AngularVelocity * baseVelocity > 0
		velocityIntegral += (leftJoint.AngularVelocity + rightJoint.AngularVelocity) * 0.5
		samples += 1
	end

	local steadyError = phaseErrorDegrees(leftHub, leftRoot, rightHub, rightRoot)
	local averageMotorVelocity = if samples > 0 then velocityIntegral / samples else 0
	return steadyError, longestExcursion, motorSignSafe, averageMotorVelocity
end

local function runTrial(redraw: boolean): boolean
	local racer = RacerRuntime.new({
		raceId = if redraw then "R17_PHASE_REDRAW" else "R17_PHASE_DRIFT",
		slotIndex = 1,
		laneIndex = 1,
		isBot = true,
		trackId = "R17_PHASE",
		spawnCFrame = CFrame.new(-120, 20, 0),
	})

	local ok, result = xpcall(function()
		local points = R16ReferenceShapes.Get("ASYM_01")
		local leftLeg, rightLeg = racer:ApplyShape(points, true)
		local body = racer:GetBody()
		body.Anchored = true

		if redraw then
			-- Exercise the real atomic redraw path before drift evidence.
			leftLeg, rightLeg = racer:ApplyShape(R16ReferenceShapes.Get("HOOK_01"), true)
		end

		local model = racer:GetModel()
		local leftHub = assert(model:FindFirstChild("LeftHub") :: BasePart?)
		local rightHub = assert(model:FindFirstChild("RightHub") :: BasePart?)
		local leftRoot = leftLeg:GetRoot()
		local rightRoot = rightLeg:GetRoot()
		local leftJoint = leftLeg:GetJoint()
		local rightJoint = rightLeg:GetJoint()
		leftJoint.Enabled = true
		rightJoint.Enabled = true

		injectDrift(leftHub, leftRoot, rightHub, rightRoot)
		local injectedError = phaseErrorDegrees(leftHub, leftRoot, rightHub, rightRoot)
		assert(injectedError >= 80, string.format("R17 phase fixture did not inject enough drift: %.3f", injectedError))

		local steadyError, longestExcursion, motorSignSafe, averageMotorVelocity = measurePhaseWindow(
			leftHub,
			leftRoot,
			leftJoint,
			rightHub,
			rightRoot,
			rightJoint
		)
		local averagePreserved = math.abs(averageMotorVelocity - PhysicsConfig.Motor.AngularVelocity) <= 0.15
		local passed = steadyError <= STEADY_ERROR_LIMIT
			and longestExcursion <= MAX_EXCURSION_SECONDS
			and motorSignSafe
			and averagePreserved

		print(string.format(
			"[DrawRacers][R17.5] redraw=%s steadyError=%.3f longest>10=%.3f motorSignSafe=%s averageMotorVelocity=%.3f target=%.3f %s",
			tostring(redraw),
			steadyError,
			longestExcursion,
			tostring(motorSignSafe),
			averageMotorVelocity,
			PhysicsConfig.Motor.AngularVelocity,
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
	print("[DrawRacers][R17.5] live phase evidence starting")
	local driftPassed = runTrial(false)
	local redrawPassed = runTrial(true)
	return driftPassed and redrawPassed
end

return R17PhaseEvidence
