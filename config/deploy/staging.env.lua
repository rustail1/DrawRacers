--!strict

-- A04 deployment source-of-truth. Public platform IDs are intentionally nil
-- until Roblox provisioning produces real values. Never replace nil with guesses.

return {
	EnvironmentName = "STAGING",
	UniverseId = nil,
	EntryFTUEPlaceId = nil,
	RacePlaceId = nil,
	PlaceModeById = {},
	DataStoreNamespace = "DrawRacers_STAGING_v1",
	AnalyticsEnvironment = "STAGING",
	MonetizationEnabled = false,
	BotsEnabled = true,
	StarterStylePassId = nil,
	NeonStylePassId = nil,
	PremiumPresentationPassId = nil,
	Coins450ProductId = nil,
	Coins1100ProductId = nil,
	Coins2500ProductId = nil,
}
