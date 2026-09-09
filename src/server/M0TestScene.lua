--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local configFolder = shared:WaitForChild("Config")
local config = require(configFolder:WaitForChild("M0SceneConfig"))
local CollisionGroups = require(script.Parent.Runtime:WaitForChild("CollisionGroups"))

type PieceConfig = {
	AnchorName: string,
	PieceId: string,
	StartX: number,
	Length: number,
	Height: number?,
	Depth: number?,
	Gap: number?,
	Count: number?,
	Thickness: number?,
	GapWidth: number?,
	Clearance: number?,
	TunnelLength: number?,
	CeilingThickness: number?,
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

local function makeTrackPart(
	name: string,
	x0: number,
	x1: number,
	topY: number,
	height: number,
	parent: Instance,
	antiStallSurface: boolean?
): Part
	assert(x1 > x0, string.format("%s must have positive X length", name))
	assert(height > 0, string.format("%s must have positive height", name))

	local part = makePart(
		name,
		Vector3.new(x1 - x0, height, config.Lane.Width),
		Vector3.new((x0 + x1) / 2, topY - height / 2, 0),
		parent
	)
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.CollisionGroup = CollisionGroups.Track
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(115, 120, 130)
	part:SetAttribute("AntiStallSurface", antiStallSurface == true)
	return part
end

local function makeRaisedBlock(name: string, x0: number, x1: number, topY: number, parent: Instance): Part
	local height = topY - config.Lane.TopY
	assert(height > 0, string.format("%s must sit above baseline", name))
	return makeTrackPart(name, x0, x1, topY, height, parent)
end

local function buildFlatShort(piece: PieceConfig, parent: Instance)
	makeTrackPart("FlatFloor", piece.StartX, piece.StartX + piece.Length, config.Lane.TopY, config.Lane.Thickness, parent, true)
end

local function buildSmallSteps(piece: PieceConfig, parent: Instance)
	local height = assert(piece.Height, "SmallSteps missing Height")
	local depth = assert(piece.Depth, "SmallSteps missing Depth")
	local gap = assert(piece.Gap, "SmallSteps missing Gap")
	local count = assert(piece.Count, "SmallSteps missing Count")

	makeTrackPart("StepsFloor", piece.StartX, piece.StartX + piece.Length, config.Lane.TopY, config.Lane.Thickness, parent)

	local entry = (piece.Length - (count * depth + (count - 1) * gap)) / 2
	assert(entry >= 0, "SmallSteps defaults exceed piece length")
	for index = 1, count do
		local x0 = piece.StartX + entry + (index - 1) * (depth + gap)
		makeRaisedBlock(string.format("Step%d", index), x0, x0 + depth, config.Lane.TopY + height, parent)
	end
end

local function buildSingleWallLow(piece: PieceConfig, parent: Instance)
	local height = assert(piece.Height, "SingleWallLow missing Height")
	local thickness = assert(piece.Thickness, "SingleWallLow missing Thickness")
	makeTrackPart("WallFloor", piece.StartX, piece.StartX + piece.Length, config.Lane.TopY, config.Lane.Thickness, parent)

	local centerX = piece.StartX + piece.Length / 2
	local wall = makePart(
		"Wall",
		Vector3.new(thickness, height, config.Lane.Width),
		Vector3.new(centerX, config.Lane.TopY + height / 2, 0),
		parent
	)
	wall.CanCollide = true
	wall.CanTouch = true
	wall.CanQuery = true
	wall.CollisionGroup = CollisionGroups.Track
	wall.Material = Enum.Material.SmoothPlastic
	wall.Color = Color3.fromRGB(115, 120, 130)
end

local function buildGapSmall(piece: PieceConfig, parent: Instance)
	local gapWidth = assert(piece.GapWidth, "GapSmall missing GapWidth")
	local approachLength = (piece.Length - gapWidth) / 2
	assert(approachLength > 0, "GapSmall gap must fit inside piece")

	local gapStart = piece.StartX + approachLength
	local gapEnd = gapStart + gapWidth
	makeTrackPart("GapApproach", piece.StartX, gapStart, config.Lane.TopY, config.Lane.Thickness, parent)
	makeTrackPart("GapLanding", gapEnd, piece.StartX + piece.Length, config.Lane.TopY, config.Lane.Thickness, parent)
end

local function buildLowTunnelWide(piece: PieceConfig, parent: Instance)
	local clearance = assert(piece.Clearance, "LowTunnelWide missing Clearance")
	local tunnelLength = assert(piece.TunnelLength, "LowTunnelWide missing TunnelLength")
	local ceilingThickness = assert(piece.CeilingThickness, "LowTunnelWide missing CeilingThickness")
	local openLength = (piece.Length - tunnelLength) / 2
	assert(openLength >= 0, "LowTunnelWide tunnel must fit inside piece")

	makeTrackPart("TunnelFloor", piece.StartX, piece.StartX + piece.Length, config.Lane.TopY, config.Lane.Thickness, parent)
	local ceilingX0 = piece.StartX + openLength
	local ceilingX1 = ceilingX0 + tunnelLength
	local ceiling = makePart(
		"TunnelCeiling",
		Vector3.new(ceilingX1 - ceilingX0, ceilingThickness, config.Lane.Width),
		Vector3.new((ceilingX0 + ceilingX1) / 2, config.Lane.TopY + clearance + ceilingThickness / 2, 0),
		parent
	)
	ceiling.CanCollide = true
	ceiling.CanTouch = true
	ceiling.CanQuery = true
	ceiling.CollisionGroup = CollisionGroups.Track
	ceiling.Material = Enum.Material.SmoothPlastic
	ceiling.Color = Color3.fromRGB(115, 120, 130)
end

local BUILDERS = {
	FlatShort = buildFlatShort,
	SmallSteps = buildSmallSteps,
	SingleWallLow = buildSingleWallLow,
	GapSmall = buildGapSmall,
	LowTunnelWide = buildLowTunnelWide,
}

function M0TestScene.build()
	CollisionGroups.ensure()

	local tracksRoot = Workspace:WaitForChild("Runtime"):WaitForChild("Tracks")
	local existing = tracksRoot:FindFirstChild(config.SceneName)
	if existing then
		existing:Destroy()
	end

	local scene = Instance.new("Folder")
	scene.Name = config.SceneName
	scene.Parent = tracksRoot

	local obstacleLab = Instance.new("Folder")
	obstacleLab.Name = "ObstacleLab"
	obstacleLab.Parent = scene

	makeTrackPart("EntryFloor", 0, config.Pieces[1].StartX, config.Lane.TopY, config.Lane.Thickness, obstacleLab, true)

	for index, rawPiece in ipairs(config.Pieces) do
		local piece = rawPiece :: PieceConfig
		local builder = BUILDERS[piece.PieceId]
		assert(builder ~= nil, string.format("no M0 obstacle builder for %s", piece.PieceId))
		builder(piece, obstacleLab)

		local nextPiece = config.Pieces[index + 1]
		local recoveryEnd = if nextPiece ~= nil then nextPiece.StartX else config.Lane.Length
		local pieceEnd = piece.StartX + piece.Length
		if recoveryEnd > pieceEnd then
			makeTrackPart(
				string.format("RecoveryAfter%s", piece.PieceId),
				pieceEnd,
				recoveryEnd,
				config.Lane.TopY,
				config.Lane.Thickness,
				obstacleLab,
				true
			)
		end
	end

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

	for index, rawPiece in ipairs(config.Pieces) do
		local piece = rawPiece :: PieceConfig
		local marker = makePart(
			piece.AnchorName,
			Vector3.new(0.5, 0.2, config.Lane.Width),
			Vector3.new(piece.StartX, config.Lane.TopY + 0.1, 0),
			anchorsFolder
		)
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.Transparency = 0.35
		marker.Material = Enum.Material.Neon
		marker.Color = Color3.fromRGB(255, 210, 70)
		marker:SetAttribute("AnchorIndex", index)
		marker:SetAttribute("PieceId", piece.PieceId)
	end

	print("[DrawRacers] B15 canonical obstacle lab ready")
end

return M0TestScene
