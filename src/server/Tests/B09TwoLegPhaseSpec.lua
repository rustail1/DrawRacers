--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B09TwoLegPhaseSpec = {}

local SHAPE_A = {
	Vector2.new(0, 0),
	Vector2.new(0.45, 0.75),
	Vector2.new(0.92, 0.10),
	Vector2.new(0.30, -0.82),
}

local SHAPE_B = {
	Vector2.new(0, 0),
	Vector2.new(0.20, 0.92),
	Vector2.new(0.88, 0.40),
	Vector2.new(0.72, -0.60),
	Vector2.new(-0.05, -0.82),
}

local function angularDistanceDegrees(a: number, b: number): number
	local delta = (a - b + 180) % 360 - 180
	return math.abs(delta)
end

local function localZDegrees(parent: CFrame, child: CFrame): number
	local relative = parent:ToObjectSpace(child)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
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
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

local function assertStructuralPair(racer: any)
	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B09 shared leg pair missing")
	local left = pair:GetLeftLeg()
	local right = pair:GetRightLeg()
	assertSamePoints(left:GetMappedPoints(), right:GetMappedPoints())

	local axleRoot = pair:GetRoot()
	local leftPhase = localZDegrees(axleRoot.CFrame, left:GetRoot().CFrame)
	local rightPhase = localZDegrees(axleRoot.CFrame, right:GetRoot().CFrame)
	local structuralDifference = (rightPhase - leftPhase + 360) % 360
	assert(
		angularDistanceDegrees(structuralDifference, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 0.1,
		string.format("opposed structural difference expected 180 got %.4f", structuralDifference)
	)

	local geometry = PhysicsConfig.LegGeometry
	local leftSocketLocal = axleRoot.CFrame:PointToObjectSpace(left:GetRoot().Position)
	local rightSocketLocal = axleRoot.CFrame:PointToObjectSpace(right:GetRoot().Position)
	assert(math.abs(leftSocketLocal.Z + geometry.LegSocketZAbs) <= 1e-4, "left side must mount on negative cube socket")
	assert(math.abs(rightSocketLocal.Z - geometry.LegSocketZAbs) <= 1e-4, "right side must mount on positive cube socket")

	local joint = pair:GetJoint()
	assert(joint.Name == "AxleJoint", "shared motor must be AxleJoint")
	assert(joint.ActuatorType == Enum.ActuatorType.Motor)
	assert(joint.AngularVelocity == PhysicsConfig.Motor.AngularVelocity)
	assert(countHinges(racer:GetModel()) == 1, "two opposed rigid sides must share exactly one HingeConstraint")
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

	-- Redraw preserves the one live axle phase. Both depth-separated sides keep
	-- their fixed 180-degree relation; there is no independent right motor to recover or drift.
	local pairBefore = racer:GetLegPair()
	local axleBefore = pairBefore:GetRoot()
	local geometry = PhysicsConfig.LegGeometry
	local base = body.CFrame * CFrame.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)
	axleBefore.CFrame = base * CFrame.Angles(0, 0, math.rad(37))
	local phaseBefore = pairBefore:GetPhaseDegrees()
	assert(angularDistanceDegrees(phaseBefore, 37) <= 0.1, "B09 fixture failed to set axle phase")

	racer:ApplyShape(SHAPE_B, false)
	local pairAfter = racer:GetLegPair()
	assert(pairAfter ~= pairBefore, "redraw must replace shared pair")
	local phaseAfter = pairAfter:GetPhaseDegrees()
	assert(angularDistanceDegrees(phaseAfter, phaseBefore) <= 0.1, "redraw must preserve the single axle phase")
	assertStructuralPair(racer)

	racer:Destroy()
	print("[DrawRacers][B09] two-leg same-XY/opposed-phase tests PASS")
end

return B09TwoLegPhaseSpec
