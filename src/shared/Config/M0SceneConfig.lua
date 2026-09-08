--!strict

-- A03 Studio-only M0 physics-lab scene contract.
-- Coordinates follow the production convention: +X travel, Y up, Z lane center.
-- The five anchor X positions are derived from canonical default piece lengths in doc 60
-- with the default 10-stud recovery spacing between representative pieces.

return {
	SceneName = "M0TestScene",
	Lane = {
		Length = 180,
		Width = 8,
		Thickness = 2,
		TopY = 0,
	},
	Spawn = {
		X = 4,
		Y = 3,
		Z = 0,
	},
	Anchors = {
		{ Name = "FlatAnchor", PieceId = "FlatShort", X = 10 },
		{ Name = "StepsAnchor", PieceId = "SmallSteps", X = 38 },
		{ Name = "WallAnchor", PieceId = "SingleWallLow", X = 76 },
		{ Name = "GapAnchor", PieceId = "GapSmall", X = 106 },
		{ Name = "TunnelAnchor", PieceId = "LowTunnelWide", X = 140 },
	},
}
