--!strict

local DebugTelemetry = require(script.Parent.Parent.Runtime:WaitForChild("DebugTelemetry"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B16DebugTuningSpec = {}

local SHAPE = {
	Vector2.new(-0.8, -0.3),
	Vector2.new(-0.35, 0.75),
	Vector2.new(0.35, 0.75),
	Vector2.new(0.8, -0.3),
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
	assert(result.accepted == true, "B16 setup shape must build")

	local model = racer:GetModel()
	local body = racer:GetBody()
	model:SetAttribute("LaneCenterZ", 0)
	model:SetAttribute("Checkpoint", 2)
	model:SetAttribute("Progress", 0.375)
	body.AssemblyLinearVelocity = Vector3.new(3, 0, 0)

	DebugTelemetry.sampleRacer(model)

	assert(model:GetAttribute("DebugShapeVersion") == 1, "shapeVersion telemetry mismatch")
	assert(isFiniteNumber(model:GetAttribute("DebugSimplifiedPoints")), "simplified point metric missing")
	assert((model:GetAttribute("DebugColliderSegments") :: number) > 0, "collider segment metric missing")
	assert((model:GetAttribute("DebugBodySpeed") :: number) >= 0, "body speed metric missing")
	assert(isFiniteNumber(model:GetAttribute("DebugMotorAngularVelocity")), "motor angular velocity metric missing")
	assert(type(model:GetAttribute("DebugStuckState")) == "boolean", "stuck state metric missing")
	assert(isFiniteNumber(model:GetAttribute("DebugLaneDeviation")), "lane deviation metric missing")
	assert(model:GetAttribute("DebugCheckpoint") == 2, "checkpoint metric mismatch")
	assert(model:GetAttribute("DebugProgress") == 0.375, "progress metric mismatch")

	racer:Destroy()
	print("[DrawRacers][B16] debug tuning panel tests PASS")
end

return B16DebugTuningSpec
