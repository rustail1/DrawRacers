--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("StrokeMath")
)
local GeometryMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("GeometryMath")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)

local LegShapeService = {}

type SemanticPoints = StrokeTypes.SemanticPoints
type ShapeSpec = StrokeTypes.ShapeSpec
type LegShapeResult = StrokeTypes.LegShapeResult
type StrokeResultPayload = StrokeTypes.StrokeResultPayload

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function reject(reasonCode: string): LegShapeResult
	return {
		accepted = false,
		rejectReasonCode = reasonCode,
	}
end

local function networkReject(sequence: number, reasonCode: string): StrokeResultPayload
	return {
		sequence = sequence,
		accepted = false,
		rejectReasonCode = reasonCode,
	}
end

local function serializeSemanticPoints(points: { Vector2 }): SemanticPoints
	local result = table.create(#points)
	for index, point in points do
		result[index] = {
			x = point.X,
			y = point.Y,
		}
	end
	return result
end

local function validateRawPointArray(rawPoints: any): ({ Vector2 }?, string?)
	local config = PhysicsConfig.StrokeProcessing
	if type(rawPoints) ~= "table" then
		return nil, "MALFORMED_POINTS"
	end

	local entryCount = 0
	local maxIndex = 0
	for key, _ in rawPoints do
		if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
			return nil, "MALFORMED_POINTS"
		end
		entryCount += 1
		if entryCount > config.MaxRawPoints or key > config.MaxRawPoints then
			return nil, "TOO_MANY_POINTS"
		end
		maxIndex = math.max(maxIndex, key)
	end

	if entryCount < config.MinimumRawPoints then
		return nil, "TOO_FEW_POINTS"
	end
	if maxIndex ~= entryCount then
		return nil, "MALFORMED_POINTS"
	end

	local points = table.create(entryCount)
	for index = 1, entryCount do
		local point = rawPoints[index]
		if typeof(point) ~= "Vector2" then
			return nil, "MALFORMED_POINTS"
		end
		points[index] = point
	end
	return points, nil
end

local function buildDebugId(version: number, points: { Vector2 }, length: number): string
	local first = points[1]
	local last = points[#points]
	return string.format(
		"shape-v%d-p%d-l%.4f-f%.3f,%.3f-z%.3f,%.3f",
		version,
		#points,
		length,
		first.X,
		first.Y,
		last.X,
		last.Y
	)
end

function LegShapeService.ValidateAndBuild(racerRuntime: any, rawPoints: any, motorEnabled: boolean?): LegShapeResult
	if type(racerRuntime) ~= "table"
		or type(racerRuntime.GetShapeVersion) ~= "function"
		or type(racerRuntime.ApplyValidatedShape) ~= "function"
	then
		return reject("INVALID_RACER")
	end

	local config = PhysicsConfig.StrokeProcessing
	local points, arrayError = validateRawPointArray(rawPoints)
	if points == nil then
		return reject(arrayError or "MALFORMED_POINTS")
	end

	local clamped, clampError = StrokeMath.Clamp(points, {
		minCoordinate = config.NormalizedMin,
		maxCoordinate = config.NormalizedMax,
		maxPoints = config.MaxRawPoints,
	})
	if clamped == nil then
		return reject(clampError or "INVALID_STROKE")
	end

	local deduped = StrokeMath.Dedupe(clamped, config.DedupeDistance)
	if #deduped < 2 then
		return reject("TOO_SHORT")
	end

	local simplified = StrokeMath.SimplifyRDP(deduped, config.RDPEpsilon)
	if #simplified < 2 then
		return reject("TOO_SHORT")
	end

	local cleaned = StrokeMath.Resample(
		simplified,
		math.min(config.ResampleTargetPoints, config.MaxCleanedPoints)
	)
	if #cleaned > config.MaxCleanedPoints then
		return reject("TOO_MANY_CLEANED_POINTS")
	end

	local cleanedLength = StrokeMath.MeasureLength(cleaned)
	if #cleaned < 2 or cleanedLength < config.MinimumCleanedPolylineLength then
		return reject("TOO_SHORT")
	end

	-- R16.3A: placement inside DrawCanvas is presentation-only. Translate the
	-- cleaned shape so its own bounds center is the mechanical hub; do not scale,
	-- rotate, mirror, or close the stroke.
	local centered = StrokeMath.CenterOnBounds(cleaned)
	local bounds = StrokeMath.ComputeBounds(centered)
	if bounds == nil then
		return reject("TOO_SHORT")
	end

	local geometryPlan = GeometryMath.BuildSegmentPlan(centered, PhysicsConfig.LegGeometry)
	if #geometryPlan.segmentPlan == 0 then
		return reject("TOO_SHORT")
	end
	if geometryPlan.extent < PhysicsConfig.LegGeometry.MinUsefulLegExtent then
		return reject("TOO_SHORT")
	end

	local nextVersion = racerRuntime:GetShapeVersion() + 1
	local shapeSpec: ShapeSpec = {
		version = nextVersion,
		normalizedPoints = centered,
		mappedPoints = geometryPlan.mappedPoints,
		bounds = bounds,
		extent = geometryPlan.extent,
		segmentPlan = geometryPlan.segmentPlan,
		debugRawPointCount = #points,
		debugPhysicsPointCount = #geometryPlan.mappedPoints,
		debugId = buildDebugId(nextVersion, centered, cleanedLength),
	}

	local applied, applyError = pcall(function()
		racerRuntime:ApplyValidatedShape(shapeSpec, motorEnabled)
	end)
	if not applied then
		warn(string.format("[DrawRacers][B11] validated shape build failed: %s", tostring(applyError)))
		return reject("BUILD_FAILED")
	end

	return {
		accepted = true,
		shapeVersion = nextVersion,
		shapeSpec = shapeSpec,
	}
end

local function extractSequence(payload: any): number?
	if type(payload) ~= "table" then
		return nil
	end
	local sequence = payload.sequence
	if type(sequence) ~= "number"
		or not isFiniteNumber(sequence)
		or sequence < 1
		or math.floor(sequence) ~= sequence
	then
		return nil
	end
	return sequence
end

function LegShapeService.ExtractSafeSequence(payload: any): number?
	return extractSequence(payload)
end

local function validateNetworkEnvelope(payload: any): string?
	if type(payload) ~= "table" then
		return "MALFORMED_PAYLOAD"
	end

	local fieldCount = 0
	for key, _ in payload do
		fieldCount += 1
		if fieldCount > 2 or (key ~= "sequence" and key ~= "points") then
			return "MALFORMED_PAYLOAD"
		end
	end
	if fieldCount ~= 2 or payload.points == nil then
		return "MALFORMED_PAYLOAD"
	end
	return nil
end

local function validateSemanticPoint(point: any): (number?, number?, string?)
	if type(point) ~= "table" then
		return nil, nil, "MALFORMED_POINTS"
	end

	local fieldCount = 0
	for key, _ in point do
		fieldCount += 1
		if fieldCount > 2 or (key ~= "x" and key ~= "y") then
			return nil, nil, "MALFORMED_POINTS"
		end
	end
	if fieldCount ~= 2 then
		return nil, nil, "MALFORMED_POINTS"
	end

	local x = point.x
	local y = point.y
	if type(x) ~= "number" or type(y) ~= "number" then
		return nil, nil, "MALFORMED_POINTS"
	end
	if not isFiniteNumber(x) or not isFiniteNumber(y) then
		return nil, nil, "NON_FINITE_POINT"
	end
	return x, y, nil
end

local function validateNetworkPoints(rawPoints: any): ({ Vector2 }?, SemanticPoints?, string?)
	local config = PhysicsConfig.StrokeProcessing
	if type(rawPoints) ~= "table" then
		return nil, nil, "MALFORMED_POINTS"
	end

	local entryCount = 0
	local maxIndex = 0
	for key, _ in rawPoints do
		if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
			return nil, nil, "MALFORMED_POINTS"
		end
		entryCount += 1
		if entryCount > config.MaxRawPoints or key > config.MaxRawPoints then
			return nil, nil, "TOO_MANY_POINTS"
		end
		maxIndex = math.max(maxIndex, key)
	end

	if entryCount < config.MinimumRawPoints then
		return nil, nil, "TOO_FEW_POINTS"
	end
	if maxIndex ~= entryCount then
		return nil, nil, "MALFORMED_POINTS"
	end

	local vectors = table.create(entryCount)
	local canonicalPoints: SemanticPoints = table.create(entryCount)
	for index = 1, entryCount do
		local x, y, pointError = validateSemanticPoint(rawPoints[index])
		if pointError ~= nil or x == nil or y == nil then
			return nil, nil, pointError or "MALFORMED_POINTS"
		end
		vectors[index] = Vector2.new(x, y)
		canonicalPoints[index] = { x = x, y = y }
	end
	return vectors, canonicalPoints, nil
end

function LegShapeService.CreateSubmitProcessor(deps: any)
	assert(type(deps) == "table", "CreateSubmitProcessor requires deps")
	assert(type(deps.resolveRacer) == "function", "CreateSubmitProcessor requires resolveRacer")
	local nowFn = deps.now or os.clock
	assert(type(nowFn) == "function", "CreateSubmitProcessor now must be a function")

	local states = setmetatable({}, { __mode = "k" })
	local processor = {}

	function processor:Handle(playerKey: any, payload: any): StrokeResultPayload?
		local sequence = extractSequence(payload)
		if sequence == nil then
			return nil
		end

		local envelopeError = validateNetworkEnvelope(payload)
		if envelopeError ~= nil then
			return networkReject(sequence, envelopeError)
		end

		local racerRuntime = deps.resolveRacer(playerKey)
		if racerRuntime == nil then
			return networkReject(sequence, "NO_RACER")
		end

		local state = states[playerKey]
		if state == nil then
			state = {
				lastAcceptedSequence = 0,
				pendingSequence = nil,
				lastRequestAt = -math.huge,
			}
			states[playerKey] = state
		end

		local pendingSequence = state.pendingSequence
		if sequence <= state.lastAcceptedSequence
			or (pendingSequence ~= nil and sequence <= pendingSequence)
		then
			return networkReject(sequence, "STALE_SEQUENCE")
		end
		state.pendingSequence = sequence

		local now = nowFn()
		if type(now) ~= "number" or not isFiniteNumber(now) then
			state.pendingSequence = nil
			return networkReject(sequence, "SERVER_TIME_INVALID")
		end
		if now - state.lastRequestAt < PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown then
			state.pendingSequence = nil
			return networkReject(sequence, "RATE_LIMITED")
		end
		state.lastRequestAt = now

		local vectors, canonicalPoints, pointsError = validateNetworkPoints(payload.points)
		if vectors == nil or canonicalPoints == nil then
			state.pendingSequence = nil
			return networkReject(sequence, pointsError or "MALFORMED_POINTS")
		end

		local encodedOk, encodedPayload = pcall(function()
			return HttpService:JSONEncode({ sequence = sequence, points = canonicalPoints })
		end)
		if not encodedOk or type(encodedPayload) ~= "string" then
			state.pendingSequence = nil
			return networkReject(sequence, "MALFORMED_POINTS")
		end
		if #encodedPayload > PhysicsConfig.StrokeProcessing.MaxStrokePayloadBytes then
			state.pendingSequence = nil
			return networkReject(sequence, "PAYLOAD_TOO_LARGE")
		end

		local buildResult = LegShapeService.ValidateAndBuild(racerRuntime, vectors, true)
		state.pendingSequence = nil
		if buildResult.accepted == true then
			state.lastAcceptedSequence = sequence
			local shapeSpec = buildResult.shapeSpec
			assert(shapeSpec ~= nil, "accepted build missing ShapeSpec")
			return {
				sequence = sequence,
				accepted = true,
				shapeVersion = buildResult.shapeVersion,
				acceptedPoints = serializeSemanticPoints(shapeSpec.normalizedPoints),
			}
		end
		return networkReject(sequence, buildResult.rejectReasonCode or "INVALID_STROKE")
	end

	return processor
end

return LegShapeService
