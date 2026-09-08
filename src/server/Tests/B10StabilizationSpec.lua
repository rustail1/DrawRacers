--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B10StabilizationSpec = {}

function B10StabilizationSpec.run()
	local config = PhysicsConfig.Stabilization
	local racer = RacerRuntime.new({
		raceId = "B10_TEST",
		slotIndex = 3,
		laneIndex = 3,
		isBot = true,
		trackId = "B10_FLAT",
		spawnCFrame = CFrame.new(-18, 8, 2.5),
		laneCenterZ = 2.5,
	})

	local body = racer:GetBody()
	body.Anchored = true
	local model = racer:GetModel()
	local stabilizer = racer:GetStabilizer()
	local laneAlign = stabilizer:GetLaneAlign()
	local orientationAlign = stabilizer:GetOrientationAlign()

	assert(laneAlign.Mode == Enum.PositionAlignmentMode.OneAttachment)
	assert(laneAlign.ForceLimitMode == Enum.ForceLimitMode.PerAxis)
	assert(laneAlign.ForceRelativeTo == Enum.ActuatorRelativeTo.World)
	assert(laneAlign.MaxAxesForce.X == 0, "B10 lane stabilizer must apply zero X force")
	assert(laneAlign.MaxAxesForce.Y == 0, "B10 lane stabilizer must apply zero Y force")
	assert(laneAlign.MaxAxesForce.Z == config.LaneMaxForceZ, "B10 lane stabilizer must apply only configured Z force")
	assert(orientationAlign.Mode == Enum.OrientationAlignmentMode.OneAttachment)
	assert(orientationAlign.Responsiveness == config.OrientationResponsiveness)
	assert(orientationAlign.RigidityEnabled == false)
	assert(orientationAlign.Enabled == true)

	body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneCorrectionDeadzone * 0.5)
	stabilizer:Step()
	assert(laneAlign.Enabled == false, "lane correction must stay off inside deadzone")
	assert(model:GetAttribute("LaneHardBoundExceeded") == false)

	body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneCorrectionDeadzone + 0.05)
	stabilizer:Step()
	assert(laneAlign.Enabled == true, "lane correction must activate outside deadzone")
	assert(math.abs(laneAlign.Position.Z - 2.5) <= 1e-6, "lane target must stay on canonical lane center Z")
	assert(model:GetAttribute("LaneNormalBoundExceeded") == false)

	body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneNormalError + 0.05)
	stabilizer:Step()
	assert(model:GetAttribute("LaneNormalBoundExceeded") == true, "normal lane bound flag did not activate")
	assert(model:GetAttribute("LaneHardBoundExceeded") == false)

	body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneHardBound + 0.05)
	stabilizer:Step()
	assert(model:GetAttribute("LaneHardBoundExceeded") == true, "hard lane bound flag did not activate")

	racer:Destroy()
	assert(model.Parent == nil, "B10 RacerRuntime destroy left stabilized model behind")

	print("[DrawRacers][B10] stabilization/lane tests PASS")
end

return B10StabilizationSpec
