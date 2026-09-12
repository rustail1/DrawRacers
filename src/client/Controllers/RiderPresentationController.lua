--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RIDER_SCALE = 0.65
local RIDER_MOUNT_X_OFFSET = -0.15
local RIDER_SEAT_CLEARANCE = 0.05
local RIDER_NAME_PREFIX = "RiderPresentation_"

local RiderPresentationController = {}
RiderPresentationController.__index = RiderPresentationController

type RiderRecord = {
	visual: Model,
	sourceCharacter: Model,
	seatPart: BasePart,
}

local function canonicalJointName(name: string): string
	return string.gsub(string.lower(name), "%s", "")
end

local function applyJockeyPose(visual: Model)
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("Motor6D") then
			local name = canonicalJointName(descendant.Name)
			if string.find(name, "rightshoulder", 1, true) then
				descendant.Transform = CFrame.Angles(math.rad(-32), 0, math.rad(18))
			elseif string.find(name, "leftshoulder", 1, true) then
				descendant.Transform = CFrame.Angles(math.rad(-32), 0, math.rad(-18))
			elseif string.find(name, "righthip", 1, true) then
				descendant.Transform = CFrame.Angles(math.rad(48), 0, math.rad(24))
			elseif string.find(name, "lefthip", 1, true) then
				descendant.Transform = CFrame.Angles(math.rad(48), 0, math.rad(-24))
			elseif name == "waist" then
				descendant.Transform = CFrame.Angles(math.rad(-10), 0, 0)
			end
		end
	end
end

local function sanitizeVisual(visual: Model)
	-- Preserve cosmetic Accessory instances (hat/hair/etc.). Their handles are
	-- made nonphysical below just like every other visual BasePart. Only objects
	-- that can execute code or behave as player-held gameplay tools are removed.
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("Tool")
			or descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
		then
			descendant:Destroy()
		end
	end

	local humanoid = visual:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid:Destroy()
	end

	local root = visual:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		visual.PrimaryPart = root
	end

	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.Anchored = descendant.Name == "HumanoidRootPart"
			descendant.LocalTransparencyModifier = 0
			if descendant.Name == "HumanoidRootPart" then
				descendant.Transparency = 1
			else
				descendant.Transparency = 0
			end
		end
	end
end

local function findSeatPart(visual: Model): BasePart?
	for _, name in { "LowerTorso", "Torso", "HumanoidRootPart" } do
		local candidate = visual:FindFirstChild(name, true)
		if candidate and candidate:IsA("BasePart") then
			return candidate
		end
	end
	return nil
end

local function cloneCharacterVisual(character: Model): Model?
	local oldArchivable = character.Archivable
	character.Archivable = true
	local ok, cloned = pcall(function()
		return character:Clone()
	end)
	character.Archivable = oldArchivable
	if not ok or cloned == nil or not cloned:IsA("Model") then
		return nil
	end

	local visual = cloned :: Model
	visual.Name = RIDER_NAME_PREFIX .. character.Name
	sanitizeVisual(visual)
	visual:ScaleTo(RIDER_SCALE)
	applyJockeyPose(visual)
	return visual
end

local function getPresentationRoot(): Instance?
	local runtime = Workspace:FindFirstChild("Runtime")
	if runtime == nil then
		return nil
	end
	return runtime:FindFirstChild("RacePresentation")
end

local function resolveOwnerPlayer(racer: Model): Player?
	local ownerUserId = racer:GetAttribute("OwnerUserId")
	if type(ownerUserId) ~= "number" or ownerUserId <= 0 then
		return nil
	end
	return Players:GetPlayerByUserId(ownerUserId)
end

local function findBody(racer: Model): BasePart?
	local body = racer:FindFirstChild("BodyCollider")
	if body and body:IsA("BasePart") then
		return body
	end
	return nil
end

function RiderPresentationController.new()
	local self = setmetatable({
		_started = false,
		_connection = nil :: RBXScriptConnection?,
		_records = {} :: { [Model]: RiderRecord },
	}, RiderPresentationController)
	return self
end

function RiderPresentationController:_destroyRecord(racer: Model)
	local record = self._records[racer]
	if record == nil then
		return
	end
	if record.visual.Parent ~= nil then
		record.visual:Destroy()
	end
	self._records[racer] = nil
end

function RiderPresentationController:_ensureRecord(racer: Model, player: Player): RiderRecord?
	local character = player.Character
	if character == nil then
		self:_destroyRecord(racer)
		return nil
	end
	if not player:HasAppearanceLoaded() then
		self:_destroyRecord(racer)
		return nil
	end

	local existing = self._records[racer]
	if existing ~= nil and existing.sourceCharacter == character and existing.visual.Parent ~= nil then
		return existing
	end
	self:_destroyRecord(racer)

	local presentationRoot = getPresentationRoot()
	if presentationRoot == nil then
		return nil
	end
	local visual = cloneCharacterVisual(character)
	if visual == nil then
		return nil
	end
	local seatPart = findSeatPart(visual)
	if seatPart == nil then
		visual:Destroy()
		return nil
	end
	visual.Name = string.format("%s%d", RIDER_NAME_PREFIX, player.UserId)
	visual.Parent = presentationRoot

	local record: RiderRecord = {
		visual = visual,
		sourceCharacter = character,
		seatPart = seatPart,
	}
	self._records[racer] = record
	return record
end

function RiderPresentationController:_targetSeatCFrame(body: BasePart, seatPart: BasePart): CFrame
	local position = body.Position
		+ Vector3.new(
			RIDER_MOUNT_X_OFFSET,
			body.Size.Y * 0.5 + seatPart.Size.Y * 0.5 + RIDER_SEAT_CLEARANCE,
			0
		)
	return CFrame.lookAt(position, position + Vector3.xAxis, Vector3.yAxis)
end

function RiderPresentationController:_placeRider(record: RiderRecord, body: BasePart)
	local localSeat = record.visual:GetPivot():ToObjectSpace(record.seatPart.CFrame)
	local targetSeat = self:_targetSeatCFrame(body, record.seatPart)
	record.visual:PivotTo(targetSeat * localSeat:Inverse())
end

function RiderPresentationController:_step()
	local runtime = Workspace:FindFirstChild("Runtime")
	local racers = runtime and runtime:FindFirstChild("Racers")
	if racers == nil then
		for racer in self._records do
			self:_destroyRecord(racer)
		end
		return
	end

	local active: { [Model]: boolean } = {}
	for _, candidate in racers:GetChildren() do
		if candidate:IsA("Model") then
			local player = resolveOwnerPlayer(candidate)
			local body = findBody(candidate)
			if player ~= nil and body ~= nil then
				active[candidate] = true
				local record = self:_ensureRecord(candidate, player)
				if record ~= nil then
					self:_placeRider(record, body)
				end
			end
		end
	end

	local stale = {}
	for racer in self._records do
		if active[racer] ~= true then
			table.insert(stale, racer)
		end
	end
	for _, racer in stale do
		self:_destroyRecord(racer)
	end
end

function RiderPresentationController:Start()
	if self._started then
		return
	end
	self._started = true
	self._connection = RunService.RenderStepped:Connect(function()
		self:_step()
	end)
	self:_step()
end

function RiderPresentationController:Destroy()
	if not self._started then
		return
	end
	self._started = false
	if self._connection ~= nil then
		self._connection:Disconnect()
		self._connection = nil
	end
	local racers = {}
	for racer in self._records do
		table.insert(racers, racer)
	end
	for _, racer in racers do
		self:_destroyRecord(racer)
	end
end

return RiderPresentationController
