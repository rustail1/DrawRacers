--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StrokeMath = require(Shared:WaitForChild("Math"):WaitForChild("StrokeMath"))
local PhysicsConfig = require(Shared:WaitForChild("Config"):WaitForChild("PhysicsConfig"))

local B04StrokeMathSpec = {}

local function assertClose(actual: number, expected: number, epsilon: number, message: string)
	assert(math.abs(actual - expected) <= epsilon, string.format("%s: expected %.6f, got %.6f", message, expected, actual))
end

local function assertPoint(actual: Vector2, expected: Vector2, message: string)
	assertClose(actual.X, expected.X, 1e-6, message .. " X")
	assertClose(actual.Y, expected.Y, 1e-6, message .. " Y")
end

local function assertSamePoints(a: { Vector2 }, b: { Vector2 })
	assert(#a == #b, string.format("point counts differ: %d ~= %d", #a, #b))
	for index = 1, #a do
		assertPoint(a[index], b[index], string.format("point %d", index))
	end
end

function B04StrokeMathSpec.run()
	local config = PhysicsConfig.StrokeProcessing

	-- R16.3B: one semantic unit is half the DrawInputRect height on both axes.
	local normalized = StrokeMath.Normalize({
		Vector2.new(0, 0),
		Vector2.new(100, 50),
		Vector2.new(200, 100),
	}, Vector2.new(200, 100))
	assertSamePoints(normalized, {
		Vector2.new(-2, 1),
		Vector2.new(0, 0),
		Vector2.new(2, -1),
	})

	local anchored = StrokeMath.AnchorToFirstPoint({
		Vector2.new(-1.25, 0.4),
		Vector2.new(-0.25, 0.1),
		Vector2.new(0.50, -0.6),
	})
	assertSamePoints(anchored, {
		Vector2.new(0, 0),
		Vector2.new(1.0, -0.3),
		Vector2.new(1.75, -1.0),
	})

	-- RDP removes redundant collinear samples but preserves endpoints.
	local simplifiedLine = StrokeMath.SimplifyRDP({
		Vector2.new(-1, 0),
		Vector2.new(-0.5, 0),
		Vector2.new(0, 0),
		Vector2.new(0.5, 0),
		Vector2.new(1, 0),
	}, config.RDPEpsilon)
	assertSamePoints(simplifiedLine, {
		Vector2.new(-1, 0),
		Vector2.new(1, 0),
	})

	local usefulV = {
		Vector2.new(-0.8, -0.5),
		Vector2.new(0, 0.8),
		Vector2.new(0.8, -0.5),
	}
	local simplifiedV = StrokeMath.SimplifyRDP(usefulV, config.RDPEpsilon)
	assert(#simplifiedV == 3, "useful V shape collapsed below its meaningful corner")

	local resampled = StrokeMath.Resample({
		Vector2.new(-1, 0),
		Vector2.new(1, 0),
	}, 5)
	assertSamePoints(resampled, {
		Vector2.new(-1, 0),
		Vector2.new(-0.5, 0),
		Vector2.new(0, 0),
		Vector2.new(0.5, 0),
		Vector2.new(1, 0),
	})

	local repeatA = StrokeMath.Resample(StrokeMath.SimplifyRDP(usefulV, config.RDPEpsilon), config.ResampleTargetPoints)
	local repeatB = StrokeMath.Resample(StrokeMath.SimplifyRDP(usefulV, config.RDPEpsilon), config.ResampleTargetPoints)
	assertSamePoints(repeatA, repeatB)
	assert(#repeatA <= config.MaxCleanedPoints, "resample exceeded MaxCleanedPoints")
	assert(#repeatA >= 3, "useful shape collapsed below minimum useful point count")

	assertClose(StrokeMath.MeasureLength({ Vector2.new(0, 0), Vector2.new(0.3, 0.4) }), 0.5, 1e-6, "MeasureLength")

	print("[DrawRacers][B04] StrokeMath R16.3B normalize/origin tests PASS")
end

return B04StrokeMathSpec
