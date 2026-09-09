--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DebugTuningPanel = {}
DebugTuningPanel.__index = DebugTuningPanel

local ROWS = {
	{ key = "shapeVersion", attribute = "DebugShapeVersion" },
	{ key = "rawPoints", attribute = "DebugRawPoints" },
	{ key = "simplifiedPoints", attribute = "DebugSimplifiedPoints" },
	{ key = "physicsPoints", attribute = "DebugPhysicsPoints" },
	{ key = "colliderSegments", attribute = "DebugColliderSegments" },
	{ key = "bodySpeed", attribute = "DebugBodySpeed" },
	{ key = "motorEnabled", attribute = "DebugMotorEnabled" },
	{ key = "motorAngularVelocity", attribute = "DebugMotorAngularVelocity" },
	{ key = "stuckState", attribute = "DebugStuckState" },
	{ key = "antiStallActive", attribute = "DebugAntiStallActive" },
	{ key = "laneDeviation", attribute = "DebugLaneDeviation" },
	{ key = "checkpoint", attribute = "DebugCheckpoint" },
	{ key = "progress", attribute = "DebugProgress" },
}

local function environmentAllowed(): boolean
	if RunService:IsStudio() then
		return true
	end
	local environment = game:GetAttribute("DrawRacersEnvironment")
	return environment == "DEV" or environment == "STAGING"
end

local function formatValue(value: any): string
	if type(value) == "number" then
		return string.format("%.3f", value)
	end
	if value == nil then
		return "-"
	end
	return tostring(value)
end

local function findRacer(): Model?
	local runtime = Workspace:FindFirstChild("Runtime")
	local racers = runtime and runtime:FindFirstChild("Racers")
	if not racers then
		return nil
	end

	local fallbackHuman: Model? = nil
	local fallbackAny: Model? = nil
	for _, child in racers:GetChildren() do
		if child:IsA("Model") and child:FindFirstChild("BodyCollider") then
			if child:GetAttribute("DebugTarget") == true then
				return child
			end
			if fallbackHuman == nil and child:GetAttribute("IsBot") == false then
				fallbackHuman = child
			end
			if fallbackAny == nil then
				fallbackAny = child
			end
		end
	end
	return fallbackHuman or fallbackAny
end

function DebugTuningPanel.new(playerGui: PlayerGui)
	local self = setmetatable({
		playerGui = playerGui,
		gui = nil,
		valueLabels = {},
		connection = nil,
		elapsed = 0,
	}, DebugTuningPanel)
	return self
end

function DebugTuningPanel:Start()
	if not environmentAllowed() or self.connection ~= nil then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "DrawRacersDebugTuning"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 1000
	gui.Parent = self.playerGui
	self.gui = gui

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -12, 0, 12)
	frame.Size = UDim2.fromOffset(330, 28 + #ROWS * 22)
	frame.BackgroundTransparency = 0.2
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(8, 4)
	title.Size = UDim2.new(1, -16, 0, 20)
	title.Font = Enum.Font.Code
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Draw Racers — DEV/STAGING physics"
	title.Parent = frame

	for index, row in ROWS do
		local y = 24 + (index - 1) * 22
		local label = Instance.new("TextLabel")
		label.Name = row.key
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromOffset(8, y)
		label.Size = UDim2.new(1, -16, 0, 20)
		label.Font = Enum.Font.Code
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = row.key .. ": -"
		label.Parent = frame
		self.valueLabels[row.key] = label
	end

	self.connection = RunService.RenderStepped:Connect(function(dt)
		self.elapsed += dt
		if self.elapsed < 0.20 then
			return
		end
		self.elapsed = 0

		local racer = findRacer()
		for _, row in ROWS do
			local label = self.valueLabels[row.key]
			if label then
				local value = if racer then racer:GetAttribute(row.attribute) else nil
				label.Text = row.key .. ": " .. formatValue(value)
			end
		end
	end)
end

function DebugTuningPanel:Destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
	table.clear(self.valueLabels)
end

return DebugTuningPanel
