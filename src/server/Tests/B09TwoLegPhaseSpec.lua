--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B09TwoLegPhaseSpec = {}

local ASYM_01 = {
	Vector2.new(-0.82, -0.18),
	Vector2.new(-0.30, -0.52),
	Vector2.new(0.18, -0.26),
	Vector2.new(0.76, 0.08),
	Vector2.new(0.34, 0.58),
	Vector2.new(-0.18, 0.82),
	Vector2.new(-0.52, 0.30),
}

local function assertClose(actual: number, expected: number, epsilon: number, message: string)
	assert(math.abs(actual - expected) <= epsilon, string.format("%s: expected %.6f got %.6f", message, expected, actual))
end

local function angularDistanceDegrees(a: number, b: number): number
	local delta = (a - b + 180) % 360 - 180
	return math.abs(delta)
end

local function assertSamePoints(a: { Vector2 }, b: { Vector2 })
	assert(#a == #b, string.format("mapped point counts differ %d ~= %d", #a, #b))
	for index = 1, #a do
		assertClose(a[index].X, b[index].X, 1e-6, string.format("mapped point %d X", index))
		assertClose(a[index].Y, b[index].Y, 1e-6, string.format("mapped point %d Y", index))
	end
end

local function phaseDegrees(hub: Part, root: Part): number
	local relative = hub.CFrame:ToObjectSpace(root.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
end

function B09TwoLegPhaseSpec.run()
	local racer = RacerRuntime.new({
		raceId = "B09_TEST",
		slotIndex = 2,
		laneIndex = 2,
		isBot = true,
		trackId = "B09_FLAT",
		spawnCFrame = CFrame.new(8, 8, 0),
	})

	local success, failure = xpcall(function()
		local leftLeg, rightLeg = racer:ApplyShape(ASYM_01, false)
		local model = racer:GetModel()
		local body = racer:GetBody()
		body.Anchored = true
		local leftModel = model.Legs:FindFirstChild("LeftLeg")
		local rightModel = model.Legs:FindFirstChild("RightLeg")
		assert(leftModel and leftModel:IsA("Model"), "B09 missing LeftLeg")
		assert(rightModel and rightModel:IsA("Model"), "B09 missing RightLeg")
		assert(#leftLeg:GetSegments() == #rightLeg:GetSegments(), "left/right segment counts differ")
		assertSamePoints(leftLeg:GetMappedPoints(), rightLeg:GetMappedPoints())

		local leftHub = model:FindFirstChild("LeftHub")
		local rightHub = model:FindFirstChild("RightHub")
		assert(leftHub and leftHub:IsA("Part"), "missing LeftHub")
		assert(rightHub and rightHub:IsA("Part"), "missing RightHub")
		assert((leftLeg:GetRoot().Position - leftHub.Position).Magnitude <= 1e-4, "LeftLeg root not at LeftHub")
		assert((rightLeg:GetRoot().Position - rightHub.Position).Magnitude <= 1e-4, "RightLeg root not at RightHub")

		local leftJoint = leftLeg:GetJoint()
		local rightJoint = rightLeg:GetJoint()
		assert(leftJoint.Attachment0 == leftHub:FindFirstChild("MotorAttachment"), "LeftLeg hinge not bound to LeftHub")
		assert(rightJoint.Attachment0 == rightHub:FindFirstChild("MotorAttachment"), "RightLeg hinge not bound to RightHub")
		assert(leftJoint.ActuatorType == Enum.ActuatorType.Motor)
		assert(rightJoint.ActuatorType == Enum.ActuatorType.Motor)
		assert(leftJoint.AngularVelocity == PhysicsConfig.Motor.AngularVelocity)
		assert(rightJoint.AngularVelocity == PhysicsConfig.Motor.AngularVelocity)
		assert(leftJoint.AngularVelocity == rightJoint.AngularVelocity, "both leg motors must use the same direction/sign")
		assert(leftJoint.MotorMaxTorque == rightJoint.MotorMaxTorque)
		assert(leftJoint.MotorMaxAcceleration == rightJoint.MotorMaxAcceleration)
		assert(leftHub.MotorAttachment.Axis == Vector3.zAxis, "LeftHub hinge axis must be +Z")
		assert(rightHub.MotorAttachment.Axis == Vector3.zAxis, "RightHub hinge axis must be +Z")

		local leftPhaseDegrees = phaseDegrees(leftHub, leftLeg:GetRoot())
		local rightPhaseDegrees = phaseDegrees(rightHub, rightLeg:GetRoot())
		local phaseDifference = (rightPhaseDegrees - leftPhaseDegrees + 360) % 360
		assertClose(leftPhaseDegrees, 0, 0.1, "left initial phase")
		assert(
			angularDistanceDegrees(phaseDifference, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 1.0,
			string.format(
				"phase difference expected %.3f got %.3f",
				PhysicsConfig.Motor.RightPhaseOffsetDegrees,
				phaseDifference
			)
		)

		-- Enable the hinges before injecting the synthetic pose. Enabling a Roblox
		-- constraint may immediately reconcile its assembly, so writing the pose
		-- first makes the intended 90-degree RED setup nondeterministic in Studio.
		leftJoint.Enabled = true
		rightJoint.Enabled = true
		leftLeg:GetRoot().CFrame = leftHub.CFrame * CFrame.Angles(0, 0, math.rad(15))
		rightLeg:GetRoot().CFrame = rightHub.CFrame * CFrame.Angles(0, 0, math.rad(105))

		local injectedDifference = (phaseDegrees(rightHub, rightLeg:GetRoot()) - phaseDegrees(leftHub, leftLeg:GetRoot()) + 360) % 360
		assert(
			angularDistanceDegrees(injectedDifference, 90) <= 1.0,
			string.format("B09 drift fixture expected 90 degrees got %.3f", injectedDifference)
		)

		racer:_StepLegPhaseSync()

		local baseVelocity = PhysicsConfig.Motor.AngularVelocity
		assert(
			leftJoint.AngularVelocity * baseVelocity > 0 and rightJoint.AngularVelocity * baseVelocity > 0,
			"phase lock correction must keep both motors in canonical locomotion direction"
		)
		assertClose(
			(leftJoint.AngularVelocity + rightJoint.AngularVelocity) * 0.5,
			baseVelocity,
			1e-6,
			"phase lock must preserve average motor speed"
		)
		assert(rightJoint.AngularVelocity > leftJoint.AngularVelocity, "90-degree drift must command right leg to catch up")

		-- At canonical anti-phase the correction disappears and both motors return
		-- exactly to the shared configured speed. Keep the joints enabled and inject
		-- the pose immediately before sampling for the same deterministic reason.
		leftLeg:GetRoot().CFrame = leftHub.CFrame * CFrame.Angles(0, 0, math.rad(15))
		rightLeg:GetRoot().CFrame = rightHub.CFrame * CFrame.Angles(0, 0, math.rad(195))
		local canonicalDifference = (phaseDegrees(rightHub, rightLeg:GetRoot()) - phaseDegrees(leftHub, leftLeg:GetRoot()) + 360) % 360
		assert(
			angularDistanceDegrees(canonicalDifference, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 1.0,
			string.format("B09 canonical fixture expected 180 degrees got %.3f", canonicalDifference)
		)
		racer:_StepLegPhaseSync()
		local phaseDifferenceAfterSync = (phaseDegrees(rightHub, rightLeg:GetRoot()) - phaseDegrees(leftHub, leftLeg:GetRoot()) + 360) % 360
		assert(
			angularDistanceDegrees(phaseDifferenceAfterSync, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 1.0,
			"phase difference after sync must be canonical"
		)
		assertClose(leftJoint.AngularVelocity, baseVelocity, 1e-6, "left canonical phase speed")
		assertClose(rightJoint.AngularVelocity, baseVelocity, 1e-6, "right canonical phase speed")
	end, debug.traceback)

	-- Always remove the synthetic racer. A failed Studio assertion must not leave
	-- floating B09 leg geometry in Workspace and confuse the following G0 check.
	racer:Destroy()
	assert(success, failure)
	print("[DrawRacers][B09] two-leg same-XY/phase tests PASS")
end

return B09TwoLegPhaseSpec
