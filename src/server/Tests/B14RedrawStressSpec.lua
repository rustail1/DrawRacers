--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B14RedrawStressSpec = {}

local TEST_PLAYER = {}
local MOVING_TEST_PLAYER = {}
local MAX_PHYSICAL_LEG_PARTS = 2 * (PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg + 1)
local MAX_VISUAL_LEG_PARTS = 2
	* (PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg + PhysicsConfig.StrokeProcessing.MaxCleanedPoints)

local function payload(sequence: number, points: { any })
	return { sequence = sequence, points = points }
end

local function shapeA(sequence: number)
	return payload(sequence, {
		{ x = 0, y = 0 },
		{ x = -0.18, y = 0.78 },
		{ x = 0.58, y = 0.54 },
		{ x = 0.82, y = -0.22 },
		{ x = 0.04, y = -0.82 },
	})
end

local function shapeB(sequence: number)
	return payload(sequence, {
		{ x = 0, y = 0 },
		{ x = -0.44, y = 0.66 },
		{ x = 0.16, y = 0.90 },
		{ x = 0.76, y = 0.30 },
		{ x = 0.46, y = -0.72 },
		{ x = -0.36, y = -0.70 },
	})
end

local function countLegModels(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("Model") and (child.Name == "LeftDrive" or child.Name == "RightDrive") then count += 1 end
	end
	return count
end

local function countPhysicalLegParts(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("BasePart") and (descendant.Name == "LegRoot" or string.match(descendant.Name, "^Segment_%d+$")) then
			count += 1
		end
	end
	return count
end

local function countVisualLegParts(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("BasePart") and (string.match(descendant.Name, "^VisualSegment_%d+$") or string.match(descendant.Name, "^VisualJoint_%d+$")) then
			count += 1
		end
	end
	return count
end

local function countHinges(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("HingeConstraint") then count += 1 end
	end
	return count
end

local function assertLegPartBounds(legsFolder: Folder, context: string)
	assert(countPhysicalLegParts(legsFolder) <= MAX_PHYSICAL_LEG_PARTS, context .. " leaked physical parts")
	assert(countVisualLegParts(legsFolder) <= MAX_VISUAL_LEG_PARTS, context .. " leaked visual parts")
	assert(countHinges(legsFolder) == 2, context .. " must keep exactly two DriveJoint hinges")
end

local function assertNoPending(legsFolder: Folder, context: string)
	for _, descendant in legsFolder:GetDescendants() do
		assert(descendant.Name ~= "StageVisual", context .. " leaked StageVisual")
		assert(descendant.Name ~= "PendingSegments", context .. " leaked PendingSegments")
		assert(descendant.Name ~= "PendingVisual", context .. " leaked PendingVisual")
	end
end

local function assertCurrentShapeIntact(racer: any, legsFolder: Folder, version: number, leftDrive: Instance, rightDrive: Instance)
	assert(racer:GetShapeVersion() == version, "rejected request changed valid current shape version")
	assert(legsFolder:FindFirstChild("LeftDrive") == leftDrive, "rejected request removed valid current shape LeftDrive")
	assert(legsFolder:FindFirstChild("RightDrive") == rightDrive, "rejected request removed valid current shape RightDrive")
	assert(countLegModels(legsFolder) == 2, "rejected request leaked leg models")
	assertLegPartBounds(legsFolder, "rejected request")
	assertNoPending(legsFolder, "rejected request")
end

local function makeProcessor(racer: any, playerKey: any, nowRef: { value: number })
	return LegShapeService.CreateSubmitProcessor({
		resolveRacer = function(key)
			if key == playerKey then return racer end
			return nil
		end,
		now = function() return nowRef.value end,
	})
end

local function runMovingRedrawParity()
	local movingRacer = RacerRuntime.new({
		raceId = "R16_8_MOVING_REDRAW",
		slotIndex = 8,
		laneIndex = 8,
		isBot = false,
		trackId = "R16_8_FLAT",
		spawnCFrame = CFrame.new(44, 12, 0),
		laneCenterZ = 0,
	})
	local legsFolder = movingRacer:GetModel():FindFirstChild("Legs") :: Folder
	local nowRef = { value = 500.0 }
	local processor = makeProcessor(movingRacer, MOVING_TEST_PLAYER, nowRef)
	local seeded = processor:Handle(MOVING_TEST_PLAYER, shapeA(2000))
	assert(seeded ~= nil and seeded.accepted == true and seeded.shapeVersion == 1, "moving seed must accept")

	local expectedVersion = 1
	for redrawIndex = 1, 10 do
		local pairBeforeRedraw = movingRacer:GetLegPair()
		assert(pairBeforeRedraw ~= nil, "moving redraw missing pair before redraw")
		local leftDriveBefore = pairBeforeRedraw:GetLeftDrive()
		local rightDriveBefore = pairBeforeRedraw:GetRightDrive()
		local leftJointBefore = leftDriveBefore:GetJoint()
		local rightJointBefore = rightDriveBefore:GetJoint()
		nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
		local sequence = 2000 + redrawIndex
		local nextPayload = if redrawIndex % 2 == 0 then shapeA(sequence) else shapeB(sequence)
		local result = processor:Handle(MOVING_TEST_PLAYER, nextPayload)
		assert(result ~= nil and result.accepted == true, "moving redraw must accept")
		expectedVersion += 1
		assert(result.shapeVersion == expectedVersion and movingRacer:GetShapeVersion() == expectedVersion)
		local pairAfterRedraw = movingRacer:GetLegPair()
		assert(pairAfterRedraw == pairBeforeRedraw, "moving redraw must preserve stable pair")
		assert(pairAfterRedraw:GetLeftDrive() == leftDriveBefore and pairAfterRedraw:GetRightDrive() == rightDriveBefore, "moving redraw replaced drives")
		assert(leftDriveBefore:GetJoint() == leftJointBefore and rightDriveBefore:GetJoint() == rightJointBefore, "moving redraw replaced joints")
		assert(countLegModels(legsFolder) == 2, "moving redraw must leave exactly two drive models")
		assertLegPartBounds(legsFolder, "moving redraw")
		assertNoPending(legsFolder, "moving redraw")
	end
	movingRacer:Destroy()
end

function B14RedrawStressSpec.run()
	local racer = RacerRuntime.new({
		raceId = "B14_TEST",
		slotIndex = 7,
		laneIndex = 7,
		isBot = false,
		trackId = "B14_FLAT",
		spawnCFrame = CFrame.new(28, 10, 0),
		laneCenterZ = 0,
	})
	racer:GetBody().Anchored = true
	local legsFolder = racer:GetModel():FindFirstChild("Legs") :: Folder
	local nowRef = { value = 100.0 }
	local processor = makeProcessor(racer, TEST_PLAYER, nowRef)

	local seeded = processor:Handle(TEST_PLAYER, shapeA(1))
	assert(seeded ~= nil and seeded.accepted == true and seeded.shapeVersion == 1, "B14 seed shape must accept")
	local leftDrive = legsFolder:FindFirstChild("LeftDrive")
	local rightDrive = legsFolder:FindFirstChild("RightDrive")
	assert(leftDrive ~= nil and rightDrive ~= nil, "B14 seed must create a valid current shape")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	nowRef.value = 100.05
	local rateLimited = processor:Handle(TEST_PLAYER, shapeB(2))
	assert(rateLimited ~= nil and rateLimited.accepted == false and rateLimited.rejectReasonCode == "RATE_LIMITED")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	local stale = processor:Handle(TEST_PLAYER, shapeB(1))
	assert(stale ~= nil and stale.accepted == false and stale.rejectReasonCode == "STALE_SEQUENCE")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local malformed = processor:Handle(TEST_PLAYER, payload(3, {{ x = 0, y = 0 }, "not-a-point", { x = 0.4, y = 0 }}))
	assert(malformed ~= nil and malformed.accepted == false and malformed.rejectReasonCode == "MALFORMED_POINTS")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local nonFinite = processor:Handle(TEST_PLAYER, payload(4, {{ x = 0, y = 0 }, { x = math.huge, y = 0.2 }, { x = 0.4, y = 0 }}))
	assert(nonFinite ~= nil and nonFinite.accepted == false and nonFinite.rejectReasonCode == "NON_FINITE_POINT")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	local tooManyPoints = table.create(PhysicsConfig.StrokeProcessing.MaxRawPoints + 1)
	for index = 1, PhysicsConfig.StrokeProcessing.MaxRawPoints + 1 do tooManyPoints[index] = { x = index / 1000, y = 0 } end
	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local tooMany = processor:Handle(TEST_PLAYER, payload(5, tooManyPoints))
	assert(tooMany ~= nil and tooMany.accepted == false and tooMany.rejectReasonCode == "TOO_MANY_POINTS")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	local oversizedPoints = table.create(PhysicsConfig.StrokeProcessing.MaxRawPoints)
	for index = 1, PhysicsConfig.StrokeProcessing.MaxRawPoints do oversizedPoints[index] = { x = 1.234567890123456e300, y = -9.876543210987654e299 } end
	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local oversized = processor:Handle(TEST_PLAYER, payload(6, oversizedPoints))
	assert(oversized ~= nil and oversized.accepted == false and oversized.rejectReasonCode == "PAYLOAD_TOO_LARGE")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftDrive, rightDrive)

	local acceptedVersion = 1
	for attempt = 1, 40 do
		nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
		local sequence = 10 + attempt
		local nextPayload = if attempt % 2 == 0 then shapeA(sequence) else shapeB(sequence)
		local result = processor:Handle(TEST_PLAYER, nextPayload)
		assert(result ~= nil and result.accepted == true, "stress redraw must accept legal shape")
		acceptedVersion += 1
		assert(result.shapeVersion == acceptedVersion and racer:GetShapeVersion() == acceptedVersion, "stress redraw version drift")
		assert(countLegModels(legsFolder) == 2, "stress redraw: no leaked leg models")
		assertLegPartBounds(legsFolder, "stress redraw")
		assertNoPending(legsFolder, "stress redraw")
	end

	for attempt = 1, 50 do
		local sequence = 1000 + attempt
		local spam = processor:Handle(TEST_PLAYER, shapeA(sequence))
		assert(spam ~= nil and spam.accepted == false and spam.rejectReasonCode == "RATE_LIMITED", "burst spam must rate-limit")
	end
	assert(racer:GetShapeVersion() == acceptedVersion, "rate-limit burst mutated valid current shape")
	assertCurrentShapeIntact(racer, legsFolder, acceptedVersion, leftDrive, rightDrive)

	runMovingRedrawParity()
	racer:Destroy()
	print("[DrawRacers][B14] CR2 redraw abuse/stress tests PASS")
end

return B14RedrawStressSpec
