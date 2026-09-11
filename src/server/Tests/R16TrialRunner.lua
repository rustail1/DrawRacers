--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local R16TrialRunner = {}

local activeRacer: any = nil
local SOLVER_LINEAR_SPEED_LIMIT = 160
local SOLVER_ANGULAR_SPEED_LIMIT = 120

local function findPiece(pieceId: string): any
	for _, piece in M0SceneConfig.Pieces do
		if piece.PieceId == pieceId then
			return piece
		end
	end
	error(string.format("missing canonical piece %s", pieceId))
end

local function contactMatches(part: BasePart, options: any?): boolean
	if options == nil then
		return true
	end
	if options.contactName ~= nil then
		return part.Name == options.contactName
	end
	local prefix = options.contactPrefix
	if prefix == nil then
		return true
	end
	return string.sub(part.Name, 1, #prefix) == prefix
end

local function partTouchesTrack(part: BasePart, model: Model, options: any?): boolean
	if not part.CanTouch then
		return false
	end
	for _, touchingPart in part:GetTouchingParts() do
		if not touchingPart:IsDescendantOf(model)
			and touchingPart.CollisionGroup == "Track"
			and contactMatches(touchingPart, options)
		then
			return true
		end
	end
	return false
end

local function hasTrackContact(model: Model, options: any?): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and partTouchesTrack(descendant, model, options) then
			return true
		end
	end
	return false
end

local function legsTouchTrack(model: Model, options: any?): boolean
	local legs = model:FindFirstChild("Legs")
	if legs == nil then
		return false
	end
	for _, descendant in legs:GetDescendants() do
		if descendant:IsA("BasePart") and partTouchesTrack(descendant, model, options) then
			return true
		end
	end
	return false
end

local function waitForTrackContact(racer: any, timeoutSeconds: number, options: any?): boolean
	local elapsed = 0
	while elapsed < timeoutSeconds do
		if hasTrackContact(racer:GetModel(), options) then
			return true
		end
		elapsed += RunService.Heartbeat:Wait()
	end
	return false
end

local function allMotorsEnabled(model: Model): boolean
	local legs = model:FindFirstChild("Legs")
	if legs == nil then
		return false
	end
	local axleRoot = legs:FindFirstChild("AxleRoot")
	if not (axleRoot and axleRoot:IsA("BasePart")) then
		return false
	end
	local joint = axleRoot:FindFirstChild("AxleJoint")
	return joint ~= nil and joint:IsA("HingeConstraint") and joint.Enabled
end

local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

local function solverUnstable(body: BasePart): boolean
	local linear = body.AssemblyLinearVelocity
	local angular = body.AssemblyAngularVelocity
	for _, value in {
		linear.X,
		linear.Y,
		linear.Z,
		angular.X,
		angular.Y,
		angular.Z,
	} do
		if not finite(value) then
			return true
		end
	end
	return linear.Magnitude > SOLVER_LINEAR_SPEED_LIMIT or angular.Magnitude > SOLVER_ANGULAR_SPEED_LIMIT
end

local function applyProperties(part: BasePart, density: number?, friction: number?)
	local baseline = part.CustomPhysicalProperties
	if baseline == nil then
		return
	end
	if density == nil and friction == nil then
		return
	end
	part.CustomPhysicalProperties = PhysicalProperties.new(
		density or baseline.Density,
		friction or baseline.Friction,
		baseline.Elasticity,
		baseline.FrictionWeight,
		baseline.ElasticityWeight
	)
end

local function applyTemporaryTuning(racer: any, tuning: any?)
	if tuning == nil then
		return
	end

	local body = racer:GetBody()
	applyProperties(body, tuning.bodyDensity, tuning.bodyFriction)
	if tuning.colliderSize ~= nil then
		local colliderSize = tuning.colliderSize
		body.Size = Vector3.new(colliderSize, colliderSize, colliderSize)
	end

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "temporary tuning requires a live LegPairAssembly")
	if tuning.legDensity ~= nil then
		for _, leg in { pair:GetLeftLeg(), pair:GetRightLeg() } do
			for _, segment in leg:GetSegments() do
				applyProperties(segment, tuning.legDensity, nil)
			end
		end
	end

	if tuning.motorAngularVelocity ~= nil then
		local joint = pair:GetJoint()
		joint.AngularVelocity = tuning.motorAngularVelocity
	end
end

function R16TrialRunner.DestroyActive()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
end

