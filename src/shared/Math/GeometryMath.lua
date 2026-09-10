--!strict

local GeometryMath = {}

export type GeometryConfig = {
	LegCanvasHalfSpan: number,
	MaxLegExtentFromHub: number,
	MaxColliderSegmentsPerLeg: number,
	InnerHubNoCollisionRadius: number,
	MinimumMappedSegmentLength: number,
}

export type SegmentPlanEntry = {
	index: number,
	a: Vector2,
	b: Vector2,
	canCollide: boolean,
}

export type GeometryPlan = {
	mappedPoints: { Vector2 },
	segmentPlan: { SegmentPlanEntry },
	extent: number,
}

local function distanceFromOriginToSegment(a: Vector2, b: Vector2): number
	local ab = b - a
	local lengthSquared = ab:Dot(ab)
	if lengthSquared <= 0 then
		return a.Magnitude
	end

	local t = math.clamp((-a):Dot(ab) / lengthSquared, 0, 1)
	return (a + ab * t).Magnitude
end

function GeometryMath.MapPoint(point: Vector2, geometry: GeometryConfig): Vector2
	-- R16.3B: ShapeSpec points are already authoritative leg-local offsets.
	-- Do not component-clamp them back into the old square; retain direction and
	-- proportion and enforce only the existing physical radial hard cap.
	local mapped = point * geometry.LegCanvasHalfSpan
	local magnitude = mapped.Magnitude
	if magnitude > geometry.MaxLegExtentFromHub and magnitude > 0 then
		mapped *= geometry.MaxLegExtentFromHub / magnitude
	end
	return mapped
end

function GeometryMath.BuildSegmentPlan(normalizedPoints: { Vector2 }, geometry: GeometryConfig): GeometryPlan
	local mappedPoints = table.create(#normalizedPoints)
	local extent = 0
	for index, point in normalizedPoints do
		local mapped = GeometryMath.MapPoint(point, geometry)
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
				canCollide = distanceFromOriginToSegment(a, b) >= geometry.InnerHubNoCollisionRadius,
			})
		end
	end

	return {
		mappedPoints = mappedPoints,
		segmentPlan = segmentPlan,
		extent = extent,
	}
end

return GeometryMath
