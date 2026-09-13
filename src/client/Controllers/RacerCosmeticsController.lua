--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CosmeticsCatalog = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("CosmeticsCatalog")
)

local RIDER_NAME_PREFIX = "RiderPresentation_"

local RacerCosmeticsController = {}
RacerCosmeticsController.__index = RacerCosmeticsController

type Style = {
	Color: Color3?,
	Tint: Color3?,
	Material: Enum.Material?,
	PreserveBase: boolean?,
}

type BaseStyle = {
	Color: Color3,
	Material: Enum.Material,
}

type BaseStyleMap = { [BasePart]: BaseStyle }
type SignatureMap = { [Model]: string }
type RiderInstanceMap = { [Model]: Model }

local function captureBaseStyle(baseStyles: BaseStyleMap, part: BasePart)
	if baseStyles[part] == nil then
		baseStyles[part] = {
			Color = part.Color,
			Material = part.Material,
		}
	end
end

local function restoreBaseStyle(baseStyles: BaseStyleMap, part: BasePart)
	local base = baseStyles[part]
	if base == nil then
		return
	end
	part.Color = base.Color
	part.Material = base.Material
end

local function styleParts(root: Instance?, style: Style, tintOnly: boolean?, baseStyles: BaseStyleMap?)
	if root == nil then
		return
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			if tintOnly == true then
				if style.Tint ~= nil and descendant.Name ~= "HumanoidRootPart" then
					descendant.Color = style.Tint
				end
			else
				if baseStyles ~= nil then
					captureBaseStyle(baseStyles, descendant)
				end
				if style.PreserveBase == true and baseStyles ~= nil then
					restoreBaseStyle(baseStyles, descendant)
				else
					if style.Color ~= nil then
						descendant.Color = style.Color
					end
					if style.Material ~= nil then
						descendant.Material = style.Material
					end
				end
			end
		end
	end
end

local function selectedStyle(catalog: { [string]: Style }, requested: any, defaultId: string): (string, Style)
	local id = if type(requested) == "string" and catalog[requested] ~= nil then requested else defaultId
	return id, catalog[id]
end

local function presentationRoot(): Instance?
	local runtime = Workspace:FindFirstChild("Runtime")
	return if runtime ~= nil then runtime:FindFirstChild("RacePresentation") else nil
end

local function findRiderVisual(racer: Model): Model?
	local ownerUserId = racer:GetAttribute("OwnerUserId")
	if type(ownerUserId) ~= "number" or ownerUserId <= 0 then
		return nil
	end
	local root = presentationRoot()
	if root == nil then
		return nil
	end
	local candidate = root:FindFirstChild(RIDER_NAME_PREFIX .. tostring(ownerUserId))
	return if candidate and candidate:IsA("Model") then candidate else nil
end

local function applyLegStyle(racer: Model, style: Style, baseStyles: BaseStyleMap)
	local legs = racer:FindFirstChild("Legs")
	if legs == nil then
		return
	end
	for _, leg in legs:GetChildren() do
		if leg:IsA("Model") then
			styleParts(leg:FindFirstChild("Visual"), style, false, baseStyles)
		end
	end
end

local function applyCubeStyle(racer: Model, style: Style)
	styleParts(racer:FindFirstChild("VisualRoot"), style, false)
end

local function applyRiderStyle(rider: Model?, style: Style)
	styleParts(rider, style, true)
end

function RacerCosmeticsController.new()
	return setmetatable({
		_started = false,
		_connection = nil :: RBXScriptConnection?,
		_signatures = {} :: SignatureMap,
		_riderInstances = {} :: RiderInstanceMap,
		_baseLegStyles = setmetatable({}, { __mode = "k" }) :: BaseStyleMap,
	}, RacerCosmeticsController)
end

function RacerCosmeticsController:_applyRacer(racer: Model)
	local legId, legStyle = selectedStyle(
		CosmeticsCatalog.LegSkins,
		racer:GetAttribute("LegSkinId"),
		CosmeticsCatalog.DefaultLegSkinId
	)
	local cubeId, cubeStyle = selectedStyle(
		CosmeticsCatalog.CubeSkins,
		racer:GetAttribute("CubeSkinId"),
		CosmeticsCatalog.DefaultCubeSkinId
	)
	local riderId, riderStyle = selectedStyle(
		CosmeticsCatalog.RiderSkins,
		racer:GetAttribute("RiderSkinId"),
		CosmeticsCatalog.DefaultRiderSkinId
	)
	local rider = findRiderVisual(racer)
	local shapeVersion = racer:GetAttribute("ShapeVersion")
	local signature = table.concat({
		legId,
		cubeId,
		riderId,
		tostring(shapeVersion),
	}, "|")
	if self._signatures[racer] == signature and self._riderInstances[racer] == rider then
		return
	end

	applyLegStyle(racer, legStyle, self._baseLegStyles)
	applyCubeStyle(racer, cubeStyle)
	applyRiderStyle(rider, riderStyle)
	self._signatures[racer] = signature
	self._riderInstances[racer] = rider
end

function RacerCosmeticsController:_step()
	local runtime = Workspace:FindFirstChild("Runtime")
	local racers = runtime and runtime:FindFirstChild("Racers")
	if racers == nil then
		table.clear(self._signatures)
		table.clear(self._riderInstances)
		return
	end

	local active: { [Model]: boolean } = {}
	for _, candidate in racers:GetChildren() do
		if candidate:IsA("Model") then
			active[candidate] = true
			self:_applyRacer(candidate)
		end
	end
	for racer in self._signatures do
		if active[racer] ~= true then
			self._signatures[racer] = nil
			self._riderInstances[racer] = nil
		end
	end
end

function RacerCosmeticsController:Start()
	if self._started then
		return
	end
	self._started = true
	self._connection = RunService.RenderStepped:Connect(function()
		self:_step()
	end)
	self:_step()
end

function RacerCosmeticsController:Destroy()
	if not self._started then
		return
	end
	self._started = false
	if self._connection ~= nil then
		self._connection:Disconnect()
		self._connection = nil
	end
	table.clear(self._signatures)
	table.clear(self._riderInstances)
	table.clear(self._baseLegStyles)
end

return RacerCosmeticsController
