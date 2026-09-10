--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Net"):WaitForChild("RemoteNames"))
local M0SceneConfig = require(
	shared:WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local StrokeRemoteTransport = require(script.Parent.Parent.Services:WaitForChild("StrokeRemoteTransport"))

local M0HumanHarness = {}

type PartState = {
	canCollide: boolean,
	canTouch: boolean,
	canQuery: boolean,
	anchored: boolean,
	transparency: number,
}

local started = false
local activePlayer: Player? = nil
local activeRacer: any = nil
local transportConnection: RBXScriptConnection? = nil
local playerAddedConnection: RBXScriptConnection? = nil
local playerRemovingConnection: RBXScriptConnection? = nil
local characterAddedConnection: RBXScriptConnection? = nil
local characterDescendantConnection: RBXScriptConnection? = nil
local recoveryConnection: RBXScriptConnection? = nil
local isolatedPartState: { [BasePart]: PartState } = {}

local function isolatePart(part: BasePart)
	if isolatedPartState[part] == nil then
		isolatedPartState[part] = {
			canCollide = part.CanCollide,
			canTouch = part.CanTouch,
			canQuery = part.CanQuery,
			anchored = part.Anchored,
			transparency = part.Transparency,
		}
	end
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
end

local function disconnectCharacterDescendantWatcher()
	if characterDescendantConnection then
		characterDescendantConnection:Disconnect()
		characterDescendantConnection = nil
	end
end

local function restoreCharacter()
	disconnectCharacterDescendantWatcher()
	for part, state in isolatedPartState do
		if part.Parent ~= nil then
			part.CanCollide = state.canCollide
			part.CanTouch = state.canTouch
			part.CanQuery = state.canQuery
			part.Anchored = state.anchored
			part.Transparency = state.transparency
		end
	end
	table.clear(isolatedPartState)
end

local function isolateCharacter(character: Model)
	-- A newly spawned Character must not re-enable or visually overlap the reference racer.
	-- Keep every still-parented Character part isolated and hidden until harness teardown;
	-- only move the descendant watcher when Roblox gives this player a newer Character.
	disconnectCharacterDescendantWatcher()

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			isolatePart(descendant)
		end
	end
	characterDescendantConnection = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			isolatePart(descendant)
		end
	end)

	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		root = character:WaitForChild("HumanoidRootPart", 5)
	end
	if root and root:IsA("BasePart") then
		isolatePart(root)
		root.Anchored = true
		local spawn = M0SceneConfig.Spawn
		local racerPosition = Vector3.new(spawn.X, spawn.Y, spawn.Z)
		local observerPosition = racerPosition + Vector3.new(-8, 7, 10)
		character:PivotTo(CFrame.lookAt(observerPosition, racerPosition))
	end
end

local function disconnectCharacterWatcher()
	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end
end

local function createActiveRacer(player: Player)
	local spawn = M0SceneConfig.Spawn
	local racer = RacerRuntime.new({
		raceId = "G0_HUMAN",
		slotIndex = 1,
		laneIndex = 1,
		isBot = false,
		trackId = "M0_G0",
		spawnCFrame = CFrame.new(spawn.X, spawn.Y, spawn.Z),
		laneCenterZ = spawn.Z,
	})
	local model = racer:GetModel()
	model:SetAttribute("DebugTarget", true)
	model:SetAttribute("OwnerUserId", player.UserId)
	activeRacer = racer
	return racer
end

local function respawnActiveRacer()
	local player = activePlayer
	local racer = activeRacer
	if player == nil or racer == nil then
		return
	end

	local shapeSpecBefore = racer:GetCurrentShapeSpec()
	local shapeVersionBefore = racer:GetShapeVersion()
	local model = racer:GetModel()
	local spawn = M0SceneConfig.Spawn

	model:PivotTo(CFrame.new(spawn.X, spawn.Y, spawn.Z))
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local shapeSpecAfter = racer:GetCurrentShapeSpec()
	local shapeVersionAfter = racer:GetShapeVersion()
	assert(shapeSpecAfter == shapeSpecBefore, "G0 recovery must preserve current ShapeSpec")
	assert(shapeVersionAfter == shapeVersionBefore, "G0 recovery must preserve ShapeVersion")
	print("[DrawRacers][R14.6] G0 racer recovered at canonical spawn")
end

local function destroyActiveRacer()
	disconnectCharacterWatcher()
	restoreCharacter()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
	activePlayer = nil
end

local function attachPlayer(player: Player)
	if activePlayer ~= nil then
		return
	end

	activePlayer = player
	characterAddedConnection = player.CharacterAdded:Connect(function(character)
		isolateCharacter(character)
	end)
	if player.Character then
		isolateCharacter(player.Character)
	end

	createActiveRacer(player)
	print("[DrawRacers][G0] human harness ready")
end

local function attachNextAvailablePlayer()
	if activePlayer ~= nil then
		return
	end
	local existingPlayers = Players:GetPlayers()
	if #existingPlayers > 0 then
		attachPlayer(existingPlayers[1])
	end
end

function M0HumanHarness.start()
	assert(RunService:IsStudio(), "M0HumanHarness is Studio-only")
	if started then
		return
	end
	started = true

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local submitStroke = remotes:WaitForChild(RemoteNames.SubmitStroke)
	local strokeResult = remotes:WaitForChild(RemoteNames.StrokeResult)

	transportConnection = StrokeRemoteTransport.Bind({
		submitStroke = submitStroke,
		strokeResult = strokeResult,
		resolveRacer = function(player)
			if player == activePlayer then
				return activeRacer
			end
			return nil
		end,
	})

	playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		attachPlayer(player)
	end)
	playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		if player == activePlayer then
			destroyActiveRacer()
			task.defer(attachNextAvailablePlayer)
		end
	end)

	recoveryConnection = RunService.Heartbeat:Connect(function()
		local racer = activeRacer
		if racer == nil then
			return
		end
		local ok, body = pcall(function()
			return racer:GetBody()
		end)
		if ok and body ~= nil and body.Position.Y < M0SceneConfig.RecoveryKillY then
			respawnActiveRacer()
		end
	end)

	attachNextAvailablePlayer()
end

function M0HumanHarness.stop()
	if recoveryConnection then
		recoveryConnection:Disconnect()
		recoveryConnection = nil
	end
	if transportConnection then
		transportConnection:Disconnect()
		transportConnection = nil
	end
	if playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
	if playerRemovingConnection then
		playerRemovingConnection:Disconnect()
		playerRemovingConnection = nil
	end
	destroyActiveRacer()
	started = false
end

return M0HumanHarness