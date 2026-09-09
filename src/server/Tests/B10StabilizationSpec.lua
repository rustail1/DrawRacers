--!strict

local PhysicsService = game:GetService("PhysicsService")
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

	assert(PhysicsService:CollisionGroupsAreCollidable("Default", "RacerBody") == false, "Default must not collide with RacerBody")
	assert(PhysicsService:CollisionGroupsAreCollidable("Default", "RacerLeg") == false, "Default must not collide with RacerLeg")
	assert(PhysicsService:CollisionGroupsAreCollidable("Track", "RacerBody") == true, "Track must collide with RacerBody")
	assert(PhysicsService:CollisionGroupsAreCollidable("Track", "RacerLeg") == true, "Track must collide with RacerLeg")

	local body = racer:GetBody()
	body.Anchored = true
	local model = racer:GetModel()
	local stabilizer = racer:GetStabilizer()
	local laneAlign = stabilizer:GetLaneAlign()
	local orientationAlign = stabilizer:GetOrientationAlign()

	assert(laneAlign.Mode == Enum.PositionAlignmentMode.OneAttachment)
	assert(laneAlign.ForceLimitMode == Enum.ForceLimitMode.PerAxis)
	assert(laneAlign.ForceRelativeTo == Enum.ActuatorRelativeTo.World)
	assert(laneAlign.MaxAxesForce.X == 0, "B10 planar lock must apply zero X force")
	assert(laneAlign.MaxAxesForce.Y == 0, "B10 planar lock must apply zero Y force")
	assert(laneAlign.MaxAxesForce.Z == config.LaneMaxForceZ, "B10 planar lock must apply only configured Z force")
	assert(laneAlign.Enabled == true, "lane constraint must remain continuously enabled")
	assert(math.abs(laneAlign.Position.Z - 2.5) <= 1e-6, "planar Z target must equal canonical lane center")

	assert(orientationAlign.Mode == Enum.OrientationAlignmentMode.OneAttachment)
	assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel)
	assert(orientationAlign.PrimaryAxis == Vector3.zAxis)
	assert(orientationAlign.Responsiveness == config.OrientationResponsiveness)
	assert(orientationAlign.RigidityEnabled == false)
	assert(orientationAlign.Enabled == true, "planar orientation constraint must remain continuously enabled")

	body.CFrame = CFrame.new(body.Position) * CFrame.Angles(0, 0, math.rad(70))
	stabilizer:Step()
	assert(orientationAlign.Enabled == true, "in-plane rotation around Z must remain unconstrained")
	assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel, "in-plane rotation must not promote to AllAxes")

	body.CFrame = CFrame.new(body.Position) * CFrame.Angles(math.rad(30), 0, 0)
	stabilizer:Step()
	assert(orientationAlign.Enabled == true, "out-of-plane disturbance must keep planar correction active")
	assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel)

	body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneNormalError + 0.005)
	stabilizer:Step()
	assert(laneAlign.Enabled == true)
	assert(math.abs(laneAlign.Position.Z - 2.5) <= 1e-6, "planar Z target drifted from lane center")
	assert(model:GetAttribute("LaneNormalBoundExceeded") == true)
	assert(model:GetAttribute("LaneHardBoundExceeded") == false)

	body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneHardBound + 0.005)
	stabilizer:Step()
	assert(laneAlign.Enabled == true)
	assert(model:GetAttribute("LaneHardBoundExceeded") == true)

	racer:Destroy()
	assert(model.Parent == nil, "B10 RacerRuntime destroy left stabilized model behind")

	print("[DrawRacers][B10] stabilization/lane tests PASS")
end

return B10StabilizationSpec
