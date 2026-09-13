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

local EPSILON = 1e-6

local function selectSupportAnchor(cleaned: { Vector2 }): Vector2
	assert(#cleaned > 0, "selectSupportAnchor requires points")
	local bounds = StrokeMath.ComputeBounds(cleaned)
	assert(bounds ~= nil, "support anchor requires finite bounds")
	local boundsCenterX = (bounds.min.X + bounds.max.X) * 0.5

	local leftCandidate = cleaned[1]
	local topCandidate = cleaned[1]
	local rightCandidate = cleaned[1]
	local topDistanceFromCenter = math.abs(topCandidate.X - boundsCenterX)

	for index = 2, #cleaned do
		local point = cleaned[index]

		if point.X < leftCandidate.X - EPSILON
			or (math.abs(point.X - leftCandidate.X) <= EPSILON and point.Y > leftCandidate.Y + EPSILON)
		then
			leftCandidate = point
		end

		local distanceFromCenter = math.abs(point.X - boundsCenterX)
		if point.Y > topCandidate.Y + EPSILON
			or (
				math.abs(point.Y - topCandidate.Y) <= EPSILON
				and distanceFromCenter < topDistanceFromCenter - EPSILON
			)
		then
			topCandidate = point
			topDistanceFromCenter = distanceFromCenter
		end

		if point.X > rightCandidate.X + EPSILON
			or (math.abs(point.X - rightCandidate.X) <= EPSILON and point.Y > rightCandidate.Y + EPSILON)
		then
			rightCandidate = point
		end
	end

	local firstCleaned = cleaned[1]
	local supportAnchor = leftCandidate
	local bestDistance = (firstCleaned - leftCandidate).Magnitude
	local topDistance = (firstCleaned - topCandidate).Magnitude
	if topDistance < bestDistance - EPSILON then
		supportAnchor = topCandidate
		bestDistance = topDistance
	end
	local rightDistance = (firstCleaned - rightCandidate).Magnitude
	if rightDistance < bestDistance - EPSILON then
		supportAnchor = rightCandidate
	end
	return supportAnchor
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

	-- CR3 canonical pipeline:
	-- raw -> clamp -> dedupe -> simplify -> resample -> choose one support point
	-- from LEFT/TOP/RIGHT geometry -> translation only -> world mapping -> segment plan.
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
	if #cleaned < 2 then
		return nil, "TOO_SHORT"
	end

	local cleanedLength = StrokeMath.MeasureLength(cleaned)
	if cleanedLength < strokeConfig.MinimumCleanedPolylineLength then
		return nil, "TOO_SHORT"
	end

	local supportAnchor = selectSupportAnchor(cleaned)
	local anchored = table.create(#cleaned)
	for index, point in cleaned do
		anchored[index] = point - supportAnchor
	end

	local geometryPlan = GeometryMath.BuildSegmentPlan(anchored, geometryConfig)
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
		presentationAnchor = supportAnchor,
		debugRawPointCount = #rawPoints,
		debugPhysicsPointCount = #geometryPlan.mappedPoints,
	}), nil
end

return CanonicalLegShape