--!strict

local StrokeMath = {}

export type ClampOptions = {
	minCoordinate: number,
	maxCoordinate: number,
	maxPoints: number?,
}

export type RectClampOptions = {
	minX: number,
	maxX: number,
	minY: number,
	maxY: number,
	maxPoints: number?,
}

export type Bounds = {
	min: Vector2,
	max: Vector2,
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

function StrokeMath.ClampToRect(points: { Vector2 }, options: RectClampOptions): ({ Vector2 }?, string?)
	if not isFiniteNumber(options.minX)
		or not isFiniteNumber(options.maxX)
		or not isFiniteNumber(options.minY)
		or not isFiniteNumber(options.maxY)
		or options.minX > options.maxX
		or options.minY > options.maxY
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
			math.clamp(point.X, options.minX, options.maxX),
			math.clamp(point.Y, options.minY, options.maxY)
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

	-- R16.3B: one pixel has the same semantic scale on X and Y. The input
	-- rectangle height defines one full semantic diameter; extra width expands X.
	local unit = canvasSize.Y * 0.5
	local center = canvasSize * 0.5
	local result = table.create(#points)
	for index, point in points do
		assert(StrokeMath.IsFinitePoint(point), "Normalize received a non-finite point")
		result[index] = Vector2.new(
			(point.X - center.X) / unit,
			(center.Y - point.Y) / unit
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

function StrokeMath.ComputeBounds(points: { Vector2 }): Bounds?
	if #points == 0 then
		return nil
	end

	local first = points[1]
	assert(StrokeMath.IsFinitePoint(first), "ComputeBounds received a non-finite point")
	local minX = first.X
	local minY = first.Y
	local maxX = first.X
	local maxY = first.Y

	for index = 2, #points do
		local point = points[index]
		assert(StrokeMath.IsFinitePoint(point), "ComputeBounds received a non-finite point")
		minX = math.min(minX, point.X)
		minY = math.min(minY, point.Y)
		maxX = math.max(maxX, point.X)
		maxY = math.max(maxY, point.Y)
	end

	return {
		min = Vector2.new(minX, minY),
		max = Vector2.new(maxX, maxY),
	}
end

function StrokeMath.CenterOnBounds(points: { Vector2 }): { Vector2 }
	if #points == 0 then
		return {}
	end

	local bounds = StrokeMath.ComputeBounds(points)
	assert(bounds ~= nil, "CenterOnBounds requires non-empty finite points")
	local center = (bounds.min + bounds.max) * 0.5
	local result = table.create(#points)
	for index, point in points do
		result[index] = point - center
	end
	return result
end

function StrokeMath.AnchorToFirstPoint(points: { Vector2 }): { Vector2 }
	if #points == 0 then
		return {}
	end
	local origin = points[1]
	assert(StrokeMath.IsFinitePoint(origin), "AnchorToFirstPoint requires finite points")
	local result = table.create(#points)
	for index, point in points do
		assert(StrokeMath.IsFinitePoint(point), "AnchorToFirstPoint received a non-finite point")
		result[index] = point - origin
	end
	return result
end

function StrokeMath.SimplifyRDP(points: { Vector2 }, epsilon: number): { Vector2 }
	assert(isFiniteNumber(epsilon) and epsilon >= 0, "epsilon must be a finite non-negative number")
	if #points <= 2 then
		return copyPoints(points)
	end

	local first = points[1]
	local last = points[#points]
	local line = last - first
	local lineLengthSquared = line:Dot(line)

	local maxDistance = -1
	local splitIndex = 0
	for index = 2, #points - 1 do
		local point = points[index]
		local distance: number
		if lineLengthSquared <= 0 then
			distance = (point - first).Magnitude
		else
			local t = math.clamp((point - first):Dot(line) / lineLengthSquared, 0, 1)
			local projection = first + line * t
			distance = (point - projection).Magnitude
		end
		if distance > maxDistance then
			maxDistance = distance
			splitIndex = index
		end
	end

	if maxDistance <= epsilon or splitIndex == 0 then
		return { first, last }
	end

	local leftInput = table.create(splitIndex)
	for index = 1, splitIndex do
		leftInput[index] = points[index]
	end
	local rightInput = table.create(#points - splitIndex + 1)
	for index = splitIndex, #points do
		rightInput[index - splitIndex + 1] = points[index]
	end

	local left = StrokeMath.SimplifyRDP(leftInput, epsilon)
	local right = StrokeMath.SimplifyRDP(rightInput, epsilon)
	local result = table.create(#left + #right - 1)
	for index = 1, #left do
		result[index] = left[index]
	end
	for index = 2, #right do
		table.insert(result, right[index])
	end
	return result
end

function StrokeMath.Resample(points: { Vector2 }, targetCount: number): { Vector2 }
	assert(targetCount >= 2 and math.floor(targetCount) == targetCount, "targetCount must be an integer >= 2")
	if #points == 0 then
		return {}
	end
	if #points == 1 then
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

	local result = table.create(targetCount)
	local segmentIndex = 2
	for sampleIndex = 0, targetCount - 1 do
		local targetDistance = totalLength * (sampleIndex / (targetCount - 1))
		while segmentIndex < #points and cumulative[segmentIndex] < targetDistance do
			segmentIndex += 1
		end

		local previousIndex = math.max(1, segmentIndex - 1)
		local previousDistance = cumulative[previousIndex]
		local nextDistance = cumulative[segmentIndex]
		local segmentLength = nextDistance - previousDistance
		local t = if segmentLength <= 0 then 0 else (targetDistance - previousDistance) / segmentLength
		result[sampleIndex + 1] = points[previousIndex]:Lerp(points[segmentIndex], t)
	end
	return result
end

return StrokeMath
