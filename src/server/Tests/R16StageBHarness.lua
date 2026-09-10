--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local R16TrialRunner = require(script.Parent:WaitForChild("R16TrialRunner"))

local R16StageBHarness = {}

local ALL_SHAPES = {
	"ROUND_01",
	"LONG_BAR_01",
	"SMALL_ROUND_01",
	"HOOK_01",
	"ASYM_01",
	"SUBOPTIMAL_01",
}

local started = false

-- Compatibility names remain in this policy layer while reset/contact/measurement ownership
-- lives in R16TrialRunner.
local function runFlatSpeedTrial(shapeId: string): any
	return R16TrialRunner.RunFlat(shapeId)
end

local function runProgressTrial(
	pieceId: string,
	shapeId: string,
	measureSeconds: number,
	spawnX: number?,
	contactPrefix: string?
): any
	local options = {}
	if spawnX ~= nil then
		options.spawnX = spawnX
	end
	if contactPrefix ~= nil then
		options.contactPrefix = contactPrefix
	end
	return R16TrialRunner.RunPiece(pieceId, shapeId, measureSeconds, options)
end

local function resultScore(result: any, completionBonus: boolean): number
	if result.valid ~= true then
		return -math.huge
	end
	local score = result.progress
	if completionBonus and (result.completedPiece == true or result.landedAfterGap == true) then
		score += 1000
	end
	return score
end

local function winnerSet(results: { [string]: any }, metric: string): { string }
	local best = -math.huge
	local scores: { [string]: number } = {}
	for _, shapeId in ALL_SHAPES do
		local result = results[shapeId]
		local score: number
		if metric == "flat" then
			score = if result.valid == true then result.speed else -math.huge
		elseif metric == "gap" or metric == "tunnel" then
			score = resultScore(result, true)
		else
			score = resultScore(result, false)
		end
		scores[shapeId] = score
		best = math.max(best, score)
	end

	local winners = {}
	if best == -math.huge then
		return winners
	end
	for _, shapeId in ALL_SHAPES do
		if math.abs(scores[shapeId] - best) <= 0.05 then
			table.insert(winners, shapeId)
		end
	end
	return winners
end

local function intersectWinnerSets(winnerSets: { { string } }): { string }
	if #winnerSets == 0 then
		return {}
	end
	local present: { [string]: boolean } = {}
	for _, shapeId in winnerSets[1] do
		present[shapeId] = true
	end
	for setIndex = 2, #winnerSets do
		local nextPresent: { [string]: boolean } = {}
		for _, shapeId in winnerSets[setIndex] do
			if present[shapeId] == true then
				nextPresent[shapeId] = true
			end
		end
		present = nextPresent
	end
	local result = {}
	for _, shapeId in ALL_SHAPES do
		if present[shapeId] == true then
			table.insert(result, shapeId)
		end
	end
	return result
end

local function measureAllFlat(): { [string]: any }
	local results = {}
	for _, shapeId in ALL_SHAPES do
		results[shapeId] = R16TrialRunner.RunFlat(shapeId)
	end
	return results
end

local function measureAllPiece(pieceId: string, seconds: number, contactPrefix: string?): { [string]: any }
	local results = {}
	for _, shapeId in ALL_SHAPES do
		local options = if contactPrefix ~= nil then { contactPrefix = contactPrefix } else nil
		results[shapeId] = R16TrialRunner.RunPiece(pieceId, shapeId, seconds, options)
	end
	return results
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
	local result = R16TrialRunner.RunPiece("GapSmall", "SMALL_ROUND_01", acceptance.GapMeasureSeconds, nil)
	local minDeltaY = result.minDeltaY
	local fallDistance = -minDeltaY
	local passed = result.valid and fallDistance >= acceptance.GapFallMin
	print(string.format(
		"[DrawRacers][R16.6] SMALL_ROUND_01 GapSmall minDeltaY=%.3f fall=%.3f target>=%.2f %s",
		minDeltaY,
		fallDistance,
		acceptance.GapFallMin,
		if passed then "PASS" else "FAIL"
	))
	return passed
end

