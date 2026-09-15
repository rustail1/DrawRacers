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

local function countSharedDriveModels(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("Model") and child.Name == "SharedLegDrive" then
			count += 1
		end
	end
	return count
end

local function countHinges(model: Model): number
	local count = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

local function assertNoTransientGeometry(model: Model)
	for _, descendant in model:GetDescendants() do
		assert(descendant.Name ~= "Preview", "redraw leaked Preview")
		assert(descendant.Name ~= "BuildSegments", "redraw leaked BuildSegments")
		assert(descendant.Name ~= "BuildVisual", "redraw leaked BuildVisual")
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
	local drive = pair:GetDrive()
	local joint = drive:GetJoint()
	local left = pair:GetLeftLeg()
	local right = pair:GetRightLeg()
	local leftModel = left:GetModel()
	local rightModel = right:GetModel()

	local invalid = LegShapeService.ValidateAndBuild(racer, { Vector2.zero }, false)
	assert(invalid.accepted == false, "invalid redraw must fail closed")
	assert(racer:GetShapeVersion() == 1, "invalid redraw changed ShapeVersion")
	assert(racer:GetLegPair() == pair, "invalid redraw replaced pair")
	assert(pair:GetDrive() == drive, "invalid redraw replaced SharedLegDrive")
	assert(drive:GetJoint() == joint, "invalid redraw replaced DriveJoint")
	assert(left:GetModel() == leftModel and right:GetModel() == rightModel, "invalid redraw replaced leg owners")
	assertNoTransientGeometry(model)

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	assert(
		second.accepted == true
			and second.shapeVersion == 2
			and second.shapeSpec ~= nil,
		"valid B13 redraw must accept exactly once"
	)

	assert(racer:GetShapeVersion() == 2)
	assert(racer:GetLegPair() == pair, "successful redraw replaced pair")
	assert(pair:GetDrive() == drive, "successful redraw replaced SharedLegDrive")
	assert(drive:GetJoint() == joint, "successful redraw replaced DriveJoint")
	assert(pair:GetLeftLeg() == left and pair:GetRightLeg() == right, "successful redraw replaced leg owners")
	assert(left:GetModel() == leftModel and right:GetModel() == rightModel, "successful redraw replaced leg models")
	assert(body.CFrame == bodyCFrameBefore, "anchored body moved during redraw")
	assert(countSharedDriveModels(legsFolder) == 1, "redraw must keep one SharedLegDrive")
	assert(countHinges(model) == 1, "redraw must keep one DriveJoint")
	assert(#left:GetSegments() == #second.shapeSpec.segmentPlan, "left final geometry mismatch")
	assert(#right:GetSegments() == #second.shapeSpec.segmentPlan, "right final geometry mismatch")
	assertNoTransientGeometry(model)

	racer:PrepareForRecovery()
	assertNoTransientGeometry(model)

	racer:Destroy()
	print("[DrawRacers][B13] Leg Core v2 redraw identity/cleanup tests PASS")
end

return B13AtomicRedrawSpec
