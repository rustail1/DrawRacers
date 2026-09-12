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
local STRUCTURAL_ERROR_LIMIT = 0.15
local MEASURE_SECONDS = 1.25

local function localPhaseDegrees(axleRoot: BasePart, sideRoot: BasePart): number
	local relative = axleRoot.CFrame:ToObjectSpace(sideRoot.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
end

local function structuralPhaseErrorDegrees(pair: any): number
	local axleRoot = pair:GetRoot()
	local left = localPhaseDegrees(axleRoot, pair:GetLeftLeg():GetRoot())
	local right = localPhaseDegrees(axleRoot, pair:GetRightLeg():GetRoot())
	local difference = (right - left + 360) % 360
	local signed = (difference - PHASE_TARGET_DEGREES + 180) % 360 - 180
	return math.abs(signed)
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

local function measureWindow(racer: any): (number, boolean, number)
	local elapsed = 0
	local maxStructuralError = 0
	local singleMotorSafe = true
	local startPhase = racer:GetLegPair():GetPhaseDegrees()

	while elapsed < MEASURE_SECONDS do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local pair = racer:GetLegPair()
		maxStructuralError = math.max(maxStructuralError, structuralPhaseErrorDegrees(pair))
		local joint = pair:GetJoint()
		singleMotorSafe = singleMotorSafe
			and countHinges(racer:GetModel()) == 1
			and joint.Name == "AxleJoint"
			and joint.Enabled
			and math.abs(joint.AngularVelocity - PhysicsConfig.Motor.AngularVelocity) <= 1e-6
	end

	local endPhase = racer:GetLegPair():GetPhaseDegrees()
	local axleTravel = math.abs((endPhase - startPhase + 180) % 360 - 180)
	return maxStructuralError, singleMotorSafe, axleTravel
end

local function runTrial(redraw: boolean): boolean
	local racer = RacerRuntime.new({
		raceId = if redraw then "R17_PHASE_REDRAW" else "R17_PHASE_RIGID",
		slotIndex = 1,
		laneIndex = 1,
		isBot = true,
		trackId = "R17_PHASE",
		spawnCFrame = CFrame.new(-120, 20, 0),
		laneCenterZ = 0,
	})

	local ok, result = xpcall(function()
		local body = racer:GetBody()
		body.Anchored = true
		racer:ApplyShape(R16ReferenceShapes.Get("ASYM_01"), true)
		local pair = racer:GetLegPair()
		assert(pair ~= nil, "R17 shared pair missing")
		assert(countHinges(racer:GetModel()) == 1, "R17 must have exactly one physical hinge")
		assert(structuralPhaseErrorDegrees(pair) <= STRUCTURAL_ERROR_LIMIT, "R17 initial side copies are not 180-degree opposed")

		if redraw then
			-- Let the one real axle rotate before redraw, then prove the replacement
			-- inherits that one axle phase while keeping the fixed 180-degree side relation.
			local waitElapsed = 0
			while waitElapsed < 0.35 do
				waitElapsed += RunService.Heartbeat:Wait()
			end
			local phaseBefore = racer:GetLegPair():GetPhaseDegrees()
			racer:ApplyShape(R16ReferenceShapes.Get("HOOK_01"), true)
			local phaseAfter = racer:GetLegPair():GetPhaseDegrees()
			local redrawDelta = math.abs((phaseAfter - phaseBefore + 180) % 360 - 180)
			assert(redrawDelta <= 1.0, string.format("R17 shared axle redraw phase jump %.3f", redrawDelta))
		end

		local maxStructuralError, singleMotorSafe, axleTravel = measureWindow(racer)
		local passed = maxStructuralError <= STRUCTURAL_ERROR_LIMIT and singleMotorSafe and axleTravel > 0.5
		print(string.format(
			"[DrawRacers][R17.5] redraw=%s opposedPhaseError=%.3f singleMotor=%s axleTravel=%.3f %s",
			tostring(redraw),
			maxStructuralError,
			tostring(singleMotorSafe),
			axleTravel,
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
	print("[DrawRacers][R17.5] shared-axle opposed-phase evidence starting")
	local rigidPassed = runTrial(false)
	local redrawPassed = runTrial(true)
	return rigidPassed and redrawPassed
end

return R17PhaseEvidence
