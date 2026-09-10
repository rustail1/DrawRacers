--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StrokeMath = require(Shared:WaitForChild("Math"):WaitForChild("StrokeMath"))
local PhysicsConfig = require(Shared:WaitForChild("Config"):WaitForChild("PhysicsConfig"))

local B03StrokeMathSpec = {}

local function assertClose(actual: number, expected: number, epsilon: number, message: string)
	assert(math.abs(actual - expected) <= epsilon, string.format("%s: expected %.6f, got %.6f", message, expected, actual))
end

local function assertSamePoints(a: { Vector2 }, b: { Vector2 })
	assert(#a == #b, string.format("point counts differ: %d ~= %d", #a, #b))
	for index = 1, #a do
		assertClose(a[index].X, b[index].X, 1e-9, string.format("point %d X differs", index))
		assertClose(a[index].Y, b[index].Y, 1e-9, string.format("point %d Y differs", index))
	end
end

function B03StrokeMathSpec.run()
	local config = PhysicsConfig.StrokeProcessing
	local clampOptions = {
		minCoordinate = config.NormalizedMin,
		maxCoordinate = config.NormalizedMax,
		maxPoints = config.MaxRawPoints,
	}

	-- Legacy square clamp remains deterministic for callers that still use it.
	local outOfBounds = {
		Vector2.new(-2.5, 0.25),
		Vector2.new(0.5, 4.0),
		Vector2.new(1.5, -3.0),
	}
	local clamped, clampError = StrokeMath.Clamp(outOfBounds, clampOptions)
	assert(clampError == nil, tostring(clampError))
	assert(clamped ~= nil, "clamp unexpectedly rejected finite points")
	assertSamePoints(clamped, {
		Vector2.new(-1, 0.25),
		Vector2.new(0.5, 1),
		Vector2.new(1, -1),
	})

	-- R16.3B authoritative/raw input uses independent wide X and Y limits.
	local rectClamped, rectError = StrokeMath.ClampToRect(outOfBounds, {
		minX = -config.RawSemanticHalfWidth,
		maxX = config.RawSemanticHalfWidth,
		minY = -config.RawSemanticHalfHeight,
		maxY = config.RawSemanticHalfHeight,
		maxPoints = config.MaxRawPoints,
	})
	assert(rectError == nil, tostring(rectError))
	assert(rectClamped ~= nil, "rect clamp unexpectedly rejected finite points")
	assertSamePoints(rectClamped, {
		Vector2.new(-1.75, 0.25),
		Vector2.new(0.5, 1),
		Vector2.new(1.5, -1),
	})

	local nearDuplicates = {
		Vector2.new(0, 0),
		Vector2.new(0.004, 0.003),
		Vector2.new(0.02, 0),
		Vector2.new(0.026, 0.004),
		Vector2.new(0.05, 0),
	}
	local deduped = StrokeMath.Dedupe(nearDuplicates, config.DedupeDistance)
	assertSamePoints(deduped, {
		Vector2.new(0, 0),
		Vector2.new(0.02, 0),
		Vector2.new(0.05, 0),
	})

	local repeatA = StrokeMath.Dedupe(nearDuplicates, config.DedupeDistance)
	local repeatB = StrokeMath.Dedupe(nearDuplicates, config.DedupeDistance)
	assertSamePoints(repeatA, repeatB)

	local _, positiveInfinityError = StrokeMath.Clamp({ Vector2.new(math.huge, 0) }, clampOptions)
	assert(positiveInfinityError == "NON_FINITE_POINT")

	local _, negativeInfinityError = StrokeMath.Clamp({ Vector2.new(-math.huge, 0) }, clampOptions)
	assert(negativeInfinityError == "NON_FINITE_POINT")

	local nanValue = math.huge - math.huge
	local _, nanError = StrokeMath.Clamp({ Vector2.new(nanValue, 0) }, clampOptions)
	assert(nanError == "NON_FINITE_POINT")

	local tooMany = table.create(config.MaxRawPoints + 1)
	for index = 1, config.MaxRawPoints + 1 do
		tooMany[index] = Vector2.new(0, 0)
	end
	local _, tooManyError = StrokeMath.Clamp(tooMany, clampOptions)
	assert(tooManyError == "TOO_MANY_POINTS")

	print("[DrawRacers][B03] StrokeMath tests PASS")
end

return B03StrokeMathSpec
