--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StrokeMath = require(script.Parent:WaitForChild("StrokeMath"))
local GeometryMath = require(script.Parent:WaitForChild("GeometryMath"))
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)

local CanonicalLegShape = {}

type ShapeBounds = StrokeTypes.ShapeBounds
type ShapeSegmentPlanEntry = StrokeTypes.ShapeSegmentPlanEntry

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

function CanonicalLegShape.Build(rawPoints: { Vector2 }, strokeConfig: any, geometryConfig: any): (CanonicalShape?, string?)
	if type(rawPoints) ~= "table" then
		return nil, "MALFORMED_POINTS"
	end
	if #rawPoints < strokeConfig.MinimumRawPoints then
		return nil, "TOO_FEW_POINTS"
	end
	if geometryConfig.LegCanvasHalfSpan <= 0 then
		return nil, "INVALID_GEOMETRY_CONFIG"
	end

	-- This is the only canonical pipeline. Keep the order explicit because both
	-- client prediction and server authority consume this exact function.
	local cleaned, clampError = StrokeMath.ClampToRect(
		rawPoints,
		-strokeConfig.RawSemanticHalfWidth,
		strokeConfig.RawSemanticHalfWidth,
		-strokeConfig.RawSemanticHalfHeight,
		strokeConfig.RawSemanticHalfHeight,
		strokeConfig.MaxRawPoints
	)
	if cleaned == nil then
		return nil, clampError or "INVALID_STROKE"
	end

	cleaned = StrokeMath.Dedupe(cleaned, strokeConfig.DedupeDistance)
	if #cleaned < 2 then
		return nil, "TOO_FEW_POINTS"
	end

	cleaned = StrokeMath.SimplifyRDP(cleaned, strokeConfig.RDPEpsilon)
	if #cleaned < 2 then
		return nil, "TOO_FEW_POINTS"
	end

	cleaned = StrokeMath.Resample(cleaned, strokeConfig.ResampleTargetPoints)
	if #cleaned > strokeConfig.MaxCleanedPoints then
		return nil, "TOO_MANY_POINTS"
	end

	local cleanedLength = StrokeMath.MeasureLength(cleaned)
	if cleanedLength < strokeConfig.MinimumCleanedPolylineLength then
		return nil, "TOO_SHORT"
	end

	local presentationAnchor = cleaned[1]
	local anchored = StrokeMath.AnchorToFirstPoint(cleaned)
	local geometryPlan = GeometryMath.BuildSegmentPlan(anchored, geometryConfig)
	if #geometryPlan.segmentPlan == 0 then
		return nil, "NO_LEGAL_SEGMENTS"
	end
	if #geometryPlan.segmentPlan > geometryConfig.MaxColliderSegmentsPerLeg then
		return nil, "TOO_MANY_SEGMENTS"
	end
	if geometryPlan.extent < geometryConfig.MinUsefulLegExtent then
		return nil, "TOO_SMALL"
	end

	-- GeometryMath may radially cap mapped points. Convert those accepted world
	-- points back into semantic units so preview, StrokeResult and colliders all
	-- describe the same centerline.
	local normalizedPoints = table.create(#geometryPlan.mappedPoints)
	for index, mapped in geometryPlan.mappedPoints do
		normalizedPoints[index] = mapped / geometryConfig.LegCanvasHalfSpan
	end
	local bounds = StrokeMath.ComputeBounds(normalizedPoints)
	if bounds == nil then
		return nil, "INVALID_BOUNDS"
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
