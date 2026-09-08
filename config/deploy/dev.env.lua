--!strict

-- A04 deployment source-of-truth. Public platform IDs are intentionally nil
-- until Roblox provisioning produces real values. Never replace nil with guesses.

return {
	EnvironmentName = "DEV",
	UniverseId = nil,
	EntryFTUEPlaceId = nil,
	RacePlaceId = nil,
	PlaceModeById = {},
	DataStoreNamespace = "DrawRacers_DEV_v1",
	AnalyticsEnvironment = "DEV",
	MonetizationEnabled = false,
	BotsEnabled = false,
	StarterStylePassId = nil,
	NeonStylePassId = nil,
	PremiumPresentationPassId = nil,
	Coins450ProductId = nil,
	Coins1100ProductId = nil,
	Coins2500ProductId = nil,
}