local function finishSpawn(racer: any, shapeId: string): any
	activeRacer = racer
	local model = racer:GetModel()
	model:SetAttribute("R16Trial", true)
	racer:ApplyShape(R16ReferenceShapes.Get(shapeId), true)
	model:SetAttribute("ShapeVersion", 1)
	return racer
end

local function spawnCanonical(pieceId: string, shapeId: string, spawnX: number?): any
	R16TrialRunner.DestroyActive()
	local piece = findPiece(pieceId)
	local racer = RacerRuntime.new({
		raceId = "R16_TRIAL",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R16_TRIAL",
		spawnCFrame = CFrame.new(spawnX or (piece.StartX + 1), 3.3, 0),
		laneCenterZ = 0,
	})
	return finishSpawn(racer, shapeId)
end

local function gapSpawnX(piece: any): number
	local gapWidth = assert(piece.GapWidth, "GapSmall missing GapWidth")
	local approachLength = (piece.Length - gapWidth) / 2
	return piece.StartX + approachLength - 2.0
end

function R16TrialRunner.RunFlat(shapeId: string): any
	assert(RunService:IsStudio(), "R16TrialRunner is Studio-only")
	R16TrialRunner.DestroyActive()
	local benchmark = M0SceneConfig.ReferenceBenchmark
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local racer = RacerRuntime.new({
		raceId = "R16_FLAT_TRIAL",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R16_REFERENCE_BENCHMARK",
		spawnCFrame = CFrame.new(benchmark.SpawnX, benchmark.SpawnY, benchmark.CenterZ),
		laneCenterZ = benchmark.CenterZ,
	})
	finishSpawn(racer, shapeId)
	local model = racer:GetModel()
	local body = racer:GetBody()
	local contactOptions = { contactName = benchmark.Name }
	local result = {
		valid = true,
		speed = 0,
		progress = 0,
		maxDeltaY = 0,
		minDeltaY = 0,
		antiStallSeen = false,
		motorsEnabled = false,
		landedAfterGap = false,
		completedPiece = false,
	}

	if not waitForTrackContact(racer, acceptance.TrackContactTimeout, contactOptions) then
		result.valid = false
		R16TrialRunner.DestroyActive()
		return result
	end

	local settleElapsed = 0
	while settleElapsed < acceptance.FlatIgnoreSeconds do
		if not hasTrackContact(model, contactOptions) then
			result.valid = false
			R16TrialRunner.DestroyActive()
			return result
		end
		settleElapsed += RunService.Heartbeat:Wait()
	end

	local startX = body.Position.X
	local startY = body.Position.Y
	local maxY = startY
	local minY = startY
	local elapsed = 0
	while elapsed < acceptance.FlatMeasureSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		if not hasTrackContact(model, contactOptions) then
			result.valid = false
			break
		end
		maxY = math.max(maxY, body.Position.Y)
		minY = math.min(minY, body.Position.Y)
		if model:GetAttribute("AntiStallActive") == true then
			result.antiStallSeen = true
		end
	end

	result.progress = body.Position.X - startX
	result.speed = result.progress / math.max(elapsed, 1e-6)
	result.maxDeltaY = maxY - startY
	result.minDeltaY = minY - startY
	result.motorsEnabled = allMotorsEnabled(model)
	R16TrialRunner.DestroyActive()
	return result
end

