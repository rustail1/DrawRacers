--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B09TwoLegPhaseSpec = {}

local SHAPE_A = {
	Vector2.zero,
	Vector2.new(0.45, 0.75),
	Vector2.new(0.92, 0.10),
	Vector2.new(0.30, -0.82),
}

local SHAPE_B = {
	Vector2.zero,
	Vector2.new(0.20, 0.92),
	Vector2.new(0.88, 0.40),
	Vector2.new(0.72, -0.60),
	Vector2.new(-0.05, -0.82),
}

local function angularDistanceDegrees(a: number, b: number): number
	local delta = (a - b + 180) % 360 - 180
	return math.abs(delta)
end

local function assertSamePoints(left: { Vector2 }, right: { Vector2 })
	assert(#left == #right, "two legs must share mapped point count")
	for index, point in left do
		assert((point - right[index]).Magnitude <= 1e-6, string.format("mapped point %d differs between legs", index))
	end
end

local function countHinges(model: Model): number
	local count = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("HingeConstraint") then count += 1 end
	end
	return count
end

local function assertStructuralPair(racer: any)
	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B09 CR2 pair missing")
	local leftDrive = pair:GetLeftDrive()
	local rightDrive = pair:GetRightDrive()
	local left = leftDrive:GetLeg()
	local right = rightDrive:GetLeg()
	assertSamePoints(left:GetMappedPoints(), right:GetMappedPoints())

	local body = racer:GetBody()
	local leftLocal = body.CFrame:PointToObjectSpace(leftDrive:GetRoot().Position)
	local rightLocal = body.CFrame:PointToObjectSpace(rightDrive:GetRoot().Position)
	local halfWidth = body.Size.X * 0.5
	assert(math.abs(leftLocal.X + halfWidth) <= 1e-3, "left drive pivot must be on negative horizontal cube edge")
	assert(math.abs(rightLocal.X - halfWidth) <= 1e-3, "right drive pivot must be on positive horizontal cube edge")
	assert(math.abs(leftLocal.Z) <= 1e-3 and math.abs(rightLocal.Z) <= 1e-3, "CR2 drives must not use depth-separated Z sockets")

	local structuralDifference = (rightDrive:GetPhaseDegrees() - leftDrive:GetPhaseDegrees() + 360) % 360
	assert(
		angularDistanceDegrees(structuralDifference, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 0.5,
		string.format("CR2 opposed drive phase expected 180 got %.4f", structuralDifference)
	)

	local leftJoint = leftDrive:GetJoint()
	local rightJoint = rightDrive:GetJoint()
	assert(leftJoint.Name == "DriveJoint" and rightJoint.Name == "DriveJoint", "CR2 drive joints missing")
	assert(leftJoint.ActuatorType == Enum.ActuatorType.Motor and rightJoint.ActuatorType == Enum.ActuatorType.Motor)
	assert(countHinges(racer:GetModel()) == 2, "CR2 pair must own exactly two HingeConstraints")
end

function B09TwoLegPhaseSpec.run()
	local racer = RacerRuntime.new({
		raceId = "B09_TEST",
		slotIndex = 2,
		laneIndex = 2,
		isBot = false,
		trackId = "B09_FLAT",
		spawnCFrame = CFrame.new(-28, 10, 0),
		laneCenterZ = 0,
	})
	local body = racer:GetBody()
	body.Anchored = true

	local left, right = racer:ApplyShape(SHAPE_A, false)
	assert(left:GetModel().Name == "LeftLeg")
	assert(right:GetModel().Name == "RightLeg")
	assertStructuralPair(racer)

	local pairBefore = racer:GetLegPair()
	local leftDriveBefore = pairBefore:GetLeftDrive()
	local rightDriveBefore = pairBefore:GetRightDrive()
	local leftJointBefore = leftDriveBefore:GetJoint()
	local rightJointBefore = rightDriveBefore:GetJoint()
	local leftLegBefore = leftDriveBefore:GetLeg()
	local rightLegBefore = rightDriveBefore:GetLeg()

	racer:ApplyShape(SHAPE_B, false)
	local pairAfter = racer:GetLegPair()
	assert(pairAfter == pairBefore, "redraw must preserve CR2 pair")
	assert(pairAfter:GetLeftDrive() == leftDriveBefore, "redraw replaced LeftDrive")
	assert(pairAfter:GetRightDrive() == rightDriveBefore, "redraw replaced RightDrive")
	assert(pairAfter:GetLeftDrive():GetJoint() == leftJointBefore, "redraw replaced left DriveJoint")
	assert(pairAfter:GetRightDrive():GetJoint() == rightJointBefore, "redraw replaced right DriveJoint")
	assert(pairAfter:GetLeftLeg() == leftLegBefore and pairAfter:GetRightLeg() == rightLegBefore, "redraw replaced persistent leg owners")
	assertStructuralPair(racer)

	racer:Destroy()
	print("[DrawRacers][B09] CR2 twin-drive same-shape/opposed-phase tests PASS")
end

return B09TwoLegPhaseSpec
