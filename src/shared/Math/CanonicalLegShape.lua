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
	presentationAnchor: Vector2,
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

	-- Single canonical pipeline shared by prediction and server authority:
	-- raw -> clamp -> dedupe -> simplify -> resample -> first-point anchor
	-- -> world mapping -> segment plan.
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

	local deduped = StrokeMath.Dedupe(clamped, strokeConfig.DedupeDistance)
	if #deduped < 2 then
		return nil, "TOO_SHORT"
	end

	local simplified = StrokeMath.SimplifyRDP(deduped, strokeConfig.RDPEpsilon)
	if #simplified < 2 then
		return nil, "TOO_SHORT"
	end

	local cleaned = StrokeMath.Resample(
		simplified,
		math.min(strokeConfig.ResampleTargetPoints, strokeConfig.MaxCleanedPoints)
	)
	if #cleaned > strokeConfig.MaxCleanedPoints then
		return nil, "TOO_MANY_CLEANED_POINTS"
	end

	local cleanedLength = StrokeMath.MeasureLength(cleaned)
	if #cleaned < 2 or cleanedLength < strokeConfig.MinimumCleanedPolylineLength then
		return nil, "TOO_SHORT"
	end

	local presentationAnchor = cleaned[1]
	local anchored = StrokeMath.AnchorToFirstPoint(cleaned)
	local geometryPlan = GeometryMath.BuildSegmentPlan(anchored, geometryConfig)
	if #geometryPlan.segmentPlan == 0 then
		return nil, "TOO_SHORT"
	end
	if geometryPlan.extent < geometryConfig.MinUsefulLegExtent then
		return nil, "TOO_SHORT"
	end

	-- GeometryMath can radially cap world points at MaxLegExtentFromHub. Project
	-- accepted mapped geometry back into semantic units so preview, StrokeResult,
	-- and world colliders all describe the exact same canonical centerline.
	assert(geometryConfig.LegCanvasHalfSpan > 0, "LegCanvasHalfSpan must be positive")
	local normalizedPoints = table.create(#geometryPlan.mappedPoints)
	for index, mapped in geometryPlan.mappedPoints do
		normalizedPoints[index] = mapped / geometryConfig.LegCanvasHalfSpan
	end

	local bounds = StrokeMath.ComputeBounds(normalizedPoints)
	if bounds == nil then
		return nil, "TOO_SHORT"
	end

	local mappedPoints = geometryPlan.mappedPoints
	local segmentPlan = geometryPlan.segmentPlan
	return table.freeze({
		normalizedPoints = freezePoints(normalizedPoints),
		mappedPoints = freezePoints(mappedPoints),
		bounds = table.freeze(bounds),
		extent = geometryPlan.extent,
		segmentPlan = freezeSegmentPlan(segmentPlan),
		cleanedLength = cleanedLength,
		presentationAnchor = presentationAnchor,
		debugRawPointCount = #rawPoints,
		debugPhysicsPointCount = #mappedPoints,
	}), nil
end

return CanonicalLegShape
