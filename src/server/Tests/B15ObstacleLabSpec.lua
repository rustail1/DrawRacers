--!strict

local B15ObstacleLabSpec = {}

local EPSILON = 1e-4

local function approx(actual: number, expected: number, label: string)
	assert(math.abs(actual - expected) <= EPSILON, string.format("%s expected %.4f, got %.4f", label, expected, actual))
end

local function requirePart(parent: Instance, name: string): Part
	local child = parent:FindFirstChild(name)
	assert(child and child:IsA("Part"), string.format("B15 missing Part %s", name))
	assert(child.Anchored == true, string.format("%s must be anchored", name))
	assert(child.CanCollide == true, string.format("%s must collide", name))
	return child
end

local function assertPartX(parent: Instance, name: string, x0: number, x1: number, topY: number)
	local part = requirePart(parent, name)
	approx(part.Position.X, (x0 + x1) / 2, name .. ".Position.X")
	approx(part.Size.X, x1 - x0, name .. ".Size.X")
	approx(part.Position.Y + part.Size.Y / 2, topY, name .. ".TopY")
	approx(part.Size.Z, 8, name .. ".Size.Z")
end

function B15ObstacleLabSpec.run()
	local runtime = workspace:WaitForChild("Runtime")
	local tracks = runtime:WaitForChild("Tracks")
	local scene = tracks:FindFirstChild("M0TestScene")
	assert(scene and scene:IsA("Folder"), "B15 requires Runtime.Tracks.M0TestScene")
	local lab = scene:FindFirstChild("ObstacleLab")
	assert(lab and lab:IsA("Folder"), "B15 requires ObstacleLab")

	assertPartX(lab, "FlatFloor", 10, 28, 0)
	assertPartX(lab, "RecoveryAfterFlatShort", 28, 38, 0)

	local stepIntervals = {
		{ 40, 44 },
		{ 45, 49 },
		{ 50, 54 },
		{ 55, 59 },
		{ 60, 64 },
	}
	assertPartX(lab, "StepsFloor", 38, 66, 0)
	for index, interval in ipairs(stepIntervals) do
		local name = string.format("Step%d", index)
		assertPartX(lab, name, interval[1], interval[2], 1.5)
		approx(requirePart(lab, name).Size.Y, 1.5, name .. ".Size.Y")
	end
	assert(requirePart(lab, "Step5") ~= nil, "SmallSteps must contain all five canonical blocks")

	assertPartX(lab, "WallFloor", 76, 96, 0)
	local wall = requirePart(lab, "Wall")
	approx(wall.Position.X, 86, "Wall.Position.X")
	approx(wall.Size.X, 2, "Wall.Size.X")
	approx(wall.Size.Y, 2.6, "Wall.Size.Y")
	approx(wall.Position.Y + wall.Size.Y / 2, 2.6, "Wall.TopY")

	assertPartX(lab, "GapApproach", 106, 116.4, 0)
	assertPartX(lab, "GapLanding", 119.6, 130, 0)
	for _, child in lab:GetChildren() do
		if child:IsA("BasePart") and child.CanCollide then
			local x0 = child.Position.X - child.Size.X / 2
			local x1 = child.Position.X + child.Size.X / 2
			local overlapsGapInterior = x1 > 116.4 + EPSILON and x0 < 119.6 - EPSILON
			assert(not overlapsGapInterior, string.format("%s illegally bridges GapSmall", child.Name))
		end
	end

	assertPartX(lab, "TunnelFloor", 140, 168, 0)
	local ceiling = requirePart(lab, "TunnelCeiling")
	approx(ceiling.Position.X, 154, "TunnelCeiling.Position.X")
	approx(ceiling.Size.X, 16, "TunnelCeiling.Size.X")
	approx(ceiling.Size.Y, 2, "TunnelCeiling.Size.Y")
	approx(ceiling.Position.Y - ceiling.Size.Y / 2, 4.25, "TunnelCeiling.BottomY")
	approx(ceiling.Size.Z, 8, "TunnelCeiling.Size.Z")

	print("[DrawRacers][B15] obstacle lab geometry tests PASS")
end

return B15ObstacleLabSpec