-- R17 evidence-only API. options.tuning is applied only to this temporary racer,
-- which is destroyed at the end of the trial; production PhysicsConfig is never mutated.
function R16TrialRunner.RunFlatTelemetry(shapeId: string, options: any): any
	assert(RunService:IsStudio(), "R16TrialRunner is Studio-only")
	R16TrialRunner.DestroyActive()
	local benchmark = M0SceneConfig.ReferenceBenchmark
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local racer = RacerRuntime.new({
		raceId = "R17_BODY_FEEL_TRIAL",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R17_BODY_FEEL",
		spawnCFrame = CFrame.new(benchmark.SpawnX, benchmark.SpawnY, benchmark.CenterZ),
		laneCenterZ = benchmark.CenterZ,
	})
	finishSpawn(racer, shapeId)
	local tuning = if options.tuning ~= nil then options.tuning else options
	applyTemporaryTuning(racer, tuning)
	local model = racer:GetModel()
	local body = racer:GetBody()
	local contactOptions = { contactName = benchmark.Name }
	local result = {
		valid = true,
		duration = 0,
		bodyContactTime = 0,
		legContactTime = 0,
		airTime = 0,
		forwardDistance = 0,
		averageSpeed = 0,
		stuckTime = 0,
		maxBounceHeight = 0,
		solverInstability = false,
		antiStallSeen = false,
		motorsEnabled = false,
	}

	if not waitForTrackContact(racer, acceptance.TrackContactTimeout, contactOptions) then
		result.valid = false
		R16TrialRunner.DestroyActive()
		return result
	end

	local settleElapsed = 0
	while settleElapsed < acceptance.FlatIgnoreSeconds do
		settleElapsed += RunService.Heartbeat:Wait()
	end

	local startX = body.Position.X
	local startY = body.Position.Y
	local elapsed = 0
	while elapsed < acceptance.FlatMeasureSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local bodyContact = partTouchesTrack(body, model, contactOptions)
		local legContact = legsTouchTrack(model, contactOptions)
		if bodyContact then
			result.bodyContactTime += dt
		end
		if legContact then
			result.legContactTime += dt
		end
		if not bodyContact and not legContact then
			result.airTime += dt
		end
		if math.abs(body.AssemblyLinearVelocity.X) < 0.5 then
			result.stuckTime += dt
		end
		result.maxBounceHeight = math.max(result.maxBounceHeight, body.Position.Y - startY)
		if solverUnstable(body) then
			result.solverInstability = true
		end
		if model:GetAttribute("AntiStallActive") == true then
			result.antiStallSeen = true
		end
	end

	result.duration = elapsed
	result.forwardDistance = body.Position.X - startX
	result.averageSpeed = result.forwardDistance / math.max(elapsed, 1e-6)
	result.motorsEnabled = allMotorsEnabled(model)
	R16TrialRunner.DestroyActive()
	return result
end

function R16TrialRunner.RunPiece(pieceId: string, shapeId: string, measureSeconds: number, options: any?): any
	assert(RunService:IsStudio(), "R16TrialRunner is Studio-only")
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local piece = findPiece(pieceId)
	local spawnX = if options ~= nil then options.spawnX else nil
	local contactTimeout = if options ~= nil and options.contactTimeout ~= nil
		then options.contactTimeout
		else acceptance.TrackContactTimeout
	if pieceId == "GapSmall" and spawnX == nil then
		spawnX = gapSpawnX(piece)
	end
	local racer = spawnCanonical(pieceId, shapeId, spawnX)
	if options ~= nil and options.tuning ~= nil then
		applyTemporaryTuning(racer, options.tuning)
	end
	local model = racer:GetModel()
	local body = racer:GetBody()
	local result = {
		valid = true,
		speed = 0,
		progress = 0,
		maxDeltaY = 0,
		minDeltaY = 0,
		maxBounceHeight = 0,
		solverInstability = false,
		antiStallSeen = false,
		motorsEnabled = false,
		landedAfterGap = false,
		completedPiece = false,
	}

	if not waitForTrackContact(racer, contactTimeout, options) then
		result.valid = false
		R16TrialRunner.DestroyActive()
		return result
	end

	local startX = body.Position.X
	local startY = body.Position.Y
	local maxX = startX
	local maxY = startY
	local minY = startY
	local elapsed = 0
	local gapEnd: number? = nil
	if pieceId == "GapSmall" then
		local gapWidth = assert(piece.GapWidth, "GapSmall missing GapWidth")
		local approachLength = (piece.Length - gapWidth) / 2
		gapEnd = piece.StartX + approachLength + gapWidth
	end

	while elapsed < measureSeconds do
		elapsed += RunService.Heartbeat:Wait()
		local position = body.Position
		maxX = math.max(maxX, position.X)
		maxY = math.max(maxY, position.Y)
		minY = math.min(minY, position.Y)
		if solverUnstable(body) then
			result.solverInstability = true
		end
		if model:GetAttribute("AntiStallActive") == true then
			result.antiStallSeen = true
		end
		if gapEnd ~= nil and position.X >= gapEnd and hasTrackContact(model, nil) then
			result.landedAfterGap = true
		end
		if position.Y < M0SceneConfig.RecoveryKillY then
			break
		end
	end

	result.progress = maxX - startX
	result.speed = result.progress / math.max(elapsed, 1e-6)
	result.maxDeltaY = maxY - startY
	result.minDeltaY = minY - startY
	result.maxBounceHeight = math.max(0, maxY - startY)
	result.motorsEnabled = allMotorsEnabled(model)
	result.completedPiece = maxX >= piece.StartX + piece.Length - 0.5
	R16TrialRunner.DestroyActive()
	return result
end

function R16TrialRunner.FindPiece(pieceId: string): any
	return findPiece(pieceId)
end

return R16TrialRunner
