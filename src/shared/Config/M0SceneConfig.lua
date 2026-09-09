--!strict

-- M0 physics-lab scene contract.
-- Coordinates follow the production convention: +X travel, Y up, Z lane center.
-- The five canonical B15 pieces use doc 60 defaults with 10-stud recovery spacing.

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
	RecoveryKillY = -12,
	Pieces = {
		{
			AnchorName = "FlatAnchor",
			PieceId = "FlatShort",
			StartX = 10,
			Length = 18,
		},
		{
			AnchorName = "StepsAnchor",
			PieceId = "SmallSteps",
			StartX = 38,
			Length = 28,
			Height = 1.5,
			Depth = 4.0,
			Gap = 1.0,
			Count = 5,
		},
		{
			AnchorName = "WallAnchor",
			PieceId = "SingleWallLow",
			StartX = 76,
			Length = 20,
			Height = 2.6,
			Thickness = 2.0,
		},
		{
			AnchorName = "GapAnchor",
			PieceId = "GapSmall",
			StartX = 106,
			Length = 24,
			GapWidth = 3.2,
		},
		{
			AnchorName = "TunnelAnchor",
			PieceId = "LowTunnelWide",
			StartX = 140,
			Length = 28,
			Clearance = 4.25,
			TunnelLength = 16,
			CeilingThickness = 2,
		},
	},
}
