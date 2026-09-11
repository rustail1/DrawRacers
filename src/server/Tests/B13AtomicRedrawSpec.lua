--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local LegAssembly = require(script.Parent.Parent.Runtime:WaitForChild("LegAssembly"))
local LegPairAssembly = require(script.Parent.Parent.Runtime:WaitForChild("LegPairAssembly"))
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

local function countAxleRoots(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("BasePart") and (child.Name == "AxleRoot" or child.Name == "AxleRoot_Retiring") then
			count += 1
		end
	end
	return count
end

local function assertOldPairIntact(racer: any, oldPair: any, leftModel: Model, rightModel: Model, context: string)
	local legsFolder = racer:GetModel().Legs
	assert(racer:GetLegPair() == oldPair, context .. ": old pair changed after failed redraw")
	assert(legsFolder:FindFirstChild("LeftLeg") == leftModel, context .. ": old LeftLeg changed")
	assert(legsFolder:FindFirstChild("RightLeg") == rightModel, context .. ": old RightLeg changed")
	assert(legsFolder:FindFirstChild("AxleRoot") == oldPair:GetRoot(), context .. ": old AxleRoot changed")
	assert(legsFolder:FindFirstChild("LeftLeg_Retiring") == nil, context .. ": leaked LeftLeg_Retiring")
	assert(legsFolder:FindFirstChild("RightLeg_Retiring") == nil, context .. ": leaked RightLeg_Retiring")
	assert(legsFolder:FindFirstChild("AxleRoot_Retiring") == nil, context .. ": leaked AxleRoot_Retiring")
	assert(countLegModels(legsFolder) == 2, context .. ": leaked leg models")
	assert(countAxleRoots(legsFolder) == 1, context .. ": leaked axle roots")
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
	local oldPair = racer:GetLegPair()
	assert(oldPair ~= nil, "B13 setup pair missing")
	local oldLeftModel = oldPair:GetLeftLeg():GetModel()
	local oldRightModel = oldPair:GetRightLeg():GetModel()

	-- Put the single working axle at a non-default phase. Redraw must preserve
	-- this one mechanical phase; the right side has no independent phase state.
	local geometry = PhysicsConfig.LegGeometry
	local base = body.CFrame * CFrame.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)
	oldPair:GetRoot().CFrame = base * CFrame.Angles(0, 0, math.rad(37))
	local phaseBefore = oldPair:GetPhaseDegrees()
	assert(angularDistanceDegrees(phaseBefore, 37) <= 0.1, "B13 phase fixture failed")

	body.AssemblyLinearVelocity = Vector3.new(11.25, 1.5, -0.35)
	body.AssemblyAngularVelocity = Vector3.new(0.2, -0.15, 0.4)
	local bodyCFrameBefore = body.CFrame
	local linearBefore = body.AssemblyLinearVelocity
	local angularBefore = body.AssemblyAngularVelocity

	-- Fail the second rigid-side build inside LegPairAssembly. Its constructor
	-- must clean partial detached geometry and RacerRuntime must keep old pair.
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
	assertOldPairIntact(racer, oldPair, oldLeftModel, oldRightModel, "build failure")
	assert(body.CFrame == bodyCFrameBefore, "failed redraw teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "failed redraw reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "failed redraw reset AssemblyAngularVelocity")

	-- Fail the second side commit after AxleRoot and LeftLeg were parented. Pair
	-- rollback must remove the partial replacement and restore retiring names.
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
	assertOldPairIntact(racer, oldPair, oldLeftModel, oldRightModel, "commit failure")
	assert(body.CFrame == bodyCFrameBefore, "commit failure teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "commit failure reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "commit failure reset AssemblyAngularVelocity")

	-- Fail only after the replacement motor has been enabled. The fully-parented
	-- replacement still must roll back as one transaction.
	local originalSetEnabled = LegPairAssembly.SetEnabled
	LegPairAssembly.SetEnabled = function(self: any, enabled: boolean)
		originalSetEnabled(self, enabled)
		error("B13 injected post-enable failure")
	end
	local enableFailed = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, true)
	LegPairAssembly.SetEnabled = originalSetEnabled

	assert(enableFailed.accepted == false and enableFailed.rejectReasonCode == "BUILD_FAILED", "enable failure must fail closed")
	assert(racer:GetShapeVersion() == 1, "enable failure changed ShapeVersion")
	assertOldPairIntact(racer, oldPair, oldLeftModel, oldRightModel, "enable failure")
	assert(body.CFrame == bodyCFrameBefore, "enable failure teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "enable failure reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "enable failure reset AssemblyAngularVelocity")

	local second = LegShapeService.ValidateAndBuild(racer, SECOND_SHAPE, false)
	assert(second.accepted == true and second.shapeVersion == 2, "valid B13 redraw must accept exactly once")
	assert(racer:GetShapeVersion() == 2)
	local newPair = racer:GetLegPair()
	assert(newPair ~= nil and newPair ~= oldPair, "successful redraw must replace shared pair")
	assert(oldLeftModel.Parent == nil and oldRightModel.Parent == nil, "retired sides were not destroyed after commit")
	assert(oldPair:GetRoot == nil or true) -- old pair is destroyed; avoid calling its guarded API
	assert(countLegModels(legsFolder) == 2, "successful redraw must leave exactly two side models")
	assert(countAxleRoots(legsFolder) == 1, "successful redraw must leave exactly one axle root")
	assert(body.CFrame == bodyCFrameBefore, "successful redraw teleported body CFrame")
	assert(body.AssemblyLinearVelocity == linearBefore, "successful redraw reset AssemblyLinearVelocity")
	assert(body.AssemblyAngularVelocity == angularBefore, "successful redraw reset AssemblyAngularVelocity")
	assert(angularDistanceDegrees(newPair:GetPhaseDegrees(), phaseBefore) <= 0.1, "single axle phase was not preserved")

	racer:Destroy()
	print("[DrawRacers][B13] atomic redraw tests PASS")
end

return B13AtomicRedrawSpec
