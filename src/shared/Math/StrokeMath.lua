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

return StrokeMath
