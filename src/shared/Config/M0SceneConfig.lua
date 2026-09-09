--!strict

return {
	SceneName = "M0_TestScene",
	Spawn = {
		X = 4,
		Y = 3,
		Z = 0,
	},
	RecoveryKillY = -12,
	Lane = {
		CenterZ = 0,
		Width = 12,
		FloorThickness = 1,
		TopY = 0,
	},
	Segments = {
		FlatStart = {
			CenterX = 20,
			Length = 40,
		},
		StepUp = {
			CenterX = 46,
			Length = 12,
			Height = 1.5,
		},
		WallLow = {
			CenterX = 62,
			Length = 12,
			WallHeight = 2.5,
			WallThickness = 1,
		},
		GapSmall = {
			CenterX = 78,
			Length = 16,
			GapWidth = 4,
		},
		TunnelLow = {
			CenterX = 98,
			Length = 16,
			Clearance = 4.2,
			CeilingThickness = 1,
		},
	},
}
