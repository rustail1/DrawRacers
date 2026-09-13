--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)

local LegCollisionSafety = {}

local function rotatePoint(point: Vector2, degrees: number): Vector2
	if math.abs(degrees) <= 1e-6 then return point end
	local angle = math.rad(degrees)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return Vector2.new(point.X * c - point.Y * s, point.X * s + point.Y * c)
end

local function segmentCFrame(rootCFrame: CFrame, a: Vector2, b: Vector2): CFrame
	local delta = b - a
	local direction = delta.Unit
	local xAxis = Vector3.new(direction.X, direction.Y, 0)
	local zAxis = Vector3.zAxis
	local yAxis = zAxis:Cross(xAxis)
	local midpoint = (a + b) * 0.5
	return rootCFrame * CFrame.fromMatrix(Vector3.new(midpoint.X, midpoint.Y, 0), xAxis, yAxis, zAxis)
end

local function tracksFolder(): Instance?
	local runtime = Workspace:FindFirstChild("Runtime")
	if runtime == nil then return nil end
	return runtime:FindFirstChild("Tracks")
end

local function makeOverlapParams(tracks: Instance): OverlapParams
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { tracks }
	params.RespectCanCollide = true
	return params
end

local function candidateOffsets(count: number, stepDegrees: number): { number }
	local result = table.create(count)
	table.insert(result, 0)
	local magnitude = 1
	while #result < count do
		table.insert(result, magnitude * stepDegrees)
		if #result >= count then break end
		table.insert(result, -magnitude * stepDegrees)
		magnitude += 1
	end
	return result
end

local function scoreRoot(shapeSpec: any, rootCFrame: CFrame, offsetDegrees: number, overlap: OverlapParams): number
	local geometry = PhysicsConfig.LegGeometry
	local inset = math.clamp(PhysicsConfig.RedrawSafety.OverlapProbeInset, 0, geometry.PhysicalLegSegmentThickness * 0.45)
	local shortAxis = math.max(0.05, geometry.PhysicalLegSegmentThickness - inset * 2)
	local score = 0
	for _, planned in shapeSpec.segmentPlan do
		if planned.canCollide == true then
			local a = rotatePoint(planned.a, offsetDegrees)
			local b = rotatePoint(planned.b, offsetDegrees)
			local length = math.max(0.05, (b - a).Magnitude + geometry.SegmentOverlapAllowance - inset * 2)
			local frame = segmentCFrame(rootCFrame, a, b)
			local hits = Workspace:GetPartBoundsInBox(frame, Vector3.new(length, shortAxis, shortAxis), overlap)
			score += #hits
		end
	end
	return score
end

function LegCollisionSafety.ScoreMountOffset(
	shapeSpec: any,
	leftRoot: Part,
	rightRoot: Part,
	offsetDegrees: number
): number
	local tracks = tracksFolder()
	if tracks == nil then
		return 0
	end
	local overlap = makeOverlapParams(tracks)
	return scoreRoot(shapeSpec, leftRoot.CFrame, offsetDegrees, overlap)
		+ scoreRoot(shapeSpec, rightRoot.CFrame, offsetDegrees, overlap)
end

function LegCollisionSafety.FindSafeMountOffset(shapeSpec: any, leftRoot: Part, rightRoot: Part): (number?, string?)
	assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table", "shapeSpec required")
	local safety = PhysicsConfig.RedrawSafety
	for _, offset in candidateOffsets(safety.CandidateCount, safety.CandidateStepDegrees) do
		if LegCollisionSafety.ScoreMountOffset(shapeSpec, leftRoot, rightRoot, offset) == 0 then
			return offset, nil
		end
	end
	return nil, "NO_SAFE_REDRAW_PHASE"
end

return LegCollisionSafety
