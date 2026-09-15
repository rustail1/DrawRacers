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

local MAX_PHYSICAL_LEG_PARTS =
	2 * (PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg + 1)
local MAX_VISUAL_LEG_PARTS =
	2 * (
		PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg
		+ PhysicsConfig.StrokeProcessing.MaxCleanedPoints
	)

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

local function countSharedDriveModels(legsFolder: Folder): number
	local count = 0
	for _, child in legsFolder:GetChildren() do
		if child:IsA("Model") and child.Name == "SharedLegDrive" then
			count += 1
		end
	end
	return count
end

local function countPhysicalLegParts(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("BasePart")
			and (
				descendant.Name == "LegRoot"
				or string.match(descendant.Name, "^Segment_%d+$")
			)
		then
			count += 1
		end
	end
	return count
end

local function countVisualLegParts(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("BasePart")
			and (
				string.match(descendant.Name, "^VisualSegment_%d+$")
				or string.match(descendant.Name, "^VisualJoint_%d+$")
			)
		then
			count += 1
		end
	end
	return count
end

local function countHinges(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

local function assertLegPartBounds(legsFolder: Folder, context: string)
	assert(
		countPhysicalLegParts(legsFolder) <= MAX_PHYSICAL_LEG_PARTS,
		context .. " leaked physical parts"
	)
	assert(
		countVisualLegParts(legsFolder) <= MAX_VISUAL_LEG_PARTS,
		context .. " leaked visual parts"
	)
	assert(countHinges(legsFolder) == 1, context .. " must keep one DriveJoint")
end

local function assertNoTransient(legsFolder: Folder, context: string)
	for _, descendant in legsFolder:GetDescendants() do
		assert(descendant.Name ~= "Preview", context .. " leaked Preview")
		assert(descendant.Name ~= "BuildSegments", context .. " leaked BuildSegments")
		assert(descendant.Name ~= "BuildVisual", context .. " leaked BuildVisual")
	end
end

local function assertCurrentShapeIntact(
	racer: any,
	legsFolder: Folder,
	version: number,
	drive: Instance
)
	assert(racer:GetShapeVersion() == version, "rejected request changed current shape version")
	assert(
		legsFolder:FindFirstChild("SharedLegDrive") == drive,
		"rejected request replaced SharedLegDrive"
	)
	assert(countSharedDriveModels(legsFolder) == 1, "rejected request leaked drive models")
	assertLegPartBounds(legsFolder, "rejected request")
	assertNoTransient(legsFolder, "rejected request")
end

local function makeProcessor(racer: any, playerKey: any, nowRef: { value: number })
	return LegShapeService.CreateSubmitProcessor({
		resolveRacer = function(key)
			if key == playerKey then
				return racer
			end
			return nil
		end,
		now = function()
			return nowRef.value
		end,
	})
end

local function runMovingRedrawParity()
	local movingRacer = RacerRuntime.new({
		raceId = "B14_MOVING_REDRAW",
		slotIndex = 8,
		laneIndex = 8,
		isBot = false,
		trackId = "B14_FLAT",
		spawnCFrame = CFrame.new(44, 12, 0),
		laneCenterZ = 0,
	})

	local legsFolder = movingRacer:GetModel():FindFirstChild("Legs") :: Folder
	local nowRef = { value = 500.0 }
	local processor = makeProcessor(movingRacer, MOVING_TEST_PLAYER, nowRef)

	local seeded = processor:Handle(MOVING_TEST_PLAYER, shapeA(2000))
	assert(seeded ~= nil and seeded.accepted == true and seeded.shapeVersion == 1)

	local expectedVersion = 1

	for redrawIndex = 1, 10 do
		local pairBefore = movingRacer:GetLegPair()
		assert(pairBefore ~= nil, "moving redraw missing pair")

		local driveBefore = pairBefore:GetDrive()
		local jointBefore = driveBefore:GetJoint()

		nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
		local sequence = 2000 + redrawIndex
		local nextPayload = if redrawIndex % 2 == 0
			then shapeA(sequence)
			else shapeB(sequence)

		local result = processor:Handle(MOVING_TEST_PLAYER, nextPayload)
		assert(result ~= nil and result.accepted == true, "moving redraw must accept")

		expectedVersion += 1
		assert(result.shapeVersion == expectedVersion)
		assert(movingRacer:GetShapeVersion() == expectedVersion)

		local pairAfter = movingRacer:GetLegPair()
		assert(pairAfter == pairBefore, "moving redraw replaced pair")
		assert(pairAfter:GetDrive() == driveBefore, "moving redraw replaced SharedLegDrive")
		assert(pairAfter:GetDrive():GetJoint() == jointBefore, "moving redraw replaced DriveJoint")
		assert(countSharedDriveModels(legsFolder) == 1)
		assertLegPartBounds(legsFolder, "moving redraw")
		assertNoTransient(legsFolder, "moving redraw")
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
	assert(seeded ~= nil and seeded.accepted == true and seeded.shapeVersion == 1)

	local pair = racer:GetLegPair()
	assert(pair ~= nil)
	local drive = pair:GetDrive():GetModel()
	assert(legsFolder:FindFirstChild("SharedLegDrive") == drive)
	assertCurrentShapeIntact(racer, legsFolder, 1, drive)

	nowRef.value = 100.05
	local rateLimited = processor:Handle(TEST_PLAYER, shapeB(2))
	assert(
		rateLimited ~= nil
			and rateLimited.accepted == false
			and rateLimited.rejectReasonCode == "RATE_LIMITED"
	)
	assertCurrentShapeIntact(racer, legsFolder, 1, drive)

	local stale = processor:Handle(TEST_PLAYER, shapeB(1))
	assert(
		stale ~= nil
			and stale.accepted == false
			and stale.rejectReasonCode == "STALE_SEQUENCE"
	)
	assertCurrentShapeIntact(racer, legsFolder, 1, drive)

	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local malformed = processor:Handle(TEST_PLAYER, payload(3, {
		{ x = 0, y = 0 },
		"not-a-point",
		{ x = 0.4, y = 0 },
	}))
	assert(
		malformed ~= nil
			and malformed.accepted == false
			and malformed.rejectReasonCode == "MALFORMED_POINTS"
	)
	assertCurrentShapeIntact(racer, legsFolder, 1, drive)

	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local nonFinite = processor:Handle(TEST_PLAYER, payload(4, {
		{ x = 0, y = 0 },
		{ x = math.huge, y = 0.2 },
		{ x = 0.4, y = 0 },
	}))
	assert(
		nonFinite ~= nil
			and nonFinite.accepted == false
			and nonFinite.rejectReasonCode == "NON_FINITE_POINT"
	)
	assertCurrentShapeIntact(racer, legsFolder, 1, drive)

	local tooManyPoints = table.create(PhysicsConfig.StrokeProcessing.MaxRawPoints + 1)
	for index = 1, PhysicsConfig.StrokeProcessing.MaxRawPoints + 1 do
		tooManyPoints[index] = { x = index / 1000, y = 0 }
	end

	nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local tooMany = processor:Handle(TEST_PLAYER, payload(5, tooManyPoints))
	assert(
		tooMany ~= nil
			and tooMany.accepted == false
			and tooMany.rejectReasonCode == "TOO_MANY_POINTS"
	)
	assertCurrentShapeIntact(racer, legsFolder, 1, drive)

	local acceptedVersion = 1
	for attempt = 1, 40 do
		nowRef.value += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
		local sequence = 10 + attempt
		local nextPayload = if attempt % 2 == 0
			then shapeA(sequence)
			else shapeB(sequence)

		local result = processor:Handle(TEST_PLAYER, nextPayload)
		assert(result ~= nil and result.accepted == true, "stress redraw must accept legal shape")

		acceptedVersion += 1
		assert(result.shapeVersion == acceptedVersion)
		assert(racer:GetShapeVersion() == acceptedVersion)
		assert(countSharedDriveModels(legsFolder) == 1)
		assertLegPartBounds(legsFolder, "stress redraw")
		assertNoTransient(legsFolder, "stress redraw")
	end

	for attempt = 1, 50 do
		local spam = processor:Handle(TEST_PLAYER, shapeA(1000 + attempt))
		assert(
			spam ~= nil
				and spam.accepted == false
				and spam.rejectReasonCode == "RATE_LIMITED",
			"burst spam must rate-limit"
		)
	end

	assert(racer:GetShapeVersion() == acceptedVersion)
	assertCurrentShapeIntact(racer, legsFolder, acceptedVersion, drive)

	runMovingRedrawParity()
	racer:Destroy()

	print("[DrawRacers][B14] shared-drive redraw abuse/stress tests PASS")
end

return B14RedrawStressSpec
