--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B11LegShapeServiceSpec = {}

local VALID_SHAPE = {
	Vector2.zero,
	Vector2.new(-0.55, 0.70),
	Vector2.new(0.10, 0.92),
	Vector2.new(0.72, 0.45),
	Vector2.new(1.30, -0.05),
	Vector2.new(0.45, -0.78),
	Vector2.new(-0.45, -0.68),
}

local SECOND_VALID_SHAPE = {
	Vector2.zero,
	Vector2.new(-0.25, 0.75),
	Vector2.new(0.55, 0.60),
	Vector2.new(0.85, -0.30),
	Vector2.new(0.10, -0.85),
	Vector2.new(-0.70, -0.55),
}

local OFF_PIVOT_SHAPE = {
	Vector2.new(0.30, 0.30),
	Vector2.new(0.60, 0.65),
	Vector2.new(0.95, 0.10),
}

function B11LegShapeServiceSpec.run()
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
	assert(first.accepted == true, "first CR2 fixed-pivot shape must be accepted")
	assert(first.shapeVersion == 1 and first.shapeSpec ~= nil, "first accepted ShapeVersion must be 1")
	assert(racer:GetShapeVersion() == 1 and model:GetAttribute("ShapeVersion") == 1)
	assert(racer:GetCurrentShapeSpec() == first.shapeSpec)
	local firstSpec = first.shapeSpec
	assert((firstSpec.normalizedPoints[1] - Vector2.zero).Magnitude <= 1e-6, "authoritative first point must be fixed pivot")
	assert(firstSpec.extent <= 4.5 + 1e-6, "server radial extent cap failed")
	assert(#firstSpec.segmentPlan > 0 and #firstSpec.segmentPlan <= 14, "server segment plan cap failed")

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "first accepted shape missing pair")
	local leftDrive = pair:GetLeftDrive()
	local rightDrive = pair:GetRightDrive()
	local leftLeg = leftDrive:GetLeg()
	local rightLeg = rightDrive:GetLeg()
	local leftModel = leftLeg:GetModel()
	local rightModel = rightLeg:GetModel()

	local offPivot = LegShapeService.ValidateAndBuild(racer, OFF_PIVOT_SHAPE, false)
	assert(offPivot.accepted == false and offPivot.rejectReasonCode == "START_OFF_PIVOT", "off-pivot stroke must reject")
	assert(racer:GetShapeVersion() == 1, "off-pivot rejection changed ShapeVersion")
	assert(racer:GetLegPair() == pair and pair:GetLeftDrive() == leftDrive and pair:GetRightDrive() == rightDrive)

	local tiny = LegShapeService.ValidateAndBuild(racer, {
		Vector2.zero,
		Vector2.new(0.01, 0),
		Vector2.new(0.02, 0),
	}, false)
	assert(tiny.accepted == false and tiny.rejectReasonCode == "TOO_SHORT", "tiny shape must reject as TOO_SHORT")
	assert(racer:GetShapeVersion() == 1)

	local nonFinite = LegShapeService.ValidateAndBuild(racer, {
		Vector2.zero,
		Vector2.new(math.huge, 0.3),
		Vector2.new(0.5, 0),
	}, false)
	assert(nonFinite.accepted == false and nonFinite.rejectReasonCode == "NON_FINITE_POINT")
	assert(racer:GetShapeVersion() == 1)

	local malformed = LegShapeService.ValidateAndBuild(racer, {
		Vector2.zero,
		"not-a-vector",
		Vector2.new(0.5, 0),
	}, false)
	assert(malformed.accepted == false and malformed.rejectReasonCode == "MALFORMED_POINTS")
	assert(racer:GetShapeVersion() == 1)

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_VALID_SHAPE, false)
	assert(second.accepted == true and second.shapeVersion == 2 and second.shapeSpec ~= nil, "second valid shape must increment once")
	assert(racer:GetShapeVersion() == 2)
	assert(racer:GetLegPair() == pair, "redraw replaced persistent pair")
	assert(pair:GetLeftDrive() == leftDrive and pair:GetRightDrive() == rightDrive, "redraw replaced persistent drives")
	assert(pair:GetLeftLeg() == leftLeg and pair:GetRightLeg() == rightLeg, "redraw replaced persistent leg owners")
	assert(leftLeg:GetModel() == leftModel and rightLeg:GetModel() == rightModel, "redraw replaced side models")
	assert(#leftLeg:GetSegments() == #second.shapeSpec.segmentPlan, "left physical geometry not committed")
	assert(#rightLeg:GetSegments() == #second.shapeSpec.segmentPlan, "right physical geometry not committed")
	assert((second.shapeSpec.normalizedPoints[1] - Vector2.zero).Magnitude <= 1e-6, "second authoritative shape lost fixed pivot")

	racer:Destroy()
	print("[DrawRacers][B11] CR2 authoritative fixed-pivot LegShapeService tests PASS")
end

return B11LegShapeServiceSpec
