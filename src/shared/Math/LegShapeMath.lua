--!strict

local StrokeMath = require(script.Parent:WaitForChild("StrokeMath"))
local GeometryMath = require(script.Parent:WaitForChild("GeometryMath"))

local LegShapeMath = {}

export type CanonicalShape = {
	normalizedPoints: { Vector2 },
	presentationPoints: { Vector2 },
	mappedPoints: { Vector2 },
	bounds: any,
	extent: number,
	segmentPlan: { any },
	cleanedLength: number,
	presentationAnchor: Vector2,
	debugRawPointCount: number,
	debugPhysicsPointCount: number,
}

function LegShapeMath.BuildCanonical(
	rawPoints: { Vector2 },
	strokeConfig: any,
	geometryConfig: any
): (CanonicalShape?, string?)
	if #rawPoints < strokeConfig.MinimumRawPoints then
		return nil, "TOO_FEW_POINTS"
	end

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

	-- RCP-08 parity repair: GeometryMath may radially cap mapped points at
	-- MaxLegExtentFromHub. Project the authoritative mapped geometry back into
	-- semantic units so both live/accepted canvas paths use the exact centerline
	-- that the world leg uses instead of the pre-cap anchored stroke.
	assert(geometryConfig.LegCanvasHalfSpan > 0, "LegCanvasHalfSpan must be positive")
	local presentationPoints = table.create(#geometryPlan.mappedPoints)
	for index, mapped in geometryPlan.mappedPoints do
		presentationPoints[index] = mapped / geometryConfig.LegCanvasHalfSpan
	end

	local bounds = StrokeMath.ComputeBounds(presentationPoints)
	if bounds == nil then
		return nil, "TOO_SHORT"
	end

	return {
		normalizedPoints = presentationPoints,
		presentationPoints = presentationPoints,
		mappedPoints = geometryPlan.mappedPoints,
		bounds = bounds,
		extent = geometryPlan.extent,
		segmentPlan = geometryPlan.segmentPlan,
		cleanedLength = cleanedLength,
		presentationAnchor = presentationAnchor,
		debugRawPointCount = #rawPoints,
		debugPhysicsPointCount = #geometryPlan.mappedPoints,
	}, nil
end

return LegShapeMath