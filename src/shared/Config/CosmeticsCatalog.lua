--!strict

return {
	DefaultLegSkinId = "Default",
	DefaultCubeSkinId = "Default",
	DefaultRiderSkinId = "Default",

	LegSkins = {
		-- Neutral default: preserve the intrinsic Left/Right presentation colors
		-- and base material owned by LegAssembly. Explicit skins may override them.
		Default = {},
	},

	CubeSkins = {
		Default = {
			Color = Color3.fromRGB(242, 242, 242),
			Material = Enum.Material.SmoothPlastic,
		},
	},

	RiderSkins = {
		Default = {
			Tint = nil,
		},
	},
}