local function runShapeMatrix(): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local flatResults = measureAllFlat()
	local stepsResults = measureAllPiece("SmallSteps", acceptance.StepsMeasureSeconds, "Step")
	local gapResults = measureAllPiece("GapSmall", acceptance.GapMeasureSeconds, nil)
	local tunnelResults = measureAllPiece("LowTunnelWide", acceptance.TunnelMeasureSeconds, nil)

	local roundFlat = flatResults.ROUND_01
	local roundFlatPassed = roundFlat.valid
		and roundFlat.speed >= acceptance.FlatSpeedMin
		and roundFlat.speed <= acceptance.FlatSpeedMax
		and not roundFlat.antiStallSeen
		and roundFlat.motorsEnabled

	local stepsRound = stepsResults.ROUND_01
	local stepsHook = stepsResults.HOOK_01
	local stepsAsym = stepsResults.ASYM_01
	local stepsBestProgress = math.max(stepsHook.progress, stepsAsym.progress)
	local stepsBestRise = math.max(stepsHook.maxDeltaY, stepsAsym.maxDeltaY)
	local stepHeight = assert(R16TrialRunner.FindPiece("SmallSteps").Height, "SmallSteps missing Height")
	local stepsNichePassed = stepsRound.valid
		and (stepsHook.valid or stepsAsym.valid)
		and (
			stepsBestProgress >= stepsRound.progress + acceptance.StepsProgressAdvantage
			or stepsBestRise >= stepsRound.maxDeltaY + stepHeight - 0.1
		)

	local gapLong = gapResults.LONG_BAR_01
	local gapSmall = gapResults.SMALL_ROUND_01
	local gapNichePassed = gapLong.valid
		and gapSmall.valid
		and (
			(gapLong.landedAfterGap and not gapSmall.landedAfterGap)
			or gapLong.progress >= gapSmall.progress + acceptance.GapProgressAdvantage
		)

	local tunnelSmall = tunnelResults.SMALL_ROUND_01
	local tunnelLong = tunnelResults.LONG_BAR_01
	local tunnelNichePassed = tunnelSmall.valid
		and tunnelLong.valid
		and (
			(tunnelSmall.completedPiece and not tunnelLong.completedPiece)
			or tunnelSmall.progress >= tunnelLong.progress + acceptance.TunnelProgressAdvantage
		)

	local bestFlatSpeed = 0
	local bestStepsProgress = 0
	for _, shapeId in ALL_SHAPES do
		local flat = flatResults[shapeId]
		local steps = stepsResults[shapeId]
		if flat.valid then
			bestFlatSpeed = math.max(bestFlatSpeed, flat.speed)
		end
		if steps.valid then
			bestStepsProgress = math.max(bestStepsProgress, steps.progress)
		end
	end
	local suboptimalFlat = flatResults.SUBOPTIMAL_01
	local suboptimalSteps = stepsResults.SUBOPTIMAL_01
	local suboptimalFlatPassed = bestFlatSpeed > 0
		and suboptimalFlat.valid
		and suboptimalFlat.speed <= bestFlatSpeed * (1 - acceptance.SuboptimalWorseRatio)
	local suboptimalStepsPassed = bestStepsProgress > 0
		and (
			suboptimalSteps.valid ~= true
			or suboptimalSteps.progress <= bestStepsProgress * (1 - acceptance.SuboptimalWorseRatio)
		)
	local suboptimalPassed = suboptimalFlatPassed or suboptimalStepsPassed

	local winnerSets = {
		winnerSet(flatResults, "flat"),
		winnerSet(stepsResults, "steps"),
		winnerSet(gapResults, "gap"),
		winnerSet(tunnelResults, "tunnel"),
	}
	local universalWinners = intersectWinnerSets(winnerSets)
	local noUniversalWinner = #universalWinners == 0
	local passed = roundFlatPassed
		and stepsNichePassed
		and gapNichePassed
		and tunnelNichePassed
		and suboptimalPassed
		and noUniversalWinner

	print(string.format(
		"[DrawRacers][R16.7] matrix flatRound=%.3f flatBest=%.3f stepsRound=%.2f stepsBest=%.2f gapLong=%.2f gapSmall=%.2f tunnelSmall=%.2f tunnelLong=%.2f steps=%s gap=%s tunnel=%s suboptimalFlat=%s suboptimalSteps=%s noUniversalWinner=%s universalCount=%d %s",
		roundFlat.speed,
		bestFlatSpeed,
		stepsRound.progress,
		stepsBestProgress,
		gapLong.progress,
		gapSmall.progress,
		tunnelSmall.progress,
		tunnelLong.progress,
		tostring(stepsNichePassed),
		tostring(gapNichePassed),
		tostring(tunnelNichePassed),
		tostring(suboptimalFlatPassed),
		tostring(suboptimalStepsPassed),
		tostring(noUniversalWinner),
		#universalWinners,
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
	R16TrialRunner.DestroyActive()
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
			R16TrialRunner.DestroyActive()
		elseif result ~= true then
			warn("[DrawRacers][R16B] one or more Stage B evidence checks FAILED")
		end
	end)
end

function R16StageBHarness.stop()
	R16TrialRunner.DestroyActive()
	started = false
end

return R16StageBHarness
