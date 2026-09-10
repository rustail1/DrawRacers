--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B11LegShapeServiceSpec = {}

local VALID_SHAPE = {
	Vector2.new(-1.25, -0.10),
	Vector2.new(-0.55, 0.70),
	Vector2.new(0.10, 0.92),
	Vector2.new(0.72, 0.45),
	Vector2.new(1.30, -0.05),
	Vector2.new(0.45, -0.78),
	Vector2.new(-0.45, -0.68),
}

local SECOND_VALID_SHAPE = {
	Vector2.new(-0.85, -0.15),
	Vector2.new(-0.25, 0.75),
	Vector2.new(0.55, 0.60),
	Vector2.new(0.85, -0.30),
	Vector2.new(0.10, -0.85),
	Vector2.new(-0.70, -0.55),
}

local ANCHOR_BASE_SHAPE = {
	Vector2.new(-0.45, -0.20),
	Vector2.new(-0.20, 0.35),
	Vector2.new(0.15, 0.40),
	Vector2.new(0.45, 0.05),
	Vector2.new(0.25, -0.35),
	Vector2.new(-0.30, -0.40),
}

-- Exact translation of ANCHOR_BASE_SHAPE by (+0.20,+0.45).
local ANCHOR_SHIFTED_SHAPE = {
	Vector2.new(-0.25, 0.25),
	Vector2.new(0.00, 0.80),
	Vector2.new(0.35, 0.85),
	Vector2.new(0.65, 0.50),
	Vector2.new(0.45, 0.10),
	Vector2.new(-0.10, 0.05),
}

local function assertClose(actual: number, expected: number, tolerance: number, message: string)
	assert(math.abs(actual - expected) <= tolerance, string.format("%s: expected %.6f got %.6f", message, expected, actual))
end

