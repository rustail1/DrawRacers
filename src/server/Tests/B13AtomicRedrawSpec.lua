--!strict

local LegAssembly = require(script.Parent.Parent.Runtime:WaitForChild("LegAssembly"))
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

local function phaseDegrees(hub: Part, root: Part): number
	local relative = hub.CFrame:ToObjectSpace(root.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
end

local function angularDistanceDegrees(a: number, b: number): number
	local delta = (a - b + 180) % 360 - 180
	return math.abs(delta)
end

local function countLegModels(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("Model") then
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
	local leftHub = model:FindFirstChild("LeftHub")
	local rightHub = model:FindFirstChild("RightHub")
	assert(legsFolder and legsFolder:IsA("Folder"))
	assert(leftHub and leftHub:IsA("Part"))
	assert(rightHub and rightHub:IsA("Part"))

	local first = LegShapeService.ValidateAndBuild(racer, FIRST_SHAPE, false)
	assert(first.accepted == true and first.shapeVersion == 1, "B13 setup shape failed")

	local oldLeftModel = legsFolder:FindFirstChild("LeftLeg")
	local oldRightModel = legsFolder:FindFirstChild("RightLeg")
	assert(oldLeftModel and oldLeftModel:IsA("Model"))
	assert(oldRightModel and oldRightModel:IsA("Model"))
	local oldLeftRoot = oldLeftModel:FindFirstChild("LegRoot")
	local oldRightRoot = oldRightModel:FindFirstChild("LegRoot")
	assert(oldLeftRoot and oldLeftRoot:IsA("Part"))
	assert(oldRightRoot and oldRightRoot:IsA("Part"))

	-- Put the currently working pair at a non-default phase so redraw must preserve actual phase,
	-- not merely recreate launch 0/180 defaults.
	oldLeftRoot.CFrame = leftHub.CFrame * CFrame.Angles(0, 0, math.rad(37))
	oldRightRoot.CFrame = rightHub.CFrame * CFrame.Angles(0, 0, math.rad(-143))
	local leftPhaseBefore = phaseDegrees(leftHub, oldLeftRoot)
	local rightPhaseBefore = phaseDegrees(rightHub, oldRightRoot)

	body.AssemblyLinearVelocity = Vector3.new(11.25, 1.5, -0.35)
	body.AssemblyAngularVelocity = Vector3.new(0.2, -0.15, 0.4)
	local bodyCFrameBefore = body.CFrame
	local linearBefore = body.AssemblyLinearVelocity
	local angularBefore = body.AssemblyAngularVelocity

	-- Force the second staged leg build to fail. The old working pair must survive intact.
	local originalNew = LegAssembly.new
	local buildCount = 0
	LegAssembly.new = function(params: any)
		buildCount += 1
		if buildCount == 2 then
			error("B13 injected right-leg build failure")
		end
		return originalNew(params)
	end

	local failed = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	LegAssembly.new = originalNew

	assert(failed.accepted == false and failed.rejectReasonCode == "BUILD_FAILED", "injected redraw failure must fail closed")
	assert(racer:GetShapeVersion() == 1, "BUILD_FAILED changed ShapeVersion")
	assert(legsFolder:FindFirstChild("LeftLeg") == oldLeftModel, "old LeftLeg changed after failed redraw")
	assert(legsFolder:FindFirstChild("RightLeg") == oldRightModel, "old RightLeg changed after failed redraw")
	assert(countLegModels(legsFolder) == 2, "failed redraw leaked staged leg models")
	assert(body.CFrame == bodyCFrameBefore, "failed redraw teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "failed redraw reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "failed redraw reset AssemblyAngularVelocity")

	-- Force the second commit to fail after the first staged leg has already committed. The
	-- transaction must roll back both staged legs and restore the exact old pair/names.
	local originalCommit = LegAssembly.Commit
	local commitCount = 0
	LegAssembly.Commit = function(self: any)
		commitCount += 1
		if commitCount == 2 then
			error("B13 injected right-leg commit failure")
		end
		return originalCommit(self)
	end

	local commitFailed = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	LegAssembly.Commit = originalCommit

	assert(commitFailed.accepted == false and commitFailed.rejectReasonCode == "BUILD_FAILED", "commit failure must fail closed")
	assert(racer:GetShapeVersion() == 1, "commit failure changed ShapeVersion")
	assert(legsFolder:FindFirstChild("LeftLeg") == oldLeftModel, "old LeftLeg not restored after commit failure")
	assert(legsFolder:FindFirstChild("RightLeg") == oldRightModel, "old RightLeg not restored after commit failure")
	assert(legsFolder:FindFirstChild("LeftLeg_Retiring") == nil, "LeftLeg_Retiring leaked after rollback")
	assert(legsFolder:FindFirstChild("RightLeg_Retiring") == nil, "RightLeg_Retiring leaked after rollback")
	assert(countLegModels(legsFolder) == 2, "commit failure leaked staged leg models")
	assert(body.CFrame == bodyCFrameBefore, "commit failure teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "commit failure reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "commit failure reset AssemblyAngularVelocity")

	-- Force an error only after both staged legs have committed and both motor-enable calls
	-- have run. Rollback must still remove the fully-parented staged pair and restore the old
	-- accepted assembly without advancing ShapeVersion or disturbing racer motion.
	local originalSetEnabled = LegAssembly.SetEnabled
	local enableCount = 0
	LegAssembly.SetEnabled = function(self: any, enabled: boolean)
		enableCount += 1
		originalSetEnabled(self, enabled)
		if enableCount == 2 then
			error("B13 injected post-enable failure")
		end
	end

	local enableFailed = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, true)
	LegAssembly.SetEnabled = originalSetEnabled

	assert(enableFailed.accepted == false and enableFailed.rejectReasonCode == "BUILD_FAILED", "enable failure must fail closed")
	assert(racer:GetShapeVersion() == 1, "enable failure changed ShapeVersion")
	assert(legsFolder:FindFirstChild("LeftLeg") == oldLeftModel, "old LeftLeg not restored after enable failure")
	assert(legsFolder:FindFirstChild("RightLeg") == oldRightModel, "old RightLeg not restored after enable failure")
	assert(legsFolder:FindFirstChild("LeftLeg_Retiring") == nil, "LeftLeg_Retiring leaked after enable rollback")
	assert(legsFolder:FindFirstChild("RightLeg_Retiring") == nil, "RightLeg_Retiring leaked after enable rollback")
	assert(countLegModels(legsFolder) == 2, "enable failure leaked staged leg models")
	assert(body.CFrame == bodyCFrameBefore, "enable failure teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "enable failure reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "enable failure reset AssemblyAngularVelocity")

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	assert(second.accepted == true and second.shapeVersion == 2, "valid B13 redraw must accept exactly once")
	assert(racer:GetShapeVersion() == 2)
	local newLeftModel = legsFolder:FindFirstChild("LeftLeg")
	local newRightModel = legsFolder:FindFirstChild("RightLeg")
	assert(newLeftModel and newLeftModel:IsA("Model") and newLeftModel ~= oldLeftModel)
	assert(newRightModel and newRightModel:IsA("Model") and newRightModel ~= oldRightModel)
	assert(oldLeftModel.Parent == nil and oldRightModel.Parent == nil, "retired legs were not destroyed after commit")
	assert(countLegModels(legsFolder) == 2, "successful atomic redraw must leave exactly two leg models")
	assert(body.CFrame == bodyCFrameBefore, "successful redraw teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "successful redraw reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "successful redraw reset AssemblyAngularVelocity")

	local newLeftRoot = newLeftModel:FindFirstChild("LegRoot")
	local newRightRoot = newRightModel:FindFirstChild("LegRoot")
	assert(newLeftRoot and newLeftRoot:IsA("Part"))
	assert(newRightRoot and newRightRoot:IsA("Part"))
	local leftPhaseAfter = phaseDegrees(leftHub, newLeftRoot)
	local rightPhaseAfter = phaseDegrees(rightHub, newRightRoot)
	assert(angularDistanceDegrees(leftPhaseAfter, leftPhaseBefore) < 0.5, "left rotation phase was not preserved")
	assert(angularDistanceDegrees(rightPhaseAfter, rightPhaseBefore) < 0.5, "right rotation phase was not preserved")

	racer:Destroy()
	print("[DrawRacers][B13] atomic redraw tests PASS")
end

return B13AtomicRedrawSpec
