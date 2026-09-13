--!strict

local StrokeMath = require(script.Parent:WaitForChild("StrokeMath"))
local GeometryMath = require(script.Parent:WaitForChild("GeometryMath"))

local CanonicalLegShape = {}

export type ShapeBounds = {
	min: Vector2,
	max: Vector2,
}

export type ShapeSegmentPlanEntry = {
	index: number,
	a: Vector2,
	b: Vector2,
	canCollide: boolean,
}

export type CanonicalShape = {
	normalizedPoints: { Vector2 },
	mappedPoints: { Vector2 },
	bounds: ShapeBounds,
	extent: number,
	segmentPlan: { ShapeSegmentPlanEntry },
	cleanedLength: number,
	debugRawPointCount: number,
	debugPhysicsPointCount: number,
}

local function freezePoints(points: { Vector2 }): { Vector2 }
	return table.freeze(points)
end

local function freezeSegmentPlan(segmentPlan: { ShapeSegmentPlanEntry }): { ShapeSegmentPlanEntry }
	for _, segment in segmentPlan do
		table.freeze(segment)
	end
	return table.freeze(segmentPlan)
end

local function copyPoints(points: { Vector2 }): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = point
	end
	return result
end

function CanonicalLegShape.Build(
	rawPoints: { Vector2 },
	strokeConfig: any,
	geometryConfig: any
): (CanonicalShape?, string?)
	if type(rawPoints) ~= "table" then
		return nil, "MALFORMED_POINTS"
	end
	if #rawPoints < strokeConfig.MinimumRawPoints then
		return nil, "TOO_FEW_POINTS"
	end

	-- CORE REPAIR v2 canonical pipeline:
	-- raw -> clamp -> fixed-pivot start validation -> snap first sample only
	-- -> dedupe -> simplify -> resample -> world mapping -> segment plan.
	-- The full stroke is never translated to hide an arbitrary first point.
	local clamped, clampError = StrokeMath.ClampToRect(rawPoints, {
		minX = -strokeConfig.RawSemanticHalfWidth,
		maxX = strokeConfig.RawSemanticHalfWidth,
		minY = -strokeConfig.RawSemanticHalfHeight,
		maxY = strokeConfig.RawSemanticHalfHeight,
		maxPoints = strokeConfig.MaxRawPoints,
	})
	if clamped == nil then
		return nil, clampError or "INVALID_STROKE"
	end

	local pivotRadius = strokeConfig.PivotStartRadiusNormalized or 0
	if #clamped == 0 or clamped[1].Magnitude > pivotRadius then
		return nil, "START_OFF_PIVOT"
	end

	local pivotSnapped = copyPoints(clamped)
	pivotSnapped[1] = Vector2.zero

	local deduped = StrokeMath.Dedupe(pivotSnapped, strokeConfig.DedupeDistance)
	if #deduped < 2 then
		return nil, "TOO_SHORT"
	end
	-- Cleanup must preserve the explicit mechanical origin.
	deduped[1] = Vector2.zero

	local simplified = StrokeMath.SimplifyRDP(deduped, strokeConfig.RDPEpsilon)
	if #simplified < 2 then
		return nil, "TOO_SHORT"
	end
	simplified[1] = Vector2.zero

	local cleaned = StrokeMath.Resample(
		simplified,
		math.min(strokeConfig.ResampleTargetPoints, strokeConfig.MaxCleanedPoints)
	)
	if #cleaned > strokeConfig.MaxCleanedPoints then
		return nil, "TOO_MANY_CLEANED_POINTS"
	end
	if #cleaned < 2 then
		return nil, "TOO_SHORT"
	end
	cleaned[1] = Vector2.zero

	local cleanedLength = StrokeMath.MeasureLength(cleaned)
	if cleanedLength < strokeConfig.MinimumCleanedPolylineLength then
		return nil, "TOO_SHORT"
	end

	local geometryPlan = GeometryMath.BuildSegmentPlan(cleaned, geometryConfig)
	if #geometryPlan.segmentPlan == 0 then
		return nil, "TOO_SHORT"
	end
	if geometryPlan.extent < geometryConfig.MinUsefulLegExtent then
		return nil, "TOO_SHORT"
	end

	assert(geometryConfig.LegCanvasHalfSpan > 0, "LegCanvasHalfSpan must be positive")
	local normalizedPoints = table.create(#geometryPlan.mappedPoints)
	for index, mapped in geometryPlan.mappedPoints do
		normalizedPoints[index] = mapped / geometryConfig.LegCanvasHalfSpan
	end
	-- Geometry radial-clamping preserves the origin, but assert it explicitly as part
	-- of the fixed-pivot public contract.
	if #normalizedPoints > 0 then
		normalizedPoints[1] = Vector2.zero
	end

	local bounds = StrokeMath.ComputeBounds(normalizedPoints)
	if bounds == nil then
		return nil, "TOO_SHORT"
	end

	return table.freeze({
		normalizedPoints = freezePoints(normalizedPoints),
		mappedPoints = freezePoints(geometryPlan.mappedPoints),
		bounds = table.freeze(bounds),
		extent = geometryPlan.extent,
		segmentPlan = freezeSegmentPlan(geometryPlan.segmentPlan),
		cleanedLength = cleanedLength,
		debugRawPointCount = #rawPoints,
		debugPhysicsPointCount = #geometryPlan.mappedPoints,
	}), nil
end

return CanonicalLegShape
