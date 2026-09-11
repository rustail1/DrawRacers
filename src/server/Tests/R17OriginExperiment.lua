--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StrokeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("StrokeMath")
)
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local R17OriginExperiment = {}

local POLICIES = {
	"FIRST_POINT",
	"BOUNDS_CENTER",
	"GEOMETRY_CENTROID",
}

local SHAPES = {
	"ROUND_01",
	"LONG_BAR_01",
	"SMALL_ROUND_01",
	"HOOK_01",
	"ASYM_01",
	"SUBOPTIMAL_01",
}

local function copyPoints(points: { Vector2 }): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = point
	end
	return result
end

local function translate(points: { Vector2 }, origin: Vector2): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = point - origin
	end
	return result
end

local function boundsCenter(points: { Vector2 }): Vector2
	local minPoint, maxPoint = StrokeMath.ComputeBounds(points)
	return (minPoint + maxPoint) * 0.5
end

-- Deterministic polyline centroid weighted by segment length. This is an evidence
-- candidate only; it does not change the production first-point ShapeSpec path.
local function geometryCentroid(points: { Vector2 }): Vector2
	if #points == 0 then
		return Vector2.zero
	end
	if #points == 1 then
		return points[1]
	end

	local weighted = Vector2.zero
	local totalLength = 0
	for index = 1, #points - 1 do
		local a = points[index]
		local b = points[index + 1]
		local length = (b - a).Magnitude
		if length > 0 then
			weighted += ((a + b) * 0.5) * length
			totalLength += length
		end
	end
	if totalLength <= 0 then
		return points[1]
	end
	return weighted / totalLength
end

local function candidatePoints(policy: string, points: { Vector2 }): { Vector2 }
	if policy == "FIRST_POINT" then
		return StrokeMath.AnchorToFirstPoint(copyPoints(points))
	elseif policy == "BOUNDS_CENTER" then
		return translate(points, boundsCenter(points))
	elseif policy == "GEOMETRY_CENTROID" then
		return translate(points, geometryCentroid(points))
	end
	error(string.format("unknown R17 origin policy %s", policy))
end

local function summarize(points: { Vector2 }): (number, number, number, number, number)
	local minPoint, maxPoint = StrokeMath.ComputeBounds(points)
	local maxRadius = 0
	for _, point in points do
		maxRadius = math.max(maxRadius, point.Magnitude)
	end
	return minPoint.X, maxPoint.X, minPoint.Y, maxPoint.Y, maxRadius
end

function R17OriginExperiment.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R17OriginExperiment is Studio-only")
	print("[DrawRacers][R17.3] mechanical-origin comparison starting")

	for _, shapeId in SHAPES do
		local source = R16ReferenceShapes.Get(shapeId)
		for _, policy in POLICIES do
			local candidate = candidatePoints(policy, source)
			assert(#candidate == #source, "origin experiment must preserve point count")
			local minX, maxX, minY, maxY, maxRadius = summarize(candidate)
			print(string.format(
				"[DrawRacers][R17.3] shape=%s policy=%s x=%.3f..%.3f y=%.3f..%.3f radius=%.3f",
				shapeId,
				policy,
				minX,
				maxX,
				minY,
				maxY,
				maxRadius
			))
		end
	end

	print("[DrawRacers][R17.3] HUMAN ORIGIN CHOICE PENDING")
	return true
end

return R17OriginExperiment
