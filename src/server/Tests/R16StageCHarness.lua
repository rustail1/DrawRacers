--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))
local R16TrialRunner = require(script.Parent:WaitForChild("R16TrialRunner"))
local R16StageBHarness = require(script.Parent:WaitForChild("R16StageBHarness"))

local R16StageCHarness = {}

local CANONICAL_PIECES = {
	"FlatShort",
	"SmallSteps",
	"SingleWallLow",
	"GapSmall",
	"LowTunnelWide",
}

local started = false
local activeRacer: any = nil

local function hasTrackContact(model: Model, partName: string?): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.CanTouch then
			for _, touchingPart in descendant:GetTouchingParts() do
				if not touchingPart:IsDescendantOf(model)
					and touchingPart.CollisionGroup == "Track"
					and (partName == nil or touchingPart.Name == partName)
				then
					return true
				end
			end
		end
	end
	return false
end

local function waitForTrackContact(racer: any, timeoutSeconds: number, partName: string?): boolean
	local elapsed = 0
	while elapsed < timeoutSeconds do
		if hasTrackContact(racer:GetModel(), partName) then
			return true
		end
		elapsed += RunService.Heartbeat:Wait()
	end
	return false
end

local function waitHeartbeatSeconds(seconds: number)
	local elapsed = 0
	while elapsed < seconds do
		elapsed += RunService.Heartbeat:Wait()
	end
end

local function destroyActiveRacer()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
end

local function verifyCanonicalPieces(): boolean
	local configured: { [string]: boolean } = {}
	for _, piece in M0SceneConfig.Pieces do
		configured[piece.PieceId] = true
	end

	local runtime = Workspace:FindFirstChild("Runtime")
	local tracks = runtime and runtime:FindFirstChild("Tracks")
	local scene = tracks and tracks:FindFirstChild(M0SceneConfig.SceneName)
	local anchors = scene and scene:FindFirstChild("ObstacleAnchors")
	if anchors == nil then
		warn("[DrawRacers][R16.10] canonical anchors missing")
		return false
	end

	local anchored: { [string]: boolean } = {}
	for _, marker in anchors:GetChildren() do
		local pieceId = marker:GetAttribute("PieceId")
		if type(pieceId) == "string" then
			anchored[pieceId] = true
		end
	end

	for _, pieceId in CANONICAL_PIECES do
		if configured[pieceId] ~= true or anchored[pieceId] ~= true then
			warn(string.format("[DrawRacers][R16.10] canonical piece missing from config/scene: %s", pieceId))
			return false
		end
	end
	return true
end

local function runWallTrial(): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local options = {
		contactName = "Wall",
		contactTimeout = acceptance.WallContactTimeout,
	}
	local hook = R16TrialRunner.RunPiece("SingleWallLow", "HOOK_01", acceptance.WallMeasureSeconds, options)
	local longBar = R16TrialRunner.RunPiece("SingleWallLow", "LONG_BAR_01", acceptance.WallMeasureSeconds, options)
	local suboptimal = R16TrialRunner.RunPiece("SingleWallLow", "SUBOPTIMAL_01", acceptance.WallMeasureSeconds, options)
	local wallGoodPassed = hook.completedPiece or longBar.completedPiece
	local wallBadPassed = suboptimal.valid and not suboptimal.completedPiece
	local wallPassed = wallGoodPassed and wallBadPassed
	print(string.format(
		"[DrawRacers][R16.10] wall summary hook=%s longBar=%s suboptimal=%s good=%s bad=%s wallPassed=%s %s",
		tostring(hook.completedPiece),
		tostring(longBar.completedPiece),
		tostring(suboptimal.completedPiece),
		tostring(wallGoodPassed),
		tostring(wallBadPassed),
		tostring(wallPassed),
		if wallPassed then "PASS" else "FAIL"
	))
	return wallPassed
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

local function angularDistanceDegrees(a: number, b: number): number
	local delta = (a - b + 180) % 360 - 180
	return math.abs(delta)
end

