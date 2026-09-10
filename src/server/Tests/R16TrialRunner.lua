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

local function hasTrackContact(model: Model, options: any?): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.CanTouch then
			for _, touchingPart in descendant:GetTouchingParts() do
				if not touchingPart:IsDescendantOf(model)
					and touchingPart.CollisionGroup == "Track"
					and contactMatches(touchingPart, options)
				then
					return true
				end
			end
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
	for _, legName in { "LeftLeg", "RightLeg" } do
		local leg = legs:FindFirstChild(legName)
		if leg == nil then
			return false
		end
		local joint = leg:FindFirstChild("HubJoint")
		if joint == nil or not joint:IsA("HingeConstraint") or not joint.Enabled then
			return false
		end
	end
	return true
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
	-- Internal Studio/test shapes intentionally bypass the network version increment.
	-- Give anti-stall the same semantic state as a racer with one accepted shape.
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

function R16TrialRunner.RunPiece(pieceId: string, shapeId: string, measureSeconds: number, options: any?): any
	assert(RunService:IsStudio(), "R16TrialRunner is Studio-only")
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local piece = findPiece(pieceId)
	local spawnX = if options ~= nil then options.spawnX else nil
	if pieceId == "GapSmall" and spawnX == nil then
		spawnX = gapSpawnX(piece)
	end
	local racer = spawnCanonical(pieceId, shapeId, spawnX)
	local model = racer:GetModel()
	local body = racer:GetBody()
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

	if not waitForTrackContact(racer, acceptance.TrackContactTimeout, options) then
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
	result.motorsEnabled = allMotorsEnabled(model)
	result.completedPiece = maxX >= piece.StartX + piece.Length - 0.5
	R16TrialRunner.DestroyActive()
	return result
end

function R16TrialRunner.FindPiece(pieceId: string): any
	return findPiece(pieceId)
end

return R16TrialRunner
