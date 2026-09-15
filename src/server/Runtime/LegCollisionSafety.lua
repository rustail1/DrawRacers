--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)

local LegCollisionSafety = {}

local function tracksRoot(): Instance?
	local runtime = Workspace:FindFirstChild("Runtime")
	if runtime == nil then
		return nil
	end
	return runtime:FindFirstChild("Tracks")
end

local function shrunkenSize(size: Vector3): Vector3
	local settings = PhysicsConfig.ColliderActivation
	local inset = math.max(0, settings.ActivationProbeInset)
	local minimum = math.max(0.01, settings.MinimumProbeSize)

	return Vector3.new(
		math.max(size.X - inset * 2, minimum),
		math.max(size.Y - inset * 2, minimum),
		math.max(size.Z - inset * 2, minimum)
	)
end

function LegCollisionSafety.IsSegmentClearOfTrack(segment: BasePart): boolean
	assert(segment:IsA("BasePart"), "segment BasePart required")

	local tracks = tracksRoot()
	if tracks == nil or #tracks:GetChildren() == 0 then
		return true
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { tracks }
	params.MaxParts = PhysicsConfig.ColliderActivation.MaxProbeParts

	-- Query a slightly shrunken OBB. Shallow legal surface contact disappears
	-- from the probe; a segment born deeply inside Track still registers.
	for _, part in Workspace:GetPartBoundsInBox(
		segment.CFrame,
		shrunkenSize(segment.Size),
		params
	) do
		if part:IsA("BasePart") and part.CanCollide then
			return false
		end
	end

	return true
end

return LegCollisionSafety
