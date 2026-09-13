--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B13AtomicRedrawSpec = {}

local FIRST_SHAPE = {
	Vector2.zero,
	Vector2.new(-0.28, 0.78),
	Vector2.new(0.48, 0.72),
	Vector2.new(0.88, -0.22),
	Vector2.new(0.10, -0.86),
	Vector2.new(-0.68, -0.60),
}

local SECOND_SHAPE = {
	Vector2.zero,
	Vector2.new(-0.52, 0.82),
	Vector2.new(0.05, 0.96),
	Vector2.new(0.62, 0.70),
	Vector2.new(0.92, -0.10),
	Vector2.new(0.30, -0.90),
	Vector2.new(-0.58, -0.72),
}

local function countNamedDriveModels(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("Model") and (child.Name == "LeftDrive" or child.Name == "RightDrive") then count += 1 end
	end
	return count
end

local function countHinges(model: Model): number
	local count = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("HingeConstraint") then count += 1 end
	end
	return count
end

local function assertNoPendingGeometry(model: Model)
	for _, descendant in model:GetDescendants() do
		assert(descendant.Name ~= "StageVisual", "redraw leaked StageVisual")
		assert(descendant.Name ~= "PendingSegments", "redraw leaked PendingSegments")
		assert(descendant.Name ~= "PendingVisual", "redraw leaked PendingVisual")
	end
end

function B13AtomicRedrawSpec.run()
	local racer = RacerRuntime.new({
		raceId = "B13_TEST",
		slotIndex = 6,
		laneIndex = 6,
		isBot = false,
		trackId = "B13_FLAT",
		spawnCFrame = CFrame.new(18, 10, 0),
		laneCenterZ = 0,
	})

	local model = racer:GetModel()
	local body = racer:GetBody()
	body.Anchored = true
	local bodyCFrameBefore = body.CFrame
	local legsFolder = model:FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"))

	local first = LegShapeService.ValidateAndBuild(racer, FIRST_SHAPE, false)
	assert(first.accepted == true and first.shapeVersion == 1, "B13 setup shape failed")
	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B13 setup pair missing")
	local leftDrive = pair:GetLeftDrive()
	local rightDrive = pair:GetRightDrive()
	local leftJoint = leftDrive:GetJoint()
	local rightJoint = rightDrive:GetJoint()
	local left = leftDrive:GetLeg()
	local right = rightDrive:GetLeg()
	local leftModel = left:GetModel()
	local rightModel = right:GetModel()

	local invalid = LegShapeService.ValidateAndBuild(racer, { Vector2.zero }, false)
	assert(invalid.accepted == false, "invalid redraw must fail closed")
	assert(racer:GetShapeVersion() == 1, "invalid redraw changed ShapeVersion")
	assert(racer:GetLegPair() == pair, "invalid redraw replaced pair")
	assert(pair:GetLeftDrive() == leftDrive and pair:GetRightDrive() == rightDrive, "invalid redraw replaced drives")
	assert(leftDrive:GetJoint() == leftJoint and rightDrive:GetJoint() == rightJoint, "invalid redraw replaced drive joints")
	assert(left:GetModel() == leftModel and right:GetModel() == rightModel, "invalid redraw replaced leg models")

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	assert(second.accepted == true and second.shapeVersion == 2 and second.shapeSpec ~= nil, "valid B13 redraw must accept exactly once")
	assert(racer:GetShapeVersion() == 2)
	assert(racer:GetLegPair() == pair, "successful redraw replaced persistent pair")
	assert(pair:GetLeftDrive() == leftDrive and pair:GetRightDrive() == rightDrive, "successful redraw replaced persistent drives")
	assert(leftDrive:GetJoint() == leftJoint and rightDrive:GetJoint() == rightJoint, "successful redraw replaced drive joints")
	assert(pair:GetLeftLeg() == left and pair:GetRightLeg() == right, "successful redraw replaced side owners")
	assert(left:GetModel() == leftModel and right:GetModel() == rightModel, "successful redraw replaced side models")
	assert(body.CFrame == bodyCFrameBefore, "successful redraw moved anchored BodyCollider")
	assert(countNamedDriveModels(legsFolder) == 2, "redraw must leave exactly two persistent drive models")
	assert(countHinges(model) == 2, "redraw must leave exactly two drive hinges")
	assert(#left:GetSegments() == #second.shapeSpec.segmentPlan, "LeftLeg commit must match authoritative plan")
	assert(#right:GetSegments() == #second.shapeSpec.segmentPlan, "RightLeg commit must match authoritative plan")
	assertNoPendingGeometry(model)

	racer:PrepareForRecovery()
	assertNoPendingGeometry(model)
	racer:Destroy()
	print("[DrawRacers][B13] CR2 transactional redraw identity tests PASS")
end

return B13AtomicRedrawSpec
