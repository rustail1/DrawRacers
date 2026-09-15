--!strict

local Workspace = game:GetService("Workspace")

local LegCoreConfig = require(script.Parent:WaitForChild("LegCoreConfig"))

local LegClearanceController = {}

local MAX_BINARY_STEPS = 14
local LIFT_EPSILON = 0.005

type ClearanceResult = {
	clear: boolean,
	requiredLift: number,
}

local function makeResult(requiredLift: number): ClearanceResult
	local boundedLift = math.clamp(requiredLift, 0, LegCoreConfig.Rebuild.MaxLift)
	return {
		clear = boundedLift <= 0,
		requiredLift = boundedLift,
	}
end

local function getCollisionSegments(leg: any, label: string): { BasePart }
	assert(leg ~= nil, label .. " leg is required")
	assert(type(leg.GetCollisionSegments) == "function", label .. " leg must expose GetCollisionSegments")

	local segments = leg:GetCollisionSegments()
	assert(type(segments) == "table", label .. " GetCollisionSegments must return a table")

	for _, segment in segments do
		assert(typeof(segment) == "Instance" and segment:IsA("BasePart"), label .. " physical segment must be BasePart")
	end

	return segments
end

local function makeTrackOverlapParams(trackRoot: Instance): OverlapParams
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { trackRoot }
	params.MaxParts = 1
	return params
end

local function segmentIntersectsTrack(segment: BasePart, lift: number, params: OverlapParams): boolean
	local padding = LegCoreConfig.Rebuild.ClearancePadding
	local paddedSize = segment.Size + Vector3.new(padding * 2, padding * 2, padding * 2)
	local prospectiveCFrame = segment.CFrame + Vector3.new(0, lift, 0)

	local overlaps = Workspace:GetPartBoundsInBox(prospectiveCFrame, paddedSize, params)
	return #overlaps > 0
end

local function pairIntersectsTrack(
	leftSegments: { BasePart },
	rightSegments: { BasePart },
	lift: number,
	params: OverlapParams
): boolean
	for _, segment in leftSegments do
		if segmentIntersectsTrack(segment, lift, params) then
			return true
		end
	end

	for _, segment in rightSegments do
		if segmentIntersectsTrack(segment, lift, params) then
			return true
		end
	end

	return false
end

function LegClearanceController.Evaluate(
	body: Part,
	leftLeg: any,
	rightLeg: any,
	trackRoot: Instance
): ClearanceResult
	assert(body ~= nil and body:IsA("Part"), "LegClearanceController requires BodyCollider Part")
	assert(trackRoot ~= nil and trackRoot:IsDescendantOf(game), "LegClearanceController requires live Track root")

	local leftSegments = getCollisionSegments(leftLeg, "Left")
	local rightSegments = getCollisionSegments(rightLeg, "Right")
	local params = makeTrackOverlapParams(trackRoot)

	if not pairIntersectsTrack(leftSegments, rightSegments, 0, params) then
		return makeResult(0)
	end

	local maxLift = LegCoreConfig.Rebuild.MaxLift
	assert(maxLift > 0, "Core V3 MaxLift must be positive")

	-- If even the configured maximum lift remains blocked, report the bounded
	-- maximum. The controller may retry after physically moving the body, but
	-- this evaluator never moves or mutates any Instance itself.
	if pairIntersectsTrack(leftSegments, rightSegments, maxLift, params) then
		return makeResult(maxLift)
	end

	-- Find the smallest +Y displacement that makes the entire prospective pair
	-- clear. Spatial queries use translated boxes only; the real Parts remain
	-- untouched throughout the calculation.
	local low = 0
	local high = maxLift

	for _ = 1, MAX_BINARY_STEPS do
		if high - low <= LIFT_EPSILON then
			break
		end

		local midpoint = (low + high) * 0.5
		if pairIntersectsTrack(leftSegments, rightSegments, midpoint, params) then
			low = midpoint
		else
			high = midpoint
		end
	end

	return makeResult(high)
end

return LegClearanceController
