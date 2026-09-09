--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local StrokeRemoteTransport = require(script.Parent.Parent.Services:WaitForChild("StrokeRemoteTransport"))

local M0HumanHarness = {}

type PartState = {
	canCollide: boolean,
	canTouch: boolean,
	canQuery: boolean,
	anchored: boolean,
}

local started = false
local activePlayer: Player? = nil
local activeRacer: any = nil
local transportConnection: RBXScriptConnection? = nil
local playerAddedConnection: RBXScriptConnection? = nil
local playerRemovingConnection: RBXScriptConnection? = nil
local characterAddedConnection: RBXScriptConnection? = nil
local characterDescendantConnection: RBXScriptConnection? = nil
local isolatedPartState: { [BasePart]: PartState } = {}

local function isolatePart(part: BasePart)
	if isolatedPartState[part] == nil then
		isolatedPartState[part] = {
			canCollide = part.CanCollide,
			canTouch = part.CanTouch,
			canQuery = part.CanQuery,
			anchored = part.Anchored,
		}
	end
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

local function restoreCharacter()
	if characterDescendantConnection then
		characterDescendantConnection:Disconnect()
		characterDescendantConnection = nil
	end
	for part, state in isolatedPartState do
		if part.Parent ~= nil then
			part.CanCollide = state.canCollide
			part.CanTouch = state.canTouch
			part.CanQuery = state.canQuery
			part.Anchored = state.anchored
		end
	end
	table.clear(isolatedPartState)
end

local function isolateCharacter(character: Model)
	restoreCharacter()

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

	activePlayer = player
	activeRacer = racer
	characterAddedConnection = player.CharacterAdded:Connect(function(character)
		isolateCharacter(character)
	end)
	if player.Character then
		task.defer(isolateCharacter, player.Character)
	end
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
	local submitStroke = remotes:WaitForChild("SubmitStroke")
	local strokeResult = remotes:WaitForChild("StrokeResult")

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

	attachNextAvailablePlayer()
end

function M0HumanHarness.stop()
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