local function assertSamePointsWithTolerance(actual: { Vector2 }, expected: { Vector2 }, tolerance: number, message: string)
	assert(#actual == #expected, string.format("%s: point count mismatch %d vs %d", message, #actual, #expected))
	for index = 1, #actual do
		assert(
			(actual[index] - expected[index]).Magnitude <= tolerance,
			string.format("%s at %d: expected %s got %s", message, index, tostring(expected[index]), tostring(actual[index]))
		)
	end
end

function B11LegShapeServiceSpec.run()
	local config = PhysicsConfig.StrokeProcessing
	local racer = RacerRuntime.new({
		raceId = "B11_TEST",
		slotIndex = 4,
		laneIndex = 4,
		isBot = false,
		trackId = "B11_FLAT",
		spawnCFrame = CFrame.new(-8, 8, 0),
		laneCenterZ = 0,
	})

	local body = racer:GetBody()
	body.Anchored = true
	local model = racer:GetModel()
	assert(racer:GetShapeVersion() == 0)
	assert(model:GetAttribute("ShapeVersion") == 0)
	assert(racer:GetCurrentShapeSpec() == nil)

	local first = LegShapeService.ValidateAndBuild(racer, VALID_SHAPE, false)
	assert(first.accepted == true, "first valid shape must be accepted")
	assert(first.shapeVersion == 1, "first accepted ShapeVersion must be 1")
	assert(first.shapeSpec ~= nil, "accepted result missing ShapeSpec")
	assert(racer:GetShapeVersion() == 1)
	assert(model:GetAttribute("ShapeVersion") == 1)
	assert(racer:GetCurrentShapeSpec() == first.shapeSpec)
	assert(model.Legs:FindFirstChild("LeftLeg") ~= nil)
	assert(model.Legs:FindFirstChild("RightLeg") ~= nil)

	local shapeSpec = first.shapeSpec
	assert((shapeSpec.normalizedPoints[1] - Vector2.zero).Magnitude <= 1e-6, "first authoritative point must be the hub origin")
	assert(shapeSpec.bounds.min.X >= -config.RawSemanticHalfWidth * 2 - 1e-6, "anchored X min escaped legal difference range")
	assert(shapeSpec.bounds.max.X <= config.RawSemanticHalfWidth * 2 + 1e-6, "anchored X max escaped legal difference range")
	assert(shapeSpec.bounds.min.Y >= -config.RawSemanticHalfHeight * 2 - 1e-6, "anchored Y min escaped legal difference range")
	assert(shapeSpec.bounds.max.Y <= config.RawSemanticHalfHeight * 2 + 1e-6, "anchored Y max escaped legal difference range")
	assert(shapeSpec.extent <= 4.5 + 1e-6, "server radial extent cap failed")
	assert(#shapeSpec.segmentPlan > 0 and #shapeSpec.segmentPlan <= 14, "server segment plan cap failed")

	local oldLeft = model.Legs:FindFirstChild("LeftLeg")
	local oldRight = model.Legs:FindFirstChild("RightLeg")
	assert(oldLeft ~= nil and oldRight ~= nil)

	local tiny = LegShapeService.ValidateAndBuild(racer, {
		Vector2.new(0, 0),
		Vector2.new(0.01, 0),
		Vector2.new(0.02, 0),
	}, false)
	assert(tiny.accepted == false and tiny.rejectReasonCode == "TOO_SHORT", "tiny shape must reject as TOO_SHORT")
	assert(racer:GetShapeVersion() == 1, "rejected tiny shape changed ShapeVersion")
	assert(model.Legs:FindFirstChild("LeftLeg") == oldLeft, "rejected tiny shape replaced LeftLeg")
	assert(model.Legs:FindFirstChild("RightLeg") == oldRight, "rejected tiny shape replaced RightLeg")

	local nonFinite = LegShapeService.ValidateAndBuild(racer, {
		Vector2.new(-0.5, 0),
		Vector2.new(math.huge, 0.3),
		Vector2.new(0.5, 0),
	}, false)
	assert(nonFinite.accepted == false and nonFinite.rejectReasonCode == "NON_FINITE_POINT")
	assert(racer:GetShapeVersion() == 1, "NON_FINITE_POINT changed ShapeVersion")
	assert(model.Legs:FindFirstChild("LeftLeg") == oldLeft)

	local malformed = LegShapeService.ValidateAndBuild(racer, {
		Vector2.new(-0.5, 0),
		"not-a-vector",
		Vector2.new(0.5, 0),
	}, false)
	assert(malformed.accepted == false and malformed.rejectReasonCode == "MALFORMED_POINTS")
	assert(racer:GetShapeVersion() == 1, "MALFORMED_POINTS changed ShapeVersion")
	assert(model.Legs:FindFirstChild("RightLeg") == oldRight)

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_VALID_SHAPE, false)
	assert(second.accepted == true and second.shapeVersion == 2, "second valid shape must increment ShapeVersion exactly once")
	assert(racer:GetShapeVersion() == 2)
	assert(model.Legs:FindFirstChild("LeftLeg") ~= oldLeft, "second accepted shape did not rebuild LeftLeg")
	assert(model.Legs:FindFirstChild("RightLeg") ~= oldRight, "second accepted shape did not rebuild RightLeg")

	local anchoringRacer = RacerRuntime.new({
		raceId = "B11_ANCHORING_TEST",
		slotIndex = 5,
		laneIndex = 5,
		isBot = false,
		trackId = "B11_ANCHORING_FLAT",
		spawnCFrame = CFrame.new(-4, 8, 6),
		laneCenterZ = 6,
	})
	anchoringRacer:GetBody().Anchored = true

	local anchoredBase = LegShapeService.ValidateAndBuild(anchoringRacer, ANCHOR_BASE_SHAPE, false)
	assert(anchoredBase.accepted == true and anchoredBase.shapeSpec ~= nil, "base anchoring shape must be accepted")
	local baseSpec = anchoredBase.shapeSpec

	local anchoredShifted = LegShapeService.ValidateAndBuild(anchoringRacer, ANCHOR_SHIFTED_SHAPE, false)
	assert(anchoredShifted.accepted == true and anchoredShifted.shapeSpec ~= nil, "shifted anchoring shape must be accepted")
	local shiftedSpec = anchoredShifted.shapeSpec

	assertSamePointsWithTolerance(
		shiftedSpec.normalizedPoints,
		baseSpec.normalizedPoints,
		1e-5,
		"shifted shape must anchor to same normalized geometry"
	)
	local baseSize = baseSpec.bounds.max - baseSpec.bounds.min
	local shiftedSize = shiftedSpec.bounds.max - shiftedSpec.bounds.min
	assertClose(shiftedSize.X, baseSize.X, 1e-5, "anchoring must preserve shape width")
	assertClose(shiftedSize.Y, baseSize.Y, 1e-5, "anchoring must preserve shape height")
	assert((baseSpec.normalizedPoints[1] - Vector2.zero).Magnitude <= 1e-6, "base first point must anchor to origin")
	assert((shiftedSpec.normalizedPoints[1] - Vector2.zero).Magnitude <= 1e-6, "shifted first point must anchor to origin")

	anchoringRacer:Destroy()
	racer:Destroy()
	print("[DrawRacers][B11] authoritative LegShapeService tests PASS")
end

return B11LegShapeServiceSpec
