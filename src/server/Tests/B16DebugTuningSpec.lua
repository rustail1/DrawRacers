--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local DebugTelemetry = require(script.Parent.Parent.Runtime:WaitForChild("DebugTelemetry"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B16DebugTuningSpec = {}

-- CR2 fixed-pivot shape: the first semantic sample is the visible pivot.
local SHAPE = {
	Vector2.zero,
	Vector2.new(0.35, 0.70),
	Vector2.new(0.80, 0.40),
	Vector2.new(1.05, -0.20),
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
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
	assert(result.accepted == true, "B16 fixed-pivot setup shape must build")

	local model = racer:GetModel()
	local body = racer:GetBody()
	local currentShape = racer:GetCurrentShapeSpec()
	assert(currentShape ~= nil, "B16 setup missing current ShapeSpec")
	model:SetAttribute("LaneCenterZ", 0)
	model:SetAttribute("Checkpoint", 2)
	model:SetAttribute("Progress", 0.375)
	body.Anchored = true

	DebugTelemetry.sampleRacer(model, 0)

	assert(model:GetAttribute("DebugShapeVersion") == 1, "shapeVersion telemetry mismatch")
	assert(model:GetAttribute("DebugRawPoints") == #SHAPE, "raw point metric mismatch")
	assert(model:GetAttribute("DebugSimplifiedPoints") == #currentShape.normalizedPoints, "simplified point metric mismatch")
	assert(model:GetAttribute("DebugPhysicsPoints") == #currentShape.mappedPoints, "physics point metric mismatch")
	assert((model:GetAttribute("DebugColliderSegments") :: number) > 0, "collider segment metric missing")
	assert((model:GetAttribute("DebugBodySpeed") :: number) >= 0, "body speed metric missing")
	assert(model:GetAttribute("DebugMotorEnabled") == false, "disabled twin drives must report false")
	assert(isFiniteNumber(model:GetAttribute("DebugMotorAngularVelocity")), "motor angular velocity metric missing")
	assert(model:GetAttribute("DebugStuckState") == false, "stuck must wait for a full progress window")
	assert(isFiniteNumber(model:GetAttribute("DebugLaneDeviation")), "lane deviation metric missing")
	assert(model:GetAttribute("DebugCheckpoint") == 2, "checkpoint metric mismatch")
	assert(model:GetAttribute("DebugProgress") == 0.375, "progress metric mismatch")

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B16 setup twin-drive pair missing")
	local leftDrive = pair:GetLeftDrive()
	local rightDrive = pair:GetRightDrive()
	assert(leftDrive:GetModel().Name == "LeftDrive", "B16 LeftDrive missing")
	assert(rightDrive:GetModel().Name == "RightDrive", "B16 RightDrive missing")
	local leftJoint = leftDrive:GetJoint()
	local rightJoint = rightDrive:GetJoint()
	assert(leftJoint.Name == "DriveJoint" and leftJoint:IsA("HingeConstraint"), "B16 left DriveJoint missing")
	assert(rightJoint.Name == "DriveJoint" and rightJoint:IsA("HingeConstraint"), "B16 right DriveJoint missing")

	pair:SetEnabled(true)
	DebugTelemetry.sampleRacer(model, 0.1)
	assert(model:GetAttribute("DebugMotorEnabled") == true, "enabled twin drives must report true")
	local expectedMean = (leftJoint.AngularVelocity + rightJoint.AngularVelocity) * 0.5
	local reportedMean = model:GetAttribute("DebugMotorAngularVelocity")
	assert(isFiniteNumber(reportedMean), "enabled twin motor angular velocity missing")
	assert(math.abs((reportedMean :: number) - expectedMean) < 1e-6, "twin motor speed telemetry mismatch")

	body.Position = body.Position + Vector3.new(PhysicsConfig.Recovery.MeaningfulHorizontalProgress - 0.1, 0, 0)
	DebugTelemetry.sampleRacer(model, PhysicsConfig.Recovery.ProgressSampleWindow)
	assert(model:GetAttribute("DebugStuckState") == true, "sub-threshold X progress must report stuck")

	body.Position = body.Position + Vector3.new(PhysicsConfig.Recovery.MeaningfulHorizontalProgress + 0.1, 0, 0)
	DebugTelemetry.sampleRacer(model, PhysicsConfig.Recovery.ProgressSampleWindow * 2)
	assert(model:GetAttribute("DebugStuckState") == false, "meaningful X progress must clear stuck")

	racer:Destroy()
	print("[DrawRacers][B16] CR2 debug tuning panel tests PASS")
end

return B16DebugTuningSpec
