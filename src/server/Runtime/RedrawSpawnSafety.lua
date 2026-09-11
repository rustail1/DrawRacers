--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RedrawSafetyMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("RedrawSafetyMath")
)

local RedrawSpawnSafety = {}

-- Nested shrunken boxes turn broad overlap into a bounded penetration proxy:
-- a shallow contact disappears at the first inset, while deeper overlap
-- survives progressively smaller query boxes and therefore receives more
-- weight. This is selection evidence only; it never moves the racer body.
local SHRINK_INSETS = { 0.04, 0.10, 0.16 }
local SHRINK_WEIGHTS = { 1, 4, 16 }
local MIN_QUERY_SIZE = 0.04

local function axleBaseCFrame(body: BasePart): CFrame
	local geometry = PhysicsConfig.LegGeometry
	return body.CFrame * CFrame.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)
end

local function shrunkenSize(size: Vector3, inset: number): Vector3
	return Vector3.new(
		math.max(size.X - inset * 2, MIN_QUERY_SIZE),
		math.max(size.Y - inset * 2, MIN_QUERY_SIZE),
		math.max(size.Z - inset * 2, MIN_QUERY_SIZE)
	)
end

local function hasCollidableTrackOverlap(cframe: CFrame, size: Vector3, overlapParams: OverlapParams): boolean
	for _, part in Workspace:GetPartBoundsInBox(cframe, size, overlapParams) do
		if part:IsA("BasePart") and part.CanCollide then
			return true
		end
	end
	return false
end

local function scoreSegment(cframe: CFrame, size: Vector3, overlapParams: OverlapParams): number
	local score = 0
	for index, inset in SHRINK_INSETS do
		if hasCollidableTrackOverlap(cframe, shrunkenSize(size, inset), overlapParams) then
			score += SHRINK_WEIGHTS[index]
		end
	end
	return score
end

local function scoreCandidate(stagedPair: any, body: BasePart, phaseDegrees: number, overlapParams: OverlapParams): number
	local stagedAxleCFrame = stagedPair:GetRoot().CFrame
	local candidateAxleCFrame = axleBaseCFrame(body) * CFrame.Angles(0, 0, math.rad(phaseDegrees))
	local score = 0

	for _, leg in { stagedPair:GetLeftLeg(), stagedPair:GetRightLeg() } do
		for _, segment in leg:GetSegments() do
			if segment.CanCollide then
				local localToAxle = stagedAxleCFrame:ToObjectSpace(segment.CFrame)
				local candidateCFrame = candidateAxleCFrame * localToAxle
				score += scoreSegment(candidateCFrame, segment.Size, overlapParams)
			end
		end
	end

	return score
end

function RedrawSpawnSafety.ChoosePhase(
	racerModel: Model,
	stagedPair: any,
	currentPhaseDegrees: number
): (number, boolean, number)
	local body = racerModel:FindFirstChild("BodyCollider")
	assert(body and body:IsA("BasePart"), "redraw safety requires BodyCollider")

	local runtime = Workspace:FindFirstChild("Runtime")
	local tracksRoot = runtime and runtime:FindFirstChild("Tracks")
	if tracksRoot == nil or #tracksRoot:GetChildren() == 0 then
		return currentPhaseDegrees, false, 0
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { tracksRoot }
	overlapParams.MaxParts = 64

	local candidatePhases = RedrawSafetyMath.BuildCandidatePhases(currentPhaseDegrees)
	local penetrationScores = table.create(#candidatePhases)
	for index, candidatePhase in candidatePhases do
		penetrationScores[index] = scoreCandidate(stagedPair, body, candidatePhase, overlapParams)
	end

	local selectedPhase, selectedScore, fallback = RedrawSafetyMath.ChooseBestCandidate(
		currentPhaseDegrees,
		candidatePhases,
		penetrationScores
	)
	return selectedPhase, fallback, selectedScore
end

return RedrawSpawnSafety
