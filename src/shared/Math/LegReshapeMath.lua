--!strict

local LegReshapeMath = {}

export type ReshapeState = {
	completeSegments: number,
	partialSegmentIndex: number?,
	partialEndpoint: Vector2?,
	totalLength: number,
	builtLength: number,
}

function LegReshapeMath.Evaluate(segmentPlan: { any }, progress: number): ReshapeState
	local clampedProgress = math.clamp(progress, 0, 1)
	local totalLength = 0
	for _, planned in segmentPlan do
		local a = planned.a
		local b = planned.b
		if typeof(a) == "Vector2" and typeof(b) == "Vector2" then
			totalLength += (b - a).Magnitude
		end
	end

	if totalLength <= 0 then
		return {
			completeSegments = 0,
			partialSegmentIndex = nil,
			partialEndpoint = nil,
			totalLength = 0,
			builtLength = 0,
		}
	end

	local targetLength = totalLength * clampedProgress
	local builtLength = 0
	local completeSegments = 0
	local partialSegmentIndex = nil
	local partialEndpoint = nil

	for index, planned in segmentPlan do
		local a = planned.a
		local b = planned.b
		if typeof(a) == "Vector2" and typeof(b) == "Vector2" then
			local delta = b - a
			local segmentLength = delta.Magnitude
			local remaining = targetLength - builtLength

			if segmentLength <= 0 then
				completeSegments = index
			elseif remaining >= segmentLength - 1e-6 then
				builtLength += segmentLength
				completeSegments = index
			elseif remaining > 0 then
				local t = math.clamp(remaining / segmentLength, 0, 1)
				partialSegmentIndex = index
				partialEndpoint = a + delta * t
				builtLength += remaining
				break
			else
				partialSegmentIndex = index
				partialEndpoint = a
				break
			end
		end
	end

	if clampedProgress >= 1 then
		completeSegments = #segmentPlan
		partialSegmentIndex = nil
		partialEndpoint = nil
		builtLength = totalLength
	end

	return {
		completeSegments = completeSegments,
		partialSegmentIndex = partialSegmentIndex,
		partialEndpoint = partialEndpoint,
		totalLength = totalLength,
		builtLength = builtLength,
	}
end

return LegReshapeMath
