--!strict

local RedrawSafetyMath = {}

local DEFAULT_PHASE_OFFSETS = { 0, 15, -15, 30, -30, 45, -45, 60, -60, 75, -75, 90, -90 }

local function normalizeDegrees(value: number): number
	return (value + 180) % 360 - 180
end

function RedrawSafetyMath.AngularDistanceDegrees(a: number, b: number): number
	return math.abs(normalizeDegrees(a - b))
end

function RedrawSafetyMath.BuildCandidatePhases(currentPhaseDegrees: number): { number }
	local result = table.create(#DEFAULT_PHASE_OFFSETS)
	for _, offset in DEFAULT_PHASE_OFFSETS do
		table.insert(result, currentPhaseDegrees + offset)
	end
	return result
end

function RedrawSafetyMath.ChooseBestCandidate(
	currentPhaseDegrees: number,
	candidatePhases: { number },
	penetrationScores: { number }
): (number, number, boolean)
	assert(#candidatePhases > 0, "redraw safety requires phase candidates")
	assert(#candidatePhases == #penetrationScores, "phase candidates/scores length mismatch")

	local bestIndex = 1
	for index = 2, #candidatePhases do
		local score = penetrationScores[index]
		local bestScore = penetrationScores[bestIndex]
		if score < bestScore then
			bestIndex = index
		elseif score == bestScore then
			local distance = RedrawSafetyMath.AngularDistanceDegrees(candidatePhases[index], currentPhaseDegrees)
			local bestDistance = RedrawSafetyMath.AngularDistanceDegrees(candidatePhases[bestIndex], currentPhaseDegrees)
			if distance < bestDistance then
				bestIndex = index
			end
		end
	end

	local bestScore = penetrationScores[bestIndex]
	return candidatePhases[bestIndex], bestScore, bestScore > 0
end

return RedrawSafetyMath
