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

local function findPiece(pieceId: string): any
	for _, piece in M0SceneConfig.Pieces do
		if piece.PieceId == pieceId then
			return piece
		end
	end
	error(string.format("missing canonical piece %s", pieceId))
end

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

local function spawnWallRacer(shapeId: string): any
	destroyActiveRacer()
	local piece = findPiece("SingleWallLow")
	local racer = RacerRuntime.new({
		raceId = "R16_STAGE_C_WALL",
		slotIndex = 7,
		laneIndex = 1,
		isBot = true,
		trackId = "M0_R16_STAGE_C",
		spawnCFrame = CFrame.new(piece.StartX + 1, 3.3, 0),
		laneCenterZ = 0,
	})
	activeRacer = racer
	local model = racer:GetModel()
	model:SetAttribute("R16StageCTrial", true)
	racer:ApplyShape(R16ReferenceShapes.Get(shapeId), true)
	model:SetAttribute("ShapeVersion", 1)
	return racer
end

local function runWallShape(shapeId: string): boolean
	local acceptance = M0SceneConfig.ReferenceAcceptance
	local piece = findPiece("SingleWallLow")
	local racer = spawnWallRacer(shapeId)
	local body = racer:GetBody()

	local contactedWall = waitForTrackContact(racer, acceptance.WallContactTimeout, "Wall")
	if not contactedWall then
		print(string.format("[DrawRacers][R16.10] wall shape=%s contact=false completed=false FAIL", shapeId))
		destroyActiveRacer()
		return false
	end

	local maxX = body.Position.X
	local elapsed = 0
	while elapsed < acceptance.WallMeasureSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		maxX = math.max(maxX, body.Position.X)
		if body.Position.Y < M0SceneConfig.RecoveryKillY then
			break
		end
	end

	local completed = maxX >= piece.StartX + piece.Length - 0.5
	print(string.format(
		"[DrawRacers][R16.10] wall shape=%s contact=%s maxX=%.2f target>=%.2f completed=%s %s",
		shapeId,
		tostring(contactedWall),
		maxX,
		piece.StartX + piece.Length - 0.5,
		tostring(completed),
		if completed then "PASS" else "FAIL"
	))
	destroyActiveRacer()
	return completed
end

local function runWallTrial(): boolean
	local hookPassed = runWallShape("HOOK_01")
	local longBarPassed = runWallShape("LONG_BAR_01")
	local wallPassed = hookPassed or longBarPassed
	print(string.format(
		"[DrawRacers][R16.10] wall summary hook=%s longBar=%s wallPassed=%s",
		tostring(hookPassed),
		tostring(longBarPassed),
		tostring(wallPassed)
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

local function getLegRoot(legsFolder: Folder, legName: string): Part?
	local leg = legsFolder:FindFirstChild(legName)
	if leg == nil or not leg:IsA("Model") then
		return nil
	end
	local root = leg:FindFirstChild("LegRoot")
	if root == nil or not root:IsA("Part") then
		return nil
	end
	return root
end

local function phaseDegrees(hub: Part, root: Part): number
	local relative = hub.CFrame:ToObjectSpace(root.CFrame)
	local _, _, z = relative:ToOrientation()
	return math.deg(z)
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
	local leftHub = model:FindFirstChild("LeftHub")
	local rightHub = model:FindFirstChild("RightHub")
	if legsFolder == nil or not legsFolder:IsA("Folder")
		or leftHub == nil or not leftHub:IsA("Part")
		or rightHub == nil or not rightHub:IsA("Part")
	then
		destroyActiveRacer()
		return false
	end

	local seed = LegShapeService.ValidateAndBuild(racer, R16ReferenceShapes.Get("ROUND_01"), true)
	if seed.accepted ~= true or not waitForTrackContact(racer, acceptance.TrackContactTimeout, nil) then
		print("[DrawRacers][R16.10] live moving redraw seed/contact FAIL")
		destroyActiveRacer()
		return false
	end

	waitHeartbeatSeconds(acceptance.MovingRedrawSettleSeconds)
	local startX = movingBody.Position.X
	local movingRedrawPassed = true

	for redrawIndex = 1, 10 do
		waitHeartbeatSeconds(acceptance.MovingRedrawStepSeconds)
		local leftRootBefore = getLegRoot(legsFolder, "LeftLeg")
		local rightRootBefore = getLegRoot(legsFolder, "RightLeg")
		if leftRootBefore == nil or rightRootBefore == nil then
			movingRedrawPassed = false
			break
		end

		local bodyCFrameBeforeRedraw = movingBody.CFrame
		local linearBeforeRedraw = movingBody.AssemblyLinearVelocity
		local angularBeforeRedraw = movingBody.AssemblyAngularVelocity
		local versionBeforeRedraw = racer:GetShapeVersion()
		local leftPhaseBeforeRedraw = phaseDegrees(leftHub, leftRootBefore)
		local rightPhaseBeforeRedraw = phaseDegrees(rightHub, rightRootBefore)
		local shapeId = if redrawIndex % 2 == 0 then "ROUND_01" else "ASYM_01"

		local result = LegShapeService.ValidateAndBuild(racer, R16ReferenceShapes.Get(shapeId), true)
		if result.accepted ~= true
			or result.shapeVersion ~= versionBeforeRedraw + 1
			or racer:GetShapeVersion() ~= versionBeforeRedraw + 1
			or countLegModels(legsFolder) ~= 2
			or legsFolder:FindFirstChild("LeftLeg_Retiring") ~= nil
			or legsFolder:FindFirstChild("RightLeg_Retiring") ~= nil
			or movingBody.CFrame ~= bodyCFrameBeforeRedraw
			or movingBody.AssemblyLinearVelocity ~= linearBeforeRedraw
			or movingBody.AssemblyAngularVelocity ~= angularBeforeRedraw
		then
			movingRedrawPassed = false
			break
		end

		local leftRootAfter = getLegRoot(legsFolder, "LeftLeg")
		local rightRootAfter = getLegRoot(legsFolder, "RightLeg")
		if leftRootAfter == nil or rightRootAfter == nil then
			movingRedrawPassed = false
			break
		end
		local leftPhaseAfterRedraw = phaseDegrees(leftHub, leftRootAfter)
		local rightPhaseAfterRedraw = phaseDegrees(rightHub, rightRootAfter)
		local leftPhaseOk = angularDistanceDegrees(leftPhaseAfterRedraw, leftPhaseBeforeRedraw) <= 5.0
		local rightPhaseOk = angularDistanceDegrees(rightPhaseAfterRedraw, rightPhaseBeforeRedraw) <= 5.0
		if not leftPhaseOk or not rightPhaseOk then
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

function R16StageCHarness.start()
	assert(RunService:IsStudio(), "R16StageCHarness is Studio-only")
	if started then
		return
	end
	started = true
	print("[DrawRacers][R16C] final reference-parity harness ready")

	task.spawn(function()
		local ok, err = xpcall(function()
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
		end, debug.traceback)
		if not ok then
			warn("[DrawRacers][R16C] final harness error: " .. tostring(err))
			destroyActiveRacer()
		end
	end)
end

function R16StageCHarness.stop()
	R16StageBHarness.stop()
	destroyActiveRacer()
	started = false
end

return R16StageCHarness
