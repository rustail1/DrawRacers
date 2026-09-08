--!strict

local DeploymentValidator = {}

local REQUIRED_PLATFORM_IDS = {
	"UniverseId",
	"EntryFTUEPlaceId",
	"RacePlaceId",
}

local SKU_FIELDS = {
	StarterStylePassId = true,
	NeonStylePassId = true,
	PremiumPresentationPassId = true,
	Coins450ProductId = true,
	Coins1100ProductId = true,
	Coins2500ProductId = true,
}

local function isResolvedId(value: any): boolean
	return type(value) == "number" and value > 0 and value % 1 == 0
end

function DeploymentValidator.assertResolved(config: { [string]: any })
	for _, key in REQUIRED_PLATFORM_IDS do
		if not isResolvedId(config[key]) then
			error(("deployment config unresolved: %s"):format(key), 2)
		end
	end
end

function DeploymentValidator.assertKnownPlace(config: { [string]: any }, placeId: number)
	if not isResolvedId(placeId) or config.PlaceModeById[placeId] == nil then
		error(("deployment config does not recognize PlaceId %s"):format(tostring(placeId)), 2)
	end
end

function DeploymentValidator.assertSkuResolved(config: { [string]: any }, skuField: string)
	if not SKU_FIELDS[skuField] then
		error(("unknown deployment SKU field: %s"):format(skuField), 2)
	end
	if not isResolvedId(config[skuField]) then
		error(("deployment SKU unresolved: %s"):format(skuField), 2)
	end
end

return DeploymentValidator
