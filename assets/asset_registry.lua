--!strict

-- A04 asset registry source-of-truth. Entries stay empty until an asset is
-- actually produced/uploaded. Raw Roblox asset IDs must not be invented.

return {
	Schema = {
		"Key",
		"AssetType",
		"AssetId",
		"Owner",
		"SourcePath",
		"SourceHash",
		"LicenseOrOriginal",
		"ModerationState",
		"RuntimeUse",
		"ReleaseRequired",
	},
	Entries = {},
}
