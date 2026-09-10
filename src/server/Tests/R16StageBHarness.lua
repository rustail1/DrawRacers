--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local R16StageBHarness = {}

local started = false
local activeRacer: any = nil

local function findPiece(pieceId: string): any
	for _, piece in M0SceneConfig.Pieces do
		if piece.PieceId == pieceId then
			return piece
		end
	end
	error(string.format("missing canonical piece %s", pieceId))
end

local function hasTrackContact(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.CanTouch then
			for _, touchingPart in descendant:GetTouchingParts() do
				if not touchingPart:IsDescendantOf(model) and touchingPart.CollisionGroup == "Track" then
					return true
				end
			end
		end
	end
	return false
end

local function waitForTrackContact(racer: any, timeoutSeconds: number): boolean
	local elapsed = 0
	while elapsed < timeoutSeconds do
		if hasTrackContact(racer:GetModel()) then
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

local function destroyActiveRacer()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
end

local function spawnTrialRacer(pieceId: string, shapeId: string): any
	destroyActiveRacer()
	local piece = findPiece(pieceId)
	local racer = RacerRuntime.new({
		raceId = "R16_STAGE_B",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R16_STAGE_B",
		spawnCFrame = CFrame.new(piece.StartX + 1, 3.3, 0),
		laneCenterZ = 0,
	})
	activeRacer = racer
	local model = racer:GetModel()
	model:SetAttribute("R16StageBTrial", true)
	racer:ApplyShape(R16ReferenceShapes.Get(shapeId), true)
	-- ApplyShape is an internal Studio/test path and intentionally does not advance
	-- authoritative player ShapeVersion. Set a positive version so anti-stall behaves
	-- exactly as it would for an accepted player shape during this measurement.
	model:SetAttribute("ShapeVersion", 1)
	return racer
end

local function runFlatRoundTrial()
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local racer = spawnTrialRacer("FlatShort", "ROUND_01")
	local model = racer:GetModel()
	local body = racer:GetBody()

	if not waitForTrackContact(racer, acceptance.TrackContactTimeout) then
		warn("[DrawRacers][R16.5] ROUND_01 FlatShort FAIL no Track contact")
		destroyActiveRacer()
		return
	end

	task.wait(acceptance.FlatIgnoreSeconds)
	local startX = body.Position.X
	local elapsed = 0
	local antiStallSeen = false
	while elapsed < acceptance.FlatMeasureSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		if model:GetAttribute("AntiStallActive") == true then
			antiStallSeen = true
		end
	end

	local averageSpeedX = (body.Position.X - startX) / math.max(elapsed, 1e-6)
	local motorsEnabled = allMotorsEnabled(model)
	local passed = averageSpeedX >= acceptance.FlatSpeedMin
		and averageSpeedX <= acceptance.FlatSpeedMax
		and not antiStallSeen
		and motorsEnabled

	print(string.format(
		"[DrawRacers][R16.5] ROUND_01 FlatShort speed=%.3f target=%.1f..%.1f antiStall=%s motors=%s %s",
		averageSpeedX,
		acceptance.FlatSpeedMin,
		acceptance.FlatSpeedMax,
		tostring(antiStallSeen),
		tostring(motorsEnabled),
		if passed then "PASS" else "FAIL"
	))

	destroyActiveRacer()
end

function R16StageBHarness.start()
	assert(RunService:IsStudio(), "R16StageBHarness is Studio-only")
	if started then
		return
	end
	started = true
	print("[DrawRacers][R16B] Stage B reference measurement harness ready")

	task.spawn(function()
		local ok, err = xpcall(runFlatRoundTrial, debug.traceback)
		if not ok then
			warn("[DrawRacers][R16.5] flat measurement harness error: " .. tostring(err))
			destroyActiveRacer()
		end
	end)
end

function R16StageBHarness.stop()
	destroyActiveRacer()
	started = false
end

return R16StageBHarness
