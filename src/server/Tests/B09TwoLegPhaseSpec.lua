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

local function assertSamePoints(left: { Vector2 }, right: { Vector2 })
	assert(#left == #right, "two legs must share mapped point count")
	for index, point in left do
		assert(
			(point - right[index]).Magnitude <= 1e-6,
			string.format("mapped point %d differs between legs", index)
		)
	end
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

local function assertStructuralPair(racer: any)
	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B09 shared-drive pair missing")

	local drive = pair:GetDrive()
	local left = pair:GetLeftLeg()
	local right = pair:GetRightLeg()

	assertSamePoints(left:GetMappedPoints(), right:GetMappedPoints())

	local body = racer:GetBody()
	local leftLocal = body.CFrame:PointToObjectSpace(drive:GetLeftRoot().Position)
	local rightLocal = body.CFrame:PointToObjectSpace(drive:GetRightRoot().Position)
	local expectedZ = body.Size.Z * 0.5 + PhysicsConfig.LegGeometry.LegMountOutset

	assert(math.abs(leftLocal.Z + expectedZ) <= 1e-3, "left root must sit outside -Z cube face")
	assert(math.abs(rightLocal.Z - expectedZ) <= 1e-3, "right root must sit outside +Z cube face")
	assert(math.abs(leftLocal.X) <= 1e-3 and math.abs(rightLocal.X) <= 1e-3, "side roots must not shift forward/back")
	assert(math.abs(pair:GetPhaseErrorDegrees()) <= 1e-6, "rigid shared axle must have zero pair drift")

	local leftRightDot = drive:GetLeftRoot().CFrame.RightVector:Dot(
		drive:GetRightRoot().CFrame.RightVector
	)
	assert(leftRightDot <= -0.999, "right root must be rigidly opposed by 180 degrees")

	local joint = drive:GetJoint()
	assert(joint.Name == "DriveJoint")
	assert(joint.ActuatorType == Enum.ActuatorType.Motor)
	assert(countHinges(racer:GetModel()) == 1, "shared pair must own exactly one HingeConstraint")
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
	assert(pairBefore ~= nil)
	local driveBefore = pairBefore:GetDrive()
	local jointBefore = driveBefore:GetJoint()
	local leftLegBefore = pairBefore:GetLeftLeg()
	local rightLegBefore = pairBefore:GetRightLeg()

	racer:ApplyShape(SHAPE_B, false)

	local pairAfter = racer:GetLegPair()
	assert(pairAfter == pairBefore, "redraw replaced persistent pair")
	assert(pairAfter:GetDrive() == driveBefore, "redraw replaced SharedLegDrive")
	assert(pairAfter:GetDrive():GetJoint() == jointBefore, "redraw replaced DriveJoint")
	assert(pairAfter:GetLeftLeg() == leftLegBefore, "redraw replaced left leg owner")
	assert(pairAfter:GetRightLeg() == rightLegBefore, "redraw replaced right leg owner")
	assertStructuralPair(racer)

	racer:Destroy()
	print("[DrawRacers][B09] shared-axle fixed-phase tests PASS")
end

return B09TwoLegPhaseSpec
