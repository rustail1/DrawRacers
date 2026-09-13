--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B13AtomicRedrawSpec = {}

local FIRST_SHAPE = {
	Vector2.new(-0.82, -0.18),
	Vector2.new(-0.28, 0.78),
	Vector2.new(0.48, 0.72),
	Vector2.new(0.88, -0.22),
	Vector2.new(0.10, -0.86),
	Vector2.new(-0.68, -0.60),
}

local SECOND_SHAPE = {
	Vector2.new(-0.92, 0.02),
	Vector2.new(-0.52, 0.82),
	Vector2.new(0.05, 0.96),
	Vector2.new(0.62, 0.70),
	Vector2.new(0.92, -0.10),
	Vector2.new(0.30, -0.90),
	Vector2.new(-0.58, -0.72),
}

local function countLegModels(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("Model") and (child.Name == "LeftLeg" or child.Name == "RightLeg") then
			count += 1
		end
	end
	return count
end

local function countAxleRoots(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("BasePart") and child.Name == "AxleRoot" then
			count += 1
		end
	end
	return count
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
	local legsFolder = model:FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"))

	local first = LegShapeService.ValidateAndBuild(racer, FIRST_SHAPE, false)
	assert(first.accepted == true and first.shapeVersion == 1, "B13 setup shape failed")
	racer:PrepareForRecovery()

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B13 setup pair missing")
	local axle = pair:GetRoot()
	local joint = pair:GetJoint()
	local left = pair:GetLeftLeg()
	local right = pair:GetRightLeg()
	local leftModel = left:GetModel()
	local rightModel = right:GetModel()
	local phaseBefore = pair:GetPhaseDegrees()

	body.AssemblyLinearVelocity = Vector3.new(11.25, 1.5, -0.35)
	body.AssemblyAngularVelocity = Vector3.new(0.2, -0.15, 0.4)
	local bodyCFrameBefore = body.CFrame
	local linearBefore = body.AssemblyLinearVelocity
	local angularBefore = body.AssemblyAngularVelocity

	local invalid = LegShapeService.ValidateAndBuild(racer, { Vector2.new(0, 0) }, false)
	assert(invalid.accepted == false, "invalid redraw must fail closed")
	assert(racer:GetShapeVersion() == 1, "invalid redraw changed ShapeVersion")
	assert(racer:GetLegPair() == pair, "invalid redraw replaced pair")
	assert(pair:GetLeftLeg() == left and pair:GetRightLeg() == right, "invalid redraw replaced side owners")
	assert(pair:GetRoot() == axle and pair:GetJoint() == joint, "invalid redraw replaced axle/joint")
	assert(left:GetModel() == leftModel and right:GetModel() == rightModel, "invalid redraw replaced side models")

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	assert(second.accepted == true and second.shapeVersion == 2, "valid B13 redraw must accept exactly once")
	assert(racer:GetShapeVersion() == 2)
	assert(racer:GetLegPair() == pair, "successful redraw replaced persistent pair")
	assert(pair:GetRoot() == axle and pair:GetJoint() == joint, "successful redraw replaced axle/joint")
	assert(pair:GetLeftLeg() == left and pair:GetRightLeg() == right, "successful redraw replaced side owners")
	assert(left:GetModel() == leftModel and right:GetModel() == rightModel, "successful redraw replaced side models")
	assert(math.abs(pair:GetPhaseDegrees() - phaseBefore) <= 0.1, "redraw changed live axle phase")
	assert(body.CFrame == bodyCFrameBefore, "successful redraw teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "successful redraw reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "successful redraw reset AssemblyAngularVelocity")
	assert(legsFolder:FindFirstChild("LeftLeg_Retiring") == nil, "redraw leaked LeftLeg_Retiring")
	assert(legsFolder:FindFirstChild("RightLeg_Retiring") == nil, "redraw leaked RightLeg_Retiring")
	assert(legsFolder:FindFirstChild("AxleRoot_Retiring") == nil, "redraw leaked AxleRoot_Retiring")
	assert(countLegModels(legsFolder) == 2, "redraw must leave exactly two side models")
	assert(countAxleRoots(legsFolder) == 1, "redraw must leave exactly one axle root")

	racer:PrepareForRecovery()
	assert(#left:GetSegments() == #second.shapeSpec.segmentPlan, "LeftLeg recovery completion must materialize authoritative plan")
	assert(#right:GetSegments() == #second.shapeSpec.segmentPlan, "RightLeg recovery completion must materialize authoritative plan")

	racer:Destroy()
	print("[DrawRacers][B13] persistent redraw identity tests PASS")
end

return B13AtomicRedrawSpec
