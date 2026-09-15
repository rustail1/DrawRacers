--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RIDER_SCALE = 0.65
local RIDER_MOUNT_X_OFFSET = -0.15
local RIDER_SEAT_CLEARANCE = 0.05
local RIDER_NAME_PREFIX = "RiderPresentation_"
local RIDER_ANCHOR_NAME = "RiderAnchor"
local COWBOY_HAT_COLOR = Color3.fromRGB(112, 72, 42)
local COWBOY_HAT_BAND_COLOR = Color3.fromRGB(48, 33, 25)

local RiderPresentationController = {}
RiderPresentationController.__index = RiderPresentationController

type RiderRecord = {
	visual: Model,
	sourceCharacter: Model,
	seatPart: BasePart,
	seatToPivot: CFrame,
	anchor: Attachment,
	ownsAnchor: boolean,
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
			descendant.Anchored = false
			descendant.LocalTransparencyModifier = 0
			-- Keep the cloned avatar/accessory Transparency authored by the player's
			-- appearance. Only the invisible presentation root is forced hidden.
			if descendant.Name == "HumanoidRootPart" then
				descendant.Transparency = 1
			end
		end
	end
end

local function stabilizeVisualAssemblies(visual: Model, preferredRoot: BasePart)
	local visited = {} :: { [BasePart]: boolean }

	local function anchorComponent(root: BasePart)
		root.Anchored = true
		visited[root] = true
		for _, connected in root:GetConnectedParts(true) do
			if connected ~= root and connected:IsDescendantOf(visual) then
				connected.Anchored = false
				visited[connected] = true
			end
		end
	end

	anchorComponent(preferredRoot)
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") and visited[descendant] ~= true then
			anchorComponent(descendant)
		end
	end
end

local function configureAnchorFrame(anchor: Attachment, body: BasePart)
	local position = Vector3.new(
		RIDER_MOUNT_X_OFFSET,
		body.Size.Y * 0.5 + RIDER_SEAT_CLEARANCE,
		0
	)
	anchor.CFrame = CFrame.lookAt(position, position + Vector3.xAxis, Vector3.yAxis)
end

local function ensureRiderAnchor(body: BasePart): (Attachment?, boolean)
	local existing = body:FindFirstChild(RIDER_ANCHOR_NAME)
	if existing ~= nil then
		if not existing:IsA("Attachment") then
			return nil, false
		end
		configureAnchorFrame(existing, body)
		return existing, false
	end

	local anchor = Instance.new("Attachment")
	anchor.Name = RIDER_ANCHOR_NAME
	configureAnchorFrame(anchor, body)
	anchor.Parent = body
	return anchor, true
end

local function configureCowboyPart(part: Part, color: Color3)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = true
end

local function weldCowboyPart(head: BasePart, part: Part)
	local weld = Instance.new("WeldConstraint")
	weld.Name = part.Name .. "Weld"
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
end

local function applyCowboyPresentation(visual: Model)
	local head = visual:FindFirstChild("Head", true)
	if head == nil or not head:IsA("BasePart") then
		return
	end

	local oldHat = visual:FindFirstChild("CowboyHatPresentation")
	if oldHat ~= nil then
		oldHat:Destroy()
	end

	local hat = Instance.new("Folder")
	hat.Name = "CowboyHatPresentation"
	hat.Parent = visual

	local brim = Instance.new("Part")
	brim.Name = "CowboyHatBrim"
	brim.Size = Vector3.new(head.Size.X * 1.7, math.max(0.08, head.Size.Y * 0.10), head.Size.Z * 1.55)
	configureCowboyPart(brim, COWBOY_HAT_COLOR)
	brim.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.54, 0)
	brim.Parent = hat
	weldCowboyPart(head, brim)

	local crown = Instance.new("Part")
	crown.Name = "CowboyHatCrown"
	crown.Size = Vector3.new(head.Size.X * 0.92, head.Size.Y * 0.58, head.Size.Z * 0.92)
	configureCowboyPart(crown, COWBOY_HAT_COLOR)
	crown.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.86, 0)
	crown.Parent = hat
	weldCowboyPart(head, crown)

	local band = Instance.new("Part")
	band.Name = "CowboyHatBand"
	band.Size = Vector3.new(head.Size.X * 0.98, math.max(0.07, head.Size.Y * 0.10), head.Size.Z * 0.98)
	configureCowboyPart(band, COWBOY_HAT_BAND_COLOR)
	band.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.65, 0)
	band.Parent = hat
	weldCowboyPart(head, band)
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
	applyCowboyPresentation(visual)
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
	if record.ownsAnchor and record.anchor.Parent ~= nil then
		record.anchor:Destroy()
	end
	self._records[racer] = nil
end

function RiderPresentationController:_ensureRecord(racer: Model, player: Player, body: BasePart): RiderRecord?
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
	if existing ~= nil
		and existing.sourceCharacter == character
		and existing.visual.Parent ~= nil
		and existing.anchor.Parent == body
	then
		configureAnchorFrame(existing.anchor, body)
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
	local stabilityRoot = visual.PrimaryPart or seatPart
	visual.PrimaryPart = stabilityRoot
	stabilizeVisualAssemblies(visual, stabilityRoot)

	local anchor, ownsAnchor = ensureRiderAnchor(body)
	if anchor == nil then
		visual:Destroy()
		return nil
	end

	local record: RiderRecord = {
		visual = visual,
		sourceCharacter = character,
		seatPart = seatPart,
		seatToPivot = seatPart.CFrame:ToObjectSpace(visual:GetPivot()),
		anchor = anchor,
		ownsAnchor = ownsAnchor,
	}
	self._records[racer] = record
	if RunService:IsStudio() then
		print(string.format("[DrawRacers][Rider] presentation ready user=%d", player.UserId))
	end
	return record
end

function RiderPresentationController:_targetSeatCFrame(anchor: Attachment, seatPart: BasePart): CFrame
	return anchor.WorldCFrame * CFrame.new(0, seatPart.Size.Y * 0.5, 0)
end

function RiderPresentationController:_placeRider(record: RiderRecord)
	local targetSeat = self:_targetSeatCFrame(record.anchor, record.seatPart)
	record.visual:PivotTo(targetSeat * record.seatToPivot)
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
				local record = self:_ensureRecord(candidate, player, body)
				if record ~= nil then
					self:_placeRider(record)
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
