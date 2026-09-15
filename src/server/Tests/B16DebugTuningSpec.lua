--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local DebugTelemetry = require(script.Parent.Parent.Runtime:WaitForChild("DebugTelemetry"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B16DebugTuningSpec = {}

local SHAPE = {
	Vector2.zero,
	Vector2.new(0.35, 0.70),
	Vector2.new(0.80, 0.40),
	Vector2.new(1.05, -0.20),
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value > -math.huge
		and value < math.huge
end

function B16DebugTuningSpec.run()
	local racer = RacerRuntime.new({
		raceId = "B16_TEST",
		slotIndex = 7,
		laneIndex = 7,
		isBot = false,
		trackId = "B16_FLAT",
		spawnCFrame = CFrame.new(0, 8, 0),
		laneCenterZ = 0,
	})

	local result = LegShapeService.ValidateAndBuild(racer, SHAPE, false)
	assert(result.accepted == true, "B16 setup shape must build")

	local model = racer:GetModel()
	local body = racer:GetBody()
	local currentShape = racer:GetCurrentShapeSpec()
	assert(currentShape ~= nil, "B16 setup missing current ShapeSpec")

	model:SetAttribute("LaneCenterZ", 0)
	model:SetAttribute("Checkpoint", 2)
	model:SetAttribute("Progress", 0.375)
	body.Anchored = true

	DebugTelemetry.sampleRacer(model, 0)

	assert(model:GetAttribute("DebugShapeVersion") == 1)
	assert(model:GetAttribute("DebugRawPoints") == #SHAPE)
	assert(model:GetAttribute("DebugSimplifiedPoints") == #currentShape.normalizedPoints)
	assert(model:GetAttribute("DebugPhysicsPoints") == #currentShape.mappedPoints)
	assert((model:GetAttribute("DebugColliderSegments") :: number) > 0)
	assert((model:GetAttribute("DebugBodySpeed") :: number) >= 0)
	assert(model:GetAttribute("DebugMotorEnabled") == false, "disabled shared motor must report false")
	assert(isFiniteNumber(model:GetAttribute("DebugMotorAngularVelocity")))
	assert(model:GetAttribute("DebugStuckState") == false)
	assert(isFiniteNumber(model:GetAttribute("DebugLaneDeviation")))
	assert(model:GetAttribute("DebugCheckpoint") == 2)
	assert(model:GetAttribute("DebugProgress") == 0.375)

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B16 shared-drive pair missing")
	local drive = pair:GetDrive()
	assert(drive:GetModel().Name == "SharedLegDrive", "B16 SharedLegDrive missing")

	local joint = drive:GetJoint()
	assert(joint.Name == "DriveJoint" and joint:IsA("HingeConstraint"))
	assert(joint.ActuatorType == Enum.ActuatorType.Motor)

	pair:SetEnabled(true)
	DebugTelemetry.sampleRacer(model, 0.1)

	assert(model:GetAttribute("DebugMotorEnabled") == true, "enabled shared motor must report true")
	local reported = model:GetAttribute("DebugMotorAngularVelocity")
	assert(isFiniteNumber(reported), "shared motor angular velocity missing")
	assert(
		math.abs((reported :: number) - joint.AngularVelocity) < 1e-6,
		"shared motor speed telemetry mismatch"
	)

	body.Position += Vector3.new(
		PhysicsConfig.Recovery.MeaningfulHorizontalProgress - 0.1,
		0,
		0
	)
	DebugTelemetry.sampleRacer(model, PhysicsConfig.Recovery.ProgressSampleWindow)
	assert(model:GetAttribute("DebugStuckState") == true)

	body.Position += Vector3.new(
		PhysicsConfig.Recovery.MeaningfulHorizontalProgress + 0.1,
		0,
		0
	)
	DebugTelemetry.sampleRacer(
		model,
		PhysicsConfig.Recovery.ProgressSampleWindow * 2
	)
	assert(model:GetAttribute("DebugStuckState") == false)

	racer:Destroy()
	print("[DrawRacers][B16] shared-drive debug telemetry tests PASS")
end

return B16DebugTuningSpec
