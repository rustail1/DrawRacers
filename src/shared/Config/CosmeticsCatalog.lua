--!strict

return {
	DefaultLegSkinId = "Default",
	DefaultCubeSkinId = "Default",
	DefaultRiderSkinId = "Default",

	LegSkins = {
		-- Neutral default: restore the intrinsic Left/Right presentation colors
		-- and base material owned by LegAssembly after any explicit cosmetic skin.
		Default = {
			PreserveBase = true,
		},
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
