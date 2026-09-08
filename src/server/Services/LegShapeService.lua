--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("StrokeMath")
)

local LegShapeService = {}

local function reject(reasonCode: string)
	return {
		accepted = false,
		rejectReasonCode = reasonCode,
	}
end

local function validateRawPointArray(rawPoints: any): ({ Vector2 }?, string?)
	local config = PhysicsConfig.StrokeProcessing
	if type(rawPoints) ~= "table" then
		return nil, "MALFORMED_POINTS"
	end

	local entryCount = 0
	local maxIndex = 0
	for key, _ in rawPoints do
		if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
			return nil, "MALFORMED_POINTS"
		end

		entryCount += 1
		if entryCount > config.MaxRawPoints or key > config.MaxRawPoints then
			return nil, "TOO_MANY_POINTS"
		end
		maxIndex = math.max(maxIndex, key)
	end

	if entryCount < config.MinimumRawPoints then
		return nil, "TOO_FEW_POINTS"
	end
	if maxIndex ~= entryCount then
		return nil, "MALFORMED_POINTS"
	end

	local points = table.create(entryCount)
	for index = 1, entryCount do
		local point = rawPoints[index]
		if typeof(point) ~= "Vector2" then
			return nil, "MALFORMED_POINTS"
		end
		points[index] = point
	end

	return points, nil
end

local function mapPointToLegSpace(point: Vector2): Vector2
	local geometry = PhysicsConfig.LegGeometry
	local mapped = point * geometry.LegCanvasHalfSpan
	local magnitude = mapped.Magnitude
	if magnitude > geometry.MaxLegExtentFromHub and magnitude > 0 then
		mapped *= geometry.MaxLegExtentFromHub / magnitude
	end
	return mapped
end

local function buildSegmentPlan(normalizedPoints: { Vector2 })
	local geometry = PhysicsConfig.LegGeometry
	local mappedPoints = table.create(#normalizedPoints)
	local extent = 0

	for index, point in normalizedPoints do
		local mapped = mapPointToLegSpace(point)
		mappedPoints[index] = mapped
		extent = math.max(extent, mapped.Magnitude)
	end

	local segmentPlan = {}
	for index = 2, #mappedPoints do
		if #segmentPlan >= geometry.MaxColliderSegmentsPerLeg then
			break
		end

		local a = mappedPoints[index - 1]
		local b = mappedPoints[index]
		if (b - a).Magnitude >= geometry.MinimumMappedSegmentLength then
			table.insert(segmentPlan, {
				index = #segmentPlan + 1,
				a = a,
				b = b,
			})
		end
	end

	return segmentPlan, extent
end

local function buildDebugId(version: number, points: { Vector2 }, length: number): string
	local first = points[1]
	local last = points[#points]
	return string.format(
		"shape-v%d-p%d-l%.4f-f%.3f,%.3f-z%.3f,%.3f",
		version,
		#points,
		length,
		first.X,
		first.Y,
		last.X,
		last.Y
	)
end

function LegShapeService.ValidateAndBuild(racerRuntime: any, rawPoints: any, motorEnabled: boolean?)
	if racerRuntime == nil
		or type(racerRuntime.GetShapeVersion) ~= "function"
		or type(racerRuntime.ApplyValidatedShape) ~= "function"
	then
		return reject("INVALID_RACER")
	end

	local config = PhysicsConfig.StrokeProcessing
	local points, arrayError = validateRawPointArray(rawPoints)
	if points == nil then
		return reject(arrayError or "MALFORMED_POINTS")
	end

	local clamped, clampError = StrokeMath.Clamp(points, {
		minCoordinate = config.NormalizedMin,
		maxCoordinate = config.NormalizedMax,
		maxPoints = config.MaxRawPoints,
	})
	if clamped == nil then
		return reject(clampError or "INVALID_STROKE")
	end

	local deduped = StrokeMath.Dedupe(clamped, config.DedupeDistance)
	if #deduped < 2 then
		return reject("TOO_SHORT")
	end

	local simplified = StrokeMath.SimplifyRDP(deduped, config.RDPEpsilon)
	if #simplified < 2 then
		return reject("TOO_SHORT")
	end

	local resampleTarget = math.min(config.ResampleTargetPoints, config.MaxCleanedPoints)
	local cleaned = StrokeMath.Resample(simplified, resampleTarget)
	if #cleaned > config.MaxCleanedPoints then
		return reject("TOO_MANY_CLEANED_POINTS")
	end

	local cleanedLength = StrokeMath.MeasureLength(cleaned)
	if #cleaned < 2 or cleanedLength < config.MinimumCleanedPolylineLength then
		return reject("TOO_SHORT")
	end

	local bounds = StrokeMath.ComputeBounds(cleaned)
	if bounds == nil then
		return reject("TOO_SHORT")
	end

	local segmentPlan, extent = buildSegmentPlan(cleaned)
	if #segmentPlan == 0 then
		return reject("TOO_SHORT")
	end

	local nextVersion = racerRuntime:GetShapeVersion() + 1
	local shapeSpec = {
		version = nextVersion,
		normalizedPoints = cleaned,
		bounds = bounds,
		extent = extent,
		segmentPlan = segmentPlan,
		debugId = buildDebugId(nextVersion, cleaned, cleanedLength),
	}

	local applied, applyError = pcall(function()
		racerRuntime:ApplyValidatedShape(shapeSpec, motorEnabled)
	end)
	if not applied then
		warn(string.format("[DrawRacers][B11] validated shape build failed: %s", tostring(applyError)))
		return reject("BUILD_FAILED")
	end

	return {
		accepted = true,
		shapeVersion = nextVersion,
		shapeSpec = shapeSpec,
	}
end

return LegShapeService
