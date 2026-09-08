--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local configFolder = shared:WaitForChild("Config")
local config = require(configFolder:WaitForChild("M0SceneConfig"))
local CollisionGroups = require(script.Parent.Runtime:WaitForChild("CollisionGroups"))

type AnchorConfig = {
	Name: string,
	PieceId: string,
	X: number,
}

local M0TestScene = {}

local function makePart(name: string, size: Vector3, position: Vector3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function M0TestScene.build()
	CollisionGroups.ensure()

	local existing = workspace:FindFirstChild(config.SceneName)
	if existing then
		existing:Destroy()
	end

	local scene = Instance.new("Folder")
	scene.Name = config.SceneName
	scene.Parent = workspace

	local lane = makePart(
		"FlatLane",
		Vector3.new(config.Lane.Length, config.Lane.Thickness, config.Lane.Width),
		Vector3.new(config.Lane.Length / 2, config.Lane.TopY - config.Lane.Thickness / 2, 0),
		scene
	)
	lane.CanCollide = true
	lane.CanTouch = true
	lane.CanQuery = true
	lane.CollisionGroup = CollisionGroups.Track
	lane.Material = Enum.Material.SmoothPlastic
	lane.Color = Color3.fromRGB(115, 120, 130)

	local debugSpawn = Instance.new("SpawnLocation")
	debugSpawn.Name = "DebugSpawn"
	debugSpawn.Anchored = true
	debugSpawn.CanCollide = false
	debugSpawn.CanTouch = false
	debugSpawn.CanQuery = false
	debugSpawn.Size = Vector3.new(1, 1, 1)
	debugSpawn.Position = Vector3.new(config.Spawn.X, config.Spawn.Y, config.Spawn.Z)
	debugSpawn.Neutral = true
	debugSpawn.AllowTeamChangeOnTouch = false
	debugSpawn.Duration = 0
	debugSpawn.Transparency = 0.35
	debugSpawn.Material = Enum.Material.Neon
	debugSpawn.Color = Color3.fromRGB(80, 220, 120)
	debugSpawn.Parent = scene

	local anchorsFolder = Instance.new("Folder")
	anchorsFolder.Name = "ObstacleAnchors"
	anchorsFolder.Parent = scene

	for index, rawAnchor in ipairs(config.Anchors) do
		local anchorConfig = rawAnchor :: AnchorConfig
		local marker = makePart(
			anchorConfig.Name,
			Vector3.new(0.5, 0.2, config.Lane.Width),
			Vector3.new(anchorConfig.X, config.Lane.TopY + 0.1, 0),
			anchorsFolder
		)
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.Transparency = 0.35
		marker.Material = Enum.Material.Neon
		marker.Color = Color3.fromRGB(255, 210, 70)
		marker:SetAttribute("AnchorIndex", index)
		marker:SetAttribute("PieceId", anchorConfig.PieceId)
	end

	print("[DrawRacers] A03 M0 test scene ready")
end

return M0TestScene
