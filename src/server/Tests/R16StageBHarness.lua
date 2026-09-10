--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local R16StageBHarness = {}

local started = false
local activeRacer: any = nil

local function findPiece(pieceId: string): any
	for _, piece in M0SceneConfig.Pieces do
		if piece.PieceId == pieceId then
			return piece
		end
	end
	error(string.format("missing canonical piece %s", pieceId))
end

local function matchesPrefix(name: string, prefix: string?): boolean
	if prefix == nil then
		return true
	end
	return string.sub(name, 1, #prefix) == prefix
end

local function hasTrackContact(model: Model, namePrefix: string?): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.CanTouch then
			for _, touchingPart in descendant:GetTouchingParts() do
				if not touchingPart:IsDescendantOf(model)
					and touchingPart.CollisionGroup == "Track"
					and matchesPrefix(touchingPart.Name, namePrefix)
				then
					return true
				end
			end
		end
	end
	return false
end

local function waitForTrackContact(racer: any, timeoutSeconds: number, namePrefix: string?): boolean
	local elapsed = 0
	while elapsed < timeoutSeconds do
		if hasTrackContact(racer:GetModel(), namePrefix) then
			return true
		end
		elapsed += RunService.Heartbeat:Wait()
	end
	return false
end

local function waitForContinuousTrackContact(racer: any, durationSeconds: number, namePrefix: string?): boolean
	local elapsed = 0
	while elapsed < durationSeconds do
		if not hasTrackContact(racer:GetModel(), namePrefix) then
			return false
		end
		elapsed += RunService.Heartbeat:Wait()
	end
	return true
end

local function allMotorsEnabled(model: Model): boolean
	local legs = model:FindFirstChild("Legs")
	if legs == nil then
		return false
	end
	for _, legName in { "LeftLeg", "RightLeg" } do
		local leg = legs:FindFirstChild(legName)
		if leg == nil then
			return false
		end
		local joint = leg:FindFirstChild("HubJoint")
		if joint == nil or not joint:IsA("HingeConstraint") or not joint.Enabled then
			return false
		end
	end
	return true
end

local function destroyActiveRacer()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
end

local function finishSpawnedRacer(racer: any, shapeId: string)
	activeRacer = racer
	local model = racer:GetModel()
	model:SetAttribute("R16StageBTrial", true)
	racer:ApplyShape(R16ReferenceShapes.Get(shapeId), true)
	-- Internal Studio/test shapes do not advance player ShapeVersion. Keep anti-stall
	-- semantics equivalent to a racer that already has one accepted authoritative shape.
	model:SetAttribute("ShapeVersion", 1)
	return racer
end

local function spawnTrialRacer(pieceId: string, shapeId: string, spawnX: number?): any
	destroyActiveRacer()
	local piece = findPiece(pieceId)
	local racer = RacerRuntime.new({
		raceId = "R16_STAGE_B",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R16_STAGE_B",
		spawnCFrame = CFrame.new(spawnX or (piece.StartX + 1), 3.3, 0),
		laneCenterZ = 0,
	})
	return finishSpawnedRacer(racer, shapeId)
end

local function spawnBenchmarkRacer(shapeId: string): any
	destroyActiveRacer()
	local benchmark = M0SceneConfig.ReferenceBenchmark
	local racer = RacerRuntime.new({
		raceId = "R16_STAGE_B_FLAT",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R16_REFERENCE_BENCHMARK",
		spawnCFrame = CFrame.new(benchmark.SpawnX, benchmark.SpawnY, benchmark.CenterZ),
		laneCenterZ = benchmark.CenterZ,
	})
	return finishSpawnedRacer(racer, shapeId)
end

local function gapTrialSpawnX(piece: any): number
	local gapWidth = assert(piece.GapWidth, "GapSmall missing GapWidth")
	local approachLength = (piece.Length - gapWidth) / 2
	return piece.StartX + approachLength - 2.0
end

local function runFlatSpeedTrial(shapeId: string): any
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local benchmark = M0SceneConfig.ReferenceBenchmark
	local racer = spawnBenchmarkRacer(shapeId)
	local model = racer:GetModel()
	local body = racer:GetBody()
	local result = {
		valid = true,
		speed = 0,
		antiStallSeen = false,
		motorsEnabled = false,
	}

	if not waitForTrackContact(racer, acceptance.TrackContactTimeout, benchmark.Name) then
		result.valid = false
		destroyActiveRacer()
		return result
	end

	-- The entire settle window must stay on the isolated benchmark. Losing benchmark
	-- contact invalidates the sample instead of silently measuring another obstacle.
	if not waitForContinuousTrackContact(racer, acceptance.FlatIgnoreSeconds, benchmark.Name) then
		result.valid = false
		destroyActiveRacer()
		return result
	end

	local startX = body.Position.X
	local elapsed = 0
	while elapsed < acceptance.FlatMeasureSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		if not hasTrackContact(model, benchmark.Name) then
			result.valid = false
			break
		end
		if model:GetAttribute("AntiStallActive") == true then
			result.antiStallSeen = true
		end
	end

	result.speed = (body.Position.X - startX) / math.max(elapsed, 1e-6)
	result.motorsEnabled = allMotorsEnabled(model)
	destroyActiveRacer()
	return result
end

local function runProgressTrial(
	pieceId: string,
	shapeId: string,
	measureSeconds: number,
	spawnX: number?,
	contactPrefix: string?
): any
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local piece = findPiece(pieceId)
	local racer = spawnTrialRacer(pieceId, shapeId, spawnX)
	local model = racer:GetModel()
	local body = racer:GetBody()

	if not waitForTrackContact(racer, acceptance.TrackContactTimeout, contactPrefix) then
		destroyActiveRacer()
		return {
			valid = false,
			progress = 0,
			maxDeltaY = 0,
			minDeltaY = 0,
			antiStallSeen = false,
			landedAfterGap = false,
			completedPiece = false,
		}
	end

	local startX = body.Position.X
	local startY = body.Position.Y
	local maxX = startX
	local maxY = startY
	local minY = startY
	local antiStallSeen = false
	local landedAfterGap = false
	local elapsed = 0
	local gapEnd: number? = nil
	if pieceId == "GapSmall" then
		local gapWidth = assert(piece.GapWidth, "GapSmall missing GapWidth")
		local approachLength = (piece.Length - gapWidth) / 2
		gapEnd = piece.StartX + approachLength + gapWidth
	end

	while elapsed < measureSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local position = body.Position
		maxX = math.max(maxX, position.X)
		maxY = math.max(maxY, position.Y)
		minY = math.min(minY, position.Y)
		if model:GetAttribute("AntiStallActive") == true then
			antiStallSeen = true
		end
		if gapEnd ~= nil and position.X >= gapEnd and hasTrackContact(model, nil) then
			landedAfterGap = true
		end
		if position.Y < M0SceneConfig.RecoveryKillY then
			break
		end
	end

	local result = {
		valid = true,
		progress = maxX - startX,
		maxDeltaY = maxY - startY,
		minDeltaY = minY - startY,
		antiStallSeen = antiStallSeen,
		landedAfterGap = landedAfterGap,
		completedPiece = maxX >= piece.StartX + piece.Length - 0.5,
	}
	destroyActiveRacer()
	return result
end

local function runFlatRoundTrial(): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local result = runFlatSpeedTrial("ROUND_01")
	local passed = result.valid
		and result.speed >= acceptance.FlatSpeedMin
		and result.speed <= acceptance.FlatSpeedMax
		and not result.antiStallSeen
		and result.motorsEnabled

	print(string.format(
		"[DrawRacers][R16.5] ROUND_01 FlatShort speed=%.3f target=%.1f..%.1f antiStall=%s motors=%s %s",
		result.speed,
		acceptance.FlatSpeedMin,
		acceptance.FlatSpeedMax,
		tostring(result.antiStallSeen),
		tostring(result.motorsEnabled),
		if passed then "PASS" else "FAIL"
	))
	return passed
end

local function runStepsVerticalTrial(): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local result = runProgressTrial("SmallSteps", "HOOK_01", acceptance.StepsMeasureSeconds, nil, "Step")
	local maxDeltaY = result.maxDeltaY
	local passed = result.valid and maxDeltaY >= acceptance.StepsRiseMin
	print(string.format(
		"[DrawRacers][R16.6] HOOK_01 SmallSteps maxDeltaY=%.3f target>=%.2f %s",
		maxDeltaY,
		acceptance.StepsRiseMin,
		if passed then "PASS" else "FAIL"
	))
	return passed
end

local function runGapVerticalTrial(): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local piece = findPiece("GapSmall")
	local result = runProgressTrial(
		"GapSmall",
		"SMALL_ROUND_01",
		acceptance.GapMeasureSeconds,
		gapTrialSpawnX(piece),
		nil
	)
	local minDeltaY = result.minDeltaY
	local fallDistance = -minDeltaY
	local crossedRecoveryKillY = fallDistance >= math.abs(M0SceneConfig.RecoveryKillY)
	local passed = result.valid and fallDistance >= acceptance.GapFallMin
	print(string.format(
		"[DrawRacers][R16.6] SMALL_ROUND_01 GapSmall minDeltaY=%.3f fall=%.3f target>=%.2f recoveryThreshold=%s %s",
		minDeltaY,
		fallDistance,
		acceptance.GapFallMin,
		tostring(crossedRecoveryKillY),
		if passed then "PASS" else "FAIL"
	))
	return passed
end

local function runShapeMatrix(): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance

	local roundFlat = runFlatSpeedTrial("ROUND_01")
	local suboptimalFlat = runFlatSpeedTrial("SUBOPTIMAL_01")
	local roundFlatPassed = roundFlat.valid
		and roundFlat.speed >= acceptance.FlatSpeedMin
		and roundFlat.speed <= acceptance.FlatSpeedMax
		and not roundFlat.antiStallSeen
		and roundFlat.motorsEnabled

	local stepsRound = runProgressTrial("SmallSteps", "ROUND_01", acceptance.StepsMeasureSeconds, nil, "Step")
	local stepsHook = runProgressTrial("SmallSteps", "HOOK_01", acceptance.StepsMeasureSeconds, nil, "Step")
	local stepsAsym = runProgressTrial("SmallSteps", "ASYM_01", acceptance.StepsMeasureSeconds, nil, "Step")
	local stepsBestProgress = math.max(stepsHook.progress, stepsAsym.progress)
	local stepsBestRise = math.max(stepsHook.maxDeltaY, stepsAsym.maxDeltaY)
	local stepHeight = assert(findPiece("SmallSteps").Height, "SmallSteps missing Height")
	local stepsNichePassed = stepsRound.valid
		and stepsHook.valid
		and stepsAsym.valid
		and (
			stepsBestProgress >= stepsRound.progress + acceptance.StepsProgressAdvantage
			or stepsBestRise >= stepsRound.maxDeltaY + stepHeight - 0.1
		)

	local gapPiece = findPiece("GapSmall")
	local gapSpawnX = gapTrialSpawnX(gapPiece)
	local gapLong = runProgressTrial("GapSmall", "LONG_BAR_01", acceptance.GapMeasureSeconds, gapSpawnX, nil)
	local gapSmall = runProgressTrial("GapSmall", "SMALL_ROUND_01", acceptance.GapMeasureSeconds, gapSpawnX, nil)
	local gapNichePassed = gapLong.valid
		and gapSmall.valid
		and (
			(gapLong.landedAfterGap and not gapSmall.landedAfterGap)
			or gapLong.progress >= gapSmall.progress + acceptance.GapProgressAdvantage
		)

	local tunnelSmall = runProgressTrial(
		"LowTunnelWide",
		"SMALL_ROUND_01",
		acceptance.TunnelMeasureSeconds,
		nil,
		nil
	)
	local tunnelLong = runProgressTrial(
		"LowTunnelWide",
		"LONG_BAR_01",
		acceptance.TunnelMeasureSeconds,
		nil,
		nil
	)
	local tunnelNichePassed = tunnelSmall.valid
		and tunnelLong.valid
		and (
			(tunnelSmall.completedPiece and not tunnelLong.completedPiece)
			or tunnelSmall.progress >= tunnelLong.progress + acceptance.TunnelProgressAdvantage
		)

	local suboptimalPassed = roundFlat.valid
		and suboptimalFlat.valid
		and roundFlat.speed > 0
		and suboptimalFlat.speed <= roundFlat.speed * (1 - acceptance.SuboptimalWorseRatio)

	local noUniversalWinner = stepsNichePassed and gapNichePassed and tunnelNichePassed and suboptimalPassed
	local passed = roundFlatPassed
		and stepsNichePassed
		and gapNichePassed
		and tunnelNichePassed
		and suboptimalPassed
		and noUniversalWinner

	print(string.format(
		"[DrawRacers][R16.7] matrix flatRound=%.3f flatSub=%.3f stepsRound=%.2f stepsBest=%.2f gapLong=%.2f gapSmall=%.2f tunnelSmall=%.2f tunnelLong=%.2f steps=%s gap=%s tunnel=%s suboptimal=%s noUniversalWinner=%s %s",
		roundFlat.speed,
		suboptimalFlat.speed,
		stepsRound.progress,
		stepsBestProgress,
		gapLong.progress,
		gapSmall.progress,
		tunnelSmall.progress,
		tunnelLong.progress,
		tostring(stepsNichePassed),
		tostring(gapNichePassed),
		tostring(tunnelNichePassed),
		tostring(suboptimalPassed),
		tostring(noUniversalWinner),
		if passed then "PASS" else "FAIL"
	))
	return passed
end

function R16StageBHarness.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R16StageBHarness evidence is Studio-only")
	local flatPassed = runFlatRoundTrial()
	local stepsPassed = runStepsVerticalTrial()
	local gapPassed = runGapVerticalTrial()
	local matrixPassed = runShapeMatrix()
	return flatPassed and stepsPassed and gapPassed and matrixPassed
end

function R16StageBHarness.start()
	assert(RunService:IsStudio(), "R16StageBHarness is Studio-only")
	if started then
		return
	end
	started = true
	print("[DrawRacers][R16B] Stage B reference measurement harness ready")

	task.spawn(function()
		local ok, result = xpcall(function()
			return R16StageBHarness.RunEvidence()
		end, debug.traceback)
		if not ok then
			warn("[DrawRacers][R16B] measurement harness error: " .. tostring(result))
			destroyActiveRacer()
		elseif result ~= true then
			warn("[DrawRacers][R16B] one or more Stage B evidence checks FAILED")
		end
	end)
end

function R16StageBHarness.stop()
	destroyActiveRacer()
	started = false
end

return R16StageBHarness
