--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local GeometryMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("GeometryMath")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegAssembly = require(script.Parent.Parent.Runtime:WaitForChild("LegAssembly"))

local B08OneHingeMotorHarness = {}

local ROUND_01 = {
	Vector2.new(0.72, 0),
	Vector2.new(0.624, 0.36),
	Vector2.new(0.36, 0.624),
	Vector2.new(0, 0.72),
	Vector2.new(-0.36, 0.624),
	Vector2.new(-0.624, 0.36),
	Vector2.new(-0.72, 0),
	Vector2.new(-0.624, -0.36),
	Vector2.new(-0.36, -0.624),
	Vector2.new(0, -0.72),
	Vector2.new(0.36, -0.624),
	Vector2.new(0.624, -0.36),
}

function B08OneHingeMotorHarness.start()
	local racer = RacerRuntime.new({
		raceId = "B08_FLAT",
		slotIndex = 8,
		laneIndex = 1,
		isBot = true,
		trackId = "B08_FLAT",
		spawnCFrame = CFrame.new(18, 3.30, 0),
	})

	local body = racer:GetBody()
	body.Transparency = 0.35
	body.Color = Color3.fromRGB(255, 145, 65)
	body.Material = Enum.Material.SmoothPlastic

	local geometryPlan = GeometryMath.BuildSegmentPlan(ROUND_01, PhysicsConfig.LegGeometry)
	local leg = LegAssembly.new({
		racerModel = racer:GetModel(),
		side = "Left",
		shapeSpec = {
			normalizedPoints = ROUND_01,
			mappedPoints = geometryPlan.mappedPoints,
			segmentPlan = geometryPlan.segmentPlan,
			extent = geometryPlan.extent,
		},
		motorEnabled = true,
	})

	local joint = leg:GetJoint()
	assert(joint.ActuatorType == Enum.ActuatorType.Motor)
	assert(joint.AngularVelocity == PhysicsConfig.Motor.AngularVelocity)
	assert(joint.MotorMaxTorque == PhysicsConfig.Motor.MotorMaxTorque)
	assert(joint.MotorMaxAcceleration == PhysicsConfig.Motor.MotorMaxAcceleration)
	assert(joint.Enabled == true)
	assert(racer:GetModel().Legs:FindFirstChild("LeftLeg") ~= nil)

	local startX = body.Position.X
	print("[DrawRacers][B08] one-hinge flat harness ready")

	task.spawn(function()
		for second = 1, 6 do
			task.wait(1)
			if body.Parent == nil then
				return
			end

			local deltaX = body.Position.X - startX
			local speedX = body.AssemblyLinearVelocity.X
			print(string.format(
				"[DrawRacers][B08] t=%ds deltaX=%.3f speedX=%.3f",
				second,
				deltaX,
				speedX
			))
		end
	end)
end

return B08OneHingeMotorHarness