local function runLiveMovingRedrawTrial(): boolean
	destroyActiveRacer()
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local racer = RacerRuntime.new({
		raceId = "R16_STAGE_C_REDRAW",
		slotIndex = 8,
		laneIndex = 1,
		isBot = false,
		trackId = "M0_R16_STAGE_C",
		spawnCFrame = CFrame.new(M0SceneConfig.Spawn.X, 3.3, 0),
		laneCenterZ = 0,
	})
	activeRacer = racer
	local model = racer:GetModel()
	model:SetAttribute("R16StageCTrial", true)
	local movingBody = racer:GetBody()
	local legsFolder = model:FindFirstChild("Legs")
	if legsFolder == nil or not legsFolder:IsA("Folder") then
		destroyActiveRacer()
		return false
	end

	local seed = LegShapeService.ValidateAndBuild(racer, R16ReferenceShapes.Get("ROUND_01"), true)
	if seed.accepted ~= true
		or racer:GetLegPair() == nil
		or countAxleRoots(legsFolder) ~= 1
		or not waitForTrackContact(racer, acceptance.TrackContactTimeout, nil)
	then
		print("[DrawRacers][R16.10] live moving redraw seed/contact FAIL")
		destroyActiveRacer()
		return false
	end

	waitHeartbeatSeconds(acceptance.MovingRedrawSettleSeconds)
	local startX = movingBody.Position.X
	local movingRedrawPassed = true

	for redrawIndex = 1, 10 do
		waitHeartbeatSeconds(acceptance.MovingRedrawStepSeconds)
		local pairBeforeRedraw = racer:GetLegPair()
		if pairBeforeRedraw == nil then
			movingRedrawPassed = false
			break
		end

		local bodyCFrameBeforeRedraw = movingBody.CFrame
		local linearBeforeRedraw = movingBody.AssemblyLinearVelocity
		local angularBeforeRedraw = movingBody.AssemblyAngularVelocity
		local versionBeforeRedraw = racer:GetShapeVersion()
		local phaseBeforeRedraw = pairBeforeRedraw:GetPhaseDegrees()
		local shapeId = if redrawIndex % 2 == 0 then "ROUND_01" else "ASYM_01"

		local result = LegShapeService.ValidateAndBuild(racer, R16ReferenceShapes.Get(shapeId), true)
		if result.accepted ~= true
			or result.shapeVersion ~= versionBeforeRedraw + 1
			or racer:GetShapeVersion() ~= versionBeforeRedraw + 1
			or countLegModels(legsFolder) ~= 2
			or countAxleRoots(legsFolder) ~= 1
			or legsFolder:FindFirstChild("LeftLeg_Retiring") ~= nil
			or legsFolder:FindFirstChild("RightLeg_Retiring") ~= nil
			or legsFolder:FindFirstChild("AxleRoot_Retiring") ~= nil
			or movingBody.CFrame ~= bodyCFrameBeforeRedraw
			or movingBody.AssemblyLinearVelocity ~= linearBeforeRedraw
			or movingBody.AssemblyAngularVelocity ~= angularBeforeRedraw
		then
			movingRedrawPassed = false
			break
		end

		local pairAfterRedraw = racer:GetLegPair()
		if pairAfterRedraw == nil or pairAfterRedraw == pairBeforeRedraw then
			movingRedrawPassed = false
			break
		end
		local phaseAfterRedraw = pairAfterRedraw:GetPhaseDegrees()
		local phasePreserved = angularDistanceDegrees(phaseAfterRedraw, phaseBeforeRedraw) <= 5.0
		if not phasePreserved then
			movingRedrawPassed = false
			break
		end
	end

	local progress = movingBody.Position.X - startX
	movingRedrawPassed = movingRedrawPassed and progress >= acceptance.MovingRedrawMinProgress
	print(string.format(
		"[DrawRacers][R16.10] live redraw progress=%.3f target>=%.2f version=%d movingRedrawPassed=%s %s",
		progress,
		acceptance.MovingRedrawMinProgress,
		racer:GetShapeVersion(),
		tostring(movingRedrawPassed),
		if movingRedrawPassed then "PASS" else "FAIL"
	))
	destroyActiveRacer()
	return movingRedrawPassed
end

function R16StageCHarness.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R16StageCHarness evidence is Studio-only")
	local piecesPassed = verifyCanonicalPieces()
	local stageBPassed = R16StageBHarness.RunEvidence()
	local wallPassed = runWallTrial()
	local movingRedrawPassed = runLiveMovingRedrawTrial()
	local passed = piecesPassed and stageBPassed and wallPassed and movingRedrawPassed
	print(string.format(
		"[DrawRacers][R16.10] canonical pass pieces=%s stageB=%s wall=%s movingRedraw=%s %s",
		tostring(piecesPassed),
		tostring(stageBPassed),
		tostring(wallPassed),
		tostring(movingRedrawPassed),
		if passed then "PASS" else "FAIL"
	))
	return passed
end

function R16StageCHarness.start()
	assert(RunService:IsStudio(), "R16StageCHarness is Studio-only")
	if started then
		return
	end
	started = true
	print("[DrawRacers][R16C] final reference-parity harness ready")

	-- Preserve the standalone R16C mode's asynchronous behavior. R16FINAL calls
	-- RunEvidence synchronously so StudioGate READY cannot race ahead of evidence.
	task.spawn(function()
		local ok, result = xpcall(function()
			return R16StageCHarness.RunEvidence()
		end, debug.traceback)
		if not ok then
			warn("[DrawRacers][R16C] final harness error: " .. tostring(result))
			R16TrialRunner.DestroyActive()
			destroyActiveRacer()
		elseif result ~= true then
			warn("[DrawRacers][R16C] one or more final evidence checks FAILED")
		end
	end)
end

function R16StageCHarness.stop()
	R16StageBHarness.stop()
	R16TrialRunner.DestroyActive()
	destroyActiveRacer()
	started = false
end

return R16StageCHarness