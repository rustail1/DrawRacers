--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))

local B14RedrawStressSpec = {}

local TEST_PLAYER = {}

local function payload(sequence: number, points: { any })
	return {
		sequence = sequence,
		points = points,
	}
end

local function shapeA(sequence: number)
	return payload(sequence, {
		{ x = -0.72, y = 0.00 },
		{ x = -0.18, y = 0.78 },
		{ x = 0.58, y = 0.54 },
		{ x = 0.82, y = -0.22 },
		{ x = 0.04, y = -0.82 },
	})
end

local function shapeB(sequence: number)
	return payload(sequence, {
		{ x = -0.88, y = -0.12 },
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
		if child:IsA("Model") then
			count += 1
		end
	end
	return count
end

local function countLegParts(legsFolder: Folder): number
	local count = 0
	for _, descendant in legsFolder:GetDescendants() do
		if descendant:IsA("BasePart") then
			count += 1
		end
	end
	return count
end

local function assertCurrentShapeIntact(racer: any, legsFolder: Folder, version: number, leftModel: Instance, rightModel: Instance)
	assert(racer:GetShapeVersion() == version, "rejected request changed valid current shape version")
	assert(legsFolder:FindFirstChild("LeftLeg") == leftModel, "rejected request removed valid current shape LeftLeg")
	assert(legsFolder:FindFirstChild("RightLeg") == rightModel, "rejected request removed valid current shape RightLeg")
	assert(countLegModels(legsFolder) == 2, "rejected request leaked leg models")
	assert(legsFolder:FindFirstChild("LeftLeg_Retiring") == nil, "rejected request left retiring LeftLeg")
	assert(legsFolder:FindFirstChild("RightLeg_Retiring") == nil, "rejected request left retiring RightLeg")
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

	local legsFolder = racer:GetModel():FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"), "B14 racer missing Legs folder")

	local now = 100.0
	local processor = LegShapeService.CreateSubmitProcessor({
		resolveRacer = function(playerKey)
			if playerKey == TEST_PLAYER then
				return racer
			end
			return nil
		end,
		now = function()
			return now
		end,
	})

	local seeded = processor:Handle(TEST_PLAYER, shapeA(1))
	assert(seeded ~= nil and seeded.accepted == true and seeded.shapeVersion == 1, "B14 seed shape must accept")
	local leftModel = legsFolder:FindFirstChild("LeftLeg")
	local rightModel = legsFolder:FindFirstChild("RightLeg")
	assert(leftModel ~= nil and rightModel ~= nil, "B14 seed must create a valid current shape")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	-- Spam a valid redraw inside cooldown. RATE_LIMITED must not mutate the accepted shape.
	now = 100.05
	local rateLimited = processor:Handle(TEST_PLAYER, shapeB(2))
	assert(rateLimited ~= nil and rateLimited.accepted == false and rateLimited.rejectReasonCode == "RATE_LIMITED")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	-- Duplicate/stale sequence cannot roll the racer back or rebuild geometry.
	local stale = processor:Handle(TEST_PLAYER, shapeB(1))
	assert(stale ~= nil and stale.accepted == false and stale.rejectReasonCode == "STALE_SEQUENCE")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	-- Each expensive invalid-payload check runs outside the previous accepted/validated request's
	-- cooldown window. Otherwise RATE_LIMITED correctly wins before point walking by contract.
	now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local malformed = processor:Handle(TEST_PLAYER, payload(3, {
		{ x = -0.4, y = 0.0 },
		"not-a-point",
		{ x = 0.4, y = 0.0 },
	}))
	assert(malformed ~= nil and malformed.accepted == false and malformed.rejectReasonCode == "MALFORMED_POINTS")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local nonFinite = processor:Handle(TEST_PLAYER, payload(4, {
		{ x = -0.4, y = 0.0 },
		{ x = math.huge, y = 0.2 },
		{ x = 0.4, y = 0.0 },
	}))
	assert(nonFinite ~= nil and nonFinite.accepted == false and nonFinite.rejectReasonCode == "NON_FINITE_POINT")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	local tooManyPoints = table.create(PhysicsConfig.StrokeProcessing.MaxRawPoints + 1)
	for index = 1, PhysicsConfig.StrokeProcessing.MaxRawPoints + 1 do
		tooManyPoints[index] = { x = index / 1000, y = 0 }
	end
	now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local tooMany = processor:Handle(TEST_PLAYER, payload(5, tooManyPoints))
	assert(tooMany ~= nil and tooMany.accepted == false and tooMany.rejectReasonCode == "TOO_MANY_POINTS")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	local oversizedPoints = table.create(PhysicsConfig.StrokeProcessing.MaxRawPoints)
	for index = 1, PhysicsConfig.StrokeProcessing.MaxRawPoints do
		oversizedPoints[index] = {
			x = 1.234567890123456e300,
			y = -9.876543210987654e299,
		}
	end
	now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
	local oversized = processor:Handle(TEST_PLAYER, payload(6, oversizedPoints))
	assert(oversized ~= nil and oversized.accepted == false and oversized.rejectReasonCode == "PAYLOAD_TOO_LARGE")
	assertCurrentShapeIntact(racer, legsFolder, 1, leftModel, rightModel)

	-- Repeated valid redraws must replace, not accumulate, physical leg assemblies.
	local acceptedVersion = 1
	local maxLegParts = 2 * (PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg + 1)
	for attempt = 1, 40 do
		now += PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown + 0.01
		local sequence = 10 + attempt
		local nextPayload = if attempt % 2 == 0 then shapeA(sequence) else shapeB(sequence)
		local result = processor:Handle(TEST_PLAYER, nextPayload)
		assert(result ~= nil and result.accepted == true, "stress redraw must accept legal shape")
		acceptedVersion += 1
		assert(result.shapeVersion == acceptedVersion and racer:GetShapeVersion() == acceptedVersion, "stress redraw version drift")
		assert(countLegModels(legsFolder) == 2, "stress redraw: no leaked leg models")
		assert(countLegParts(legsFolder) <= maxLegParts, "stress redraw leaked physical parts")
		assert(legsFolder:FindFirstChild("LeftLeg_Retiring") == nil, "stress redraw leaked retiring LeftLeg")
		assert(legsFolder:FindFirstChild("RightLeg_Retiring") == nil, "stress redraw leaked retiring RightLeg")
	end

	-- Burst spam after a successful redraw may reject repeatedly but cannot grow Instances.
	local modelsBeforeBurst = countLegModels(legsFolder)
	local partsBeforeBurst = countLegParts(legsFolder)
	local versionBeforeBurst = racer:GetShapeVersion()
	for attempt = 1, 50 do
		local result = processor:Handle(TEST_PLAYER, shapeA(1000 + attempt))
		assert(result ~= nil and result.accepted == false and result.rejectReasonCode == "RATE_LIMITED", "burst spam must remain rate limited")
	end
	assert(racer:GetShapeVersion() == versionBeforeBurst, "burst spam changed valid current shape")
	assert(countLegModels(legsFolder) == modelsBeforeBurst, "burst spam: no leaked leg models")
	assert(countLegParts(legsFolder) == partsBeforeBurst, "burst spam leaked physical parts")

	racer:Destroy()
	print("[DrawRacers][B14] redraw abuse/stress tests PASS")
end

return B14RedrawStressSpec