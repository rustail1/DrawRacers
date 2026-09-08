--!strict

local StrokeMath = {}

export type ClampOptions = {
	minCoordinate: number,
	maxCoordinate: number,
	maxPoints: number?,
}

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function copyPoints(points: { Vector2 }): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = point
	end
	return result
end

function StrokeMath.IsFinitePoint(point: Vector2): boolean
	return isFiniteNumber(point.X) and isFiniteNumber(point.Y)
end

function StrokeMath.Clamp(points: { Vector2 }, options: ClampOptions): ({ Vector2 }?, string?)
	local minCoordinate = options.minCoordinate
	local maxCoordinate = options.maxCoordinate

	if not isFiniteNumber(minCoordinate)
		or not isFiniteNumber(maxCoordinate)
		or minCoordinate > maxCoordinate
	then
		return nil, "INVALID_BOUNDS"
	end

	local maxPoints = options.maxPoints
	if maxPoints ~= nil and #points > maxPoints then
		return nil, "TOO_MANY_POINTS"
	end

	local result = table.create(#points)
	for index, point in points do
		if not StrokeMath.IsFinitePoint(point) then
			return nil, "NON_FINITE_POINT"
		end

		result[index] = Vector2.new(
			math.clamp(point.X, minCoordinate, maxCoordinate),
			math.clamp(point.Y, minCoordinate, maxCoordinate)
		)
	end

	return result, nil
end

function StrokeMath.Dedupe(points: { Vector2 }, minDistance: number): { Vector2 }
	assert(isFiniteNumber(minDistance) and minDistance >= 0, "minDistance must be a finite non-negative number")

	if #points == 0 then
		return {}
	end

	local result = table.create(#points)
	local lastKept = points[1]
	assert(StrokeMath.IsFinitePoint(lastKept), "Dedupe received a non-finite point")
	table.insert(result, lastKept)

	local thresholdSquared = minDistance * minDistance
	for index = 2, #points do
		local point = points[index]
		assert(StrokeMath.IsFinitePoint(point), "Dedupe received a non-finite point")

		local delta = point - lastKept
		if delta:Dot(delta) >= thresholdSquared then
			table.insert(result, point)
			lastKept = point
		end
	end

	return result
end

function StrokeMath.Normalize(points: { Vector2 }, canvasSize: Vector2): { Vector2 }
	assert(StrokeMath.IsFinitePoint(canvasSize), "canvasSize must be finite")
	assert(canvasSize.X > 0 and canvasSize.Y > 0, "canvasSize must be positive")

	local result = table.create(#points)
	for index, point in points do
		assert(StrokeMath.IsFinitePoint(point), "Normalize received a non-finite point")
		result[index] = Vector2.new(
			(point.X / canvasSize.X) * 2 - 1,
			1 - (point.Y / canvasSize.Y) * 2
		)
	end
	return result
end

function StrokeMath.MeasureLength(points: { Vector2 }): number
	local total = 0
	for index = 2, #points do
		local a = points[index - 1]
		local b = points[index]
		assert(StrokeMath.IsFinitePoint(a) and StrokeMath.IsFinitePoint(b), "MeasureLength received a non-finite point")
		total += (b - a).Magnitude
	end
	return total
end

local function pointToSegmentDistance(point: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local lengthSquared = ab:Dot(ab)
	if lengthSquared <= 0 then
		return (point - a).Magnitude
	end

	local t = math.clamp((point - a):Dot(ab) / lengthSquared, 0, 1)
	local projection = a + ab * t
	return (point - projection).Magnitude
end

function StrokeMath.SimplifyRDP(points: { Vector2 }, epsilon: number): { Vector2 }
	assert(isFiniteNumber(epsilon) and epsilon >= 0, "epsilon must be a finite non-negative number")
	for _, point in points do
		assert(StrokeMath.IsFinitePoint(point), "SimplifyRDP received a non-finite point")
	end

	if #points <= 2 then
		return copyPoints(points)
	end

	local first = points[1]
	local last = points[#points]
	local furthestIndex = 0
	local furthestDistance = -1

	for index = 2, #points - 1 do
		local distance = pointToSegmentDistance(points[index], first, last)
		if distance > furthestDistance then
			furthestDistance = distance
			furthestIndex = index
		end
	end

	if furthestDistance <= epsilon or furthestIndex == 0 then
		return { first, last }
	end

	local leftInput = table.create(furthestIndex)
	for index = 1, furthestIndex do
		leftInput[index] = points[index]
	end

	local rightCount = #points - furthestIndex + 1
	local rightInput = table.create(rightCount)
	for index = furthestIndex, #points do
		rightInput[index - furthestIndex + 1] = points[index]
	end

	local left = StrokeMath.SimplifyRDP(leftInput, epsilon)
	local right = StrokeMath.SimplifyRDP(rightInput, epsilon)
	local result = table.create(#left + #right - 1)

	for index = 1, #left do
		result[index] = left[index]
	end
	for index = 2, #right do
		result[#result + 1] = right[index]
	end

	return result
end

function StrokeMath.Resample(points: { Vector2 }, targetPoints: number): { Vector2 }
	assert(targetPoints >= 1 and targetPoints % 1 == 0, "targetPoints must be a positive integer")
	for _, point in points do
		assert(StrokeMath.IsFinitePoint(point), "Resample received a non-finite point")
	end

	if #points == 0 then
		return {}
	end
	if #points == 1 or targetPoints == 1 then
		return { points[1] }
	end

	local cumulative = table.create(#points)
	cumulative[1] = 0
	for index = 2, #points do
		cumulative[index] = cumulative[index - 1] + (points[index] - points[index - 1]).Magnitude
	end

	local totalLength = cumulative[#points]
	if totalLength <= 0 then
		return { points[1] }
	end

	local result = table.create(targetPoints)
	local segmentIndex = 2
	for sampleIndex = 0, targetPoints - 1 do
		local targetDistance = if sampleIndex == targetPoints - 1
			then totalLength
			else totalLength * (sampleIndex / (targetPoints - 1))

		while segmentIndex < #points and cumulative[segmentIndex] < targetDistance do
			segmentIndex += 1
		end

		local segmentStartIndex = math.max(1, segmentIndex - 1)
		local segmentEndIndex = math.min(#points, segmentIndex)
		local startDistance = cumulative[segmentStartIndex]
		local endDistance = cumulative[segmentEndIndex]
		local denominator = endDistance - startDistance
		local alpha = if denominator > 0 then (targetDistance - startDistance) / denominator else 0

		result[sampleIndex + 1] = points[segmentStartIndex]:Lerp(points[segmentEndIndex], math.clamp(alpha, 0, 1))
	end

	return result
end

return StrokeMath
