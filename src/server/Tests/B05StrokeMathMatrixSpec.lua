--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StrokeMath = require(Shared:WaitForChild("Math"):WaitForChild("StrokeMath"))
local PhysicsConfig = require(Shared:WaitForChild("Config"):WaitForChild("PhysicsConfig"))

local B05StrokeMathMatrixSpec = {}

local function assertClose(actual: number, expected: number, epsilon: number, message: string)
	assert(math.abs(actual - expected) <= epsilon, string.format("%s: expected %.6f, got %.6f", message, expected, actual))
end

local function assertSamePoints(a: { Vector2 }, b: { Vector2 }, message: string)
	assert(#a == #b, string.format("%s: point counts differ %d ~= %d", message, #a, #b))
	for index = 1, #a do
		assertClose(a[index].X, b[index].X, 1e-6, string.format("%s point %d X", message, index))
		assertClose(a[index].Y, b[index].Y, 1e-6, string.format("%s point %d Y", message, index))
	end
end

local function processNormalized(points: { Vector2 })
	local config = PhysicsConfig.StrokeProcessing
	local clamped, clampError = StrokeMath.Clamp(points, {
		minCoordinate = config.NormalizedMin,
		maxCoordinate = config.NormalizedMax,
		maxPoints = config.MaxRawPoints,
	})
	if clamped == nil then
		return nil, clampError
	end

	local deduped = StrokeMath.Dedupe(clamped, config.DedupeDistance)
	local simplified = StrokeMath.SimplifyRDP(deduped, config.RDPEpsilon)
	local targetPoints = math.min(config.ResampleTargetPoints, config.MaxCleanedPoints)
	local resampled = StrokeMath.Resample(simplified, targetPoints)
	local length = StrokeMath.MeasureLength(resampled)

	return {
		points = resampled,
		length = length,
		dedupedCount = #deduped,
		simplifiedCount = #simplified,
	}, nil
end

local PRESETS = {
	ROUND_01 = {
		Vector2.new(0.72, 0), Vector2.new(0.624, 0.36), Vector2.new(0.36, 0.624), Vector2.new(0, 0.72),
		Vector2.new(-0.36, 0.624), Vector2.new(-0.624, 0.36), Vector2.new(-0.72, 0), Vector2.new(-0.624, -0.36),
		Vector2.new(-0.36, -0.624), Vector2.new(0, -0.72), Vector2.new(0.36, -0.624), Vector2.new(0.624, -0.36),
	},
	LONG_BAR_01 = {
		Vector2.new(-0.92, 0), Vector2.new(-0.46, 0), Vector2.new(0, 0), Vector2.new(0.46, 0), Vector2.new(0.92, 0),
	},
	SMALL_ROUND_01 = {
		Vector2.new(0.40, 0), Vector2.new(0.3467, 0.20), Vector2.new(0.20, 0.3467), Vector2.new(0, 0.40),
		Vector2.new(-0.20, 0.3467), Vector2.new(-0.3467, 0.20), Vector2.new(-0.40, 0), Vector2.new(-0.3467, -0.20),
		Vector2.new(-0.20, -0.3467), Vector2.new(0, -0.40), Vector2.new(0.20, -0.3467), Vector2.new(0.3467, -0.20),
	},
	HOOK_01 = {
		Vector2.new(-0.20, -0.20), Vector2.new(0.10, -0.10), Vector2.new(0.45, 0.05), Vector2.new(0.72, 0.34),
		Vector2.new(0.70, 0.70), Vector2.new(0.38, 0.88), Vector2.new(0.12, 0.72),
	},
	ASYM_01 = {
		Vector2.new(-0.82, -0.18), Vector2.new(-0.30, -0.52), Vector2.new(0.18, -0.26), Vector2.new(0.76, 0.08),
		Vector2.new(0.34, 0.58), Vector2.new(-0.18, 0.82), Vector2.new(-0.52, 0.30),
	},
	SUBOPTIMAL_01 = {
		Vector2.new(-0.42, -0.25), Vector2.new(-0.15, -0.05), Vector2.new(0.08, 0.22), Vector2.new(0.36, 0.42),
	},
}

function B05StrokeMathMatrixSpec.run()
	local config = PhysicsConfig.StrokeProcessing

	-- Canonical preset matrix from spec 73: every legal preset must stay finite,
	-- deterministic, open and bounded after the B03/B04 pipeline.
	for presetId, preset in PRESETS do
		local first, firstError = processNormalized(preset)
		assert(first ~= nil and firstError == nil, string.format("%s unexpectedly rejected: %s", presetId, tostring(firstError)))
		assert(#first.points <= config.MaxCleanedPoints, presetId .. " exceeded MaxCleanedPoints")
		assert(first.length >= config.MinimumCleanedPolylineLength, presetId .. " collapsed below minimum useful length")

		local second, secondError = processNormalized(preset)
		assert(second ~= nil and secondError == nil, string.format("%s repeat unexpectedly rejected", presetId))
		assertSamePoints(first.points, second.points, presetId .. " deterministic repeat")
	end

	-- tiny stroke: cleanup may resample it, but length must remain tiny so the
	-- later acceptance validator can reject it without inventing useful size.
	local tinyStroke = {
		Vector2.new(0, 0),
		Vector2.new(0.01, 0),
		Vector2.new(0.02, 0),
	}
	local tiny, tinyError = processNormalized(tinyStroke)
	assert(tiny ~= nil and tinyError == nil, "tiny stroke math should remain safe to inspect")
	assert(tiny.length < config.MinimumCleanedPolylineLength, "tiny stroke was inflated into a valid-length shape")

	-- duplicate-heavy input: near/exact duplicates collapse deterministically and
	-- cannot create unbounded cleaned geometry.
	local duplicateHeavy = {
		Vector2.new(-0.6, 0), Vector2.new(-0.6, 0), Vector2.new(-0.596, 0.002),
		Vector2.new(-0.2, 0), Vector2.new(-0.2, 0), Vector2.new(0.2, 0),
		Vector2.new(0.2, 0), Vector2.new(0.6, 0), Vector2.new(0.6, 0),
	}
	local duplicateResult, duplicateError = processNormalized(duplicateHeavy)
	assert(duplicateResult ~= nil and duplicateError == nil, "duplicate-heavy input was rejected")
	assert(duplicateResult.dedupedCount < #duplicateHeavy, "duplicate-heavy input was not deduped")
	assert(#duplicateResult.points <= config.MaxCleanedPoints, "duplicate-heavy input exceeded cleaned cap")

	-- self-cross remains legal: the pipeline preserves an open crossing polyline
	-- and does not crash, close the stroke or create unbounded complexity.
	local selfCross = {
		Vector2.new(-0.75, -0.75),
		Vector2.new(0.75, 0.75),
		Vector2.new(-0.75, 0.75),
		Vector2.new(0.75, -0.75),
	}
	local crossed, crossedError = processNormalized(selfCross)
	assert(crossed ~= nil and crossedError == nil, "self-cross input was rejected")
	assert(crossed.length >= config.MinimumCleanedPolylineLength, "self-cross collapsed below useful length")
	assert(#crossed.points <= config.MaxCleanedPoints, "self-cross exceeded cleaned cap")
	assert((crossed.points[1] - crossed.points[#crossed.points]).Magnitude > 0.01, "self-cross was silently closed")

	-- MaxRawPoints boundary: exact cap accepted, cap+1 rejected.
	local atMax = table.create(config.MaxRawPoints)
	for index = 1, config.MaxRawPoints do
		local alpha = (index - 1) / (config.MaxRawPoints - 1)
		atMax[index] = Vector2.new(-1 + alpha * 2, 0)
	end
	local maxAccepted, maxAcceptedError = processNormalized(atMax)
	assert(maxAccepted ~= nil and maxAcceptedError == nil, "MaxRawPoints exact boundary should be accepted")

	local overMax = table.create(config.MaxRawPoints + 1)
	for index = 1, config.MaxRawPoints + 1 do
		overMax[index] = Vector2.new(0, 0)
	end
	local _, overMaxError = processNormalized(overMax)
	assert(overMaxError == "TOO_MANY_POINTS", "MaxRawPoints+1 must fail with TOO_MANY_POINTS")

	-- malformed/non-finite cases fail closed in Clamp before any later math.
	local nanValue = math.huge - math.huge
	for _, malformed in {
		Vector2.new(nanValue, 0),
		Vector2.new(math.huge, 0),
		Vector2.new(-math.huge, 0),
	} do
		local _, malformedError = StrokeMath.Clamp({ malformed }, {
			minCoordinate = config.NormalizedMin,
			maxCoordinate = config.NormalizedMax,
			maxPoints = config.MaxRawPoints,
		})
		assert(malformedError == "NON_FINITE_POINT", "malformed point must fail with NON_FINITE_POINT")
	end

	print("[DrawRacers][B05] canonical/tiny/duplicate/self-cross/max-point/malformed StrokeMath matrix PASS")
end

return B05StrokeMathMatrixSpec
