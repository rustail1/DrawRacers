--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("RemoteNames")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))
local StrokeRemoteTransport = require(script.Parent.Parent.Services:WaitForChild("StrokeRemoteTransport"))

local B12StrokeRemoteSpec = {}

local TEST_PLAYER = {}
local OTHER_PLAYER = {}

local function validPayload(sequence: number)
	return {
		sequence = sequence,
		points = {
			{ x = -0.72, y = 0 },
			{ x = 0, y = 0.72 },
			{ x = 0.72, y = 0 },
			{ x = 0, y = -0.72 },
		},
	}
end

local function assertAcceptedPointsMatchCurrentShape(racer: any, accepted: any)
	local currentShape = racer:GetCurrentShapeSpec()
	assert(currentShape ~= nil, "accepted result requires current ShapeSpec")
	assert(type(accepted.acceptedPoints) == "table", "accepted result missing authoritative acceptedPoints")
	assert(#accepted.acceptedPoints == #currentShape.normalizedPoints, "acceptedPoints count must match ShapeSpec")
	for index, point in currentShape.normalizedPoints do
		local resultPoint = accepted.acceptedPoints[index]
		assert(type(resultPoint) == "table", "acceptedPoints entry must be semantic point")
		assert(math.abs(resultPoint.x - point.X) <= 1e-6, "acceptedPoints X drifted from ShapeSpec")
		assert(math.abs(resultPoint.y - point.Y) <= 1e-6, "acceptedPoints Y drifted from ShapeSpec")
	end
end

function B12StrokeRemoteSpec.run()
	assert(type(StrokeRemoteTransport.Bind) == "function", "B12 transport helper must expose Bind")
	assert(type(StrokeRemoteTransport.ProcessSafely) == "function", "B12 transport helper must expose ProcessSafely")

	local injectedError = StrokeRemoteTransport.ProcessSafely({
		Handle = function()
			error("B12 injected processor failure")
		end,
	}, TEST_PLAYER, validPayload(99))
	assert(
		injectedError ~= nil
			and injectedError.sequence == 99
			and injectedError.accepted == false
			and injectedError.rejectReasonCode == "SERVER_ERROR",
		"processor exception must become immediate generic SERVER_ERROR"
	)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local submitStroke = remotes:WaitForChild(RemoteNames.SubmitStroke)
	local strokeResult = remotes:WaitForChild(RemoteNames.StrokeResult)
	assert(submitStroke:IsA("RemoteEvent"), "SubmitStroke must be RemoteEvent")
	assert(strokeResult:IsA("RemoteEvent"), "StrokeResult must be RemoteEvent")
	assert(remotes:FindFirstChildWhichIsA("RemoteFunction") == nil, "B12 must not expose RemoteFunction/generic RPC")

	local racer = RacerRuntime.new({
		raceId = "B12_TEST",
		slotIndex = 5,
		laneIndex = 5,
		isBot = false,
		trackId = "B12_FLAT",
		spawnCFrame = CFrame.new(-12, 8, 0),
		laneCenterZ = 0,
	})
	racer:GetBody().Anchored = true

	local now = 10.0
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

	assert(racer:GetShapeVersion() == 0)
	local accepted = processor:Handle(TEST_PLAYER, validPayload(1))
	assert(accepted ~= nil and accepted.sequence == 1 and accepted.accepted == true, "valid B12 submit must accept")
	assert(accepted.shapeVersion == 1 and racer:GetShapeVersion() == 1, "accepted submit must advance ShapeVersion exactly once")
	assertAcceptedPointsMatchCurrentShape(racer, accepted)

	local stale = processor:Handle(TEST_PLAYER, validPayload(1))
	assert(stale ~= nil and stale.accepted == false and stale.rejectReasonCode == "STALE_SEQUENCE", "duplicate sequence must be stale")
	assert(racer:GetShapeVersion() == 1, "STALE_SEQUENCE changed ShapeVersion")

	now = 10.10
	local rateLimited = processor:Handle(TEST_PLAYER, validPayload(2))
	assert(rateLimited ~= nil and rateLimited.accepted == false and rateLimited.rejectReasonCode == "RATE_LIMITED", "cooldown spam must reject")
	assert(racer:GetShapeVersion() == 1, "RATE_LIMITED changed ShapeVersion")

	now = 10.25
	local malformed = processor:Handle(TEST_PLAYER, {
		sequence = 2,
		points = {
			{ x = -0.5, y = 0 },
			"not-a-point",
			{ x = 0.5, y = 0 },
		},
	})
	assert(malformed ~= nil and malformed.accepted == false and malformed.rejectReasonCode == "MALFORMED_POINTS")
	assert(racer:GetShapeVersion() == 1, "MALFORMED_POINTS changed ShapeVersion")

	now = 10.50
	local nonFinite = processor:Handle(TEST_PLAYER, {
		sequence = 3,
		points = {
			{ x = -0.5, y = 0 },
			{ x = math.huge, y = 0.25 },
			{ x = 0.5, y = 0 },
		},
	})
	assert(nonFinite ~= nil and nonFinite.accepted == false and nonFinite.rejectReasonCode == "NON_FINITE_POINT")
	assert(racer:GetShapeVersion() == 1, "NON_FINITE_POINT changed ShapeVersion")

	now = 10.75
	local tooManyPoints = table.create(97)
	for index = 1, 97 do
		tooManyPoints[index] = { x = index / 100, y = 0 }
	end
	local tooMany = processor:Handle(TEST_PLAYER, {
		sequence = 4,
		points = tooManyPoints,
	})
	assert(tooMany ~= nil and tooMany.accepted == false and tooMany.rejectReasonCode == "TOO_MANY_POINTS")
	assert(racer:GetShapeVersion() == 1, "TOO_MANY_POINTS changed ShapeVersion")

	now = 11.00
	local oversizedPoints = table.create(96)
	for index = 1, 96 do
		oversizedPoints[index] = {
			x = 1.234567890123456e300,
			y = -9.876543210987654e299,
		}
	end
	local oversized = processor:Handle(TEST_PLAYER, {
		sequence = 5,
		points = oversizedPoints,
	})
	assert(oversized ~= nil and oversized.accepted == false and oversized.rejectReasonCode == "PAYLOAD_TOO_LARGE", "bounded >4096 payload must reject")
	assert(racer:GetShapeVersion() == 1, "PAYLOAD_TOO_LARGE changed ShapeVersion")

	now = 11.25
	local unexpectedField = validPayload(6)
	unexpectedField.unexpectedField = "not part of SubmitStroke contract"
	local malformedEnvelope = processor:Handle(TEST_PLAYER, unexpectedField)
	assert(malformedEnvelope ~= nil and malformedEnvelope.accepted == false and malformedEnvelope.rejectReasonCode == "MALFORMED_PAYLOAD", "extra top-level fields must fail closed")
	assert(racer:GetShapeVersion() == 1, "MALFORMED_PAYLOAD changed ShapeVersion")

	local noRacer = processor:Handle(OTHER_PLAYER, validPayload(1))
	assert(noRacer ~= nil and noRacer.accepted == false and noRacer.rejectReasonCode == "NO_RACER", "unresolved player must fail closed")

	now = 11.50
	local second = processor:Handle(TEST_PLAYER, validPayload(2))
	assert(second ~= nil and second.accepted == true and second.sequence == 2, "new valid sequence after cooldown must accept")
	assert(second.shapeVersion == 2 and racer:GetShapeVersion() == 2, "second accepted submit must advance ShapeVersion to 2")
	assertAcceptedPointsMatchCurrentShape(racer, second)

	assert(processor:Handle(TEST_PLAYER, { points = {} }) == nil, "missing sequence must not fabricate echo result")
	assert(processor:Handle(TEST_PLAYER, { sequence = 2.5, points = {} }) == nil, "non-integer sequence must fail closed without echo")

	racer:Destroy()
	print("[DrawRacers][B12] SubmitStroke/StrokeResult tests PASS")
end

return B12StrokeRemoteSpec
