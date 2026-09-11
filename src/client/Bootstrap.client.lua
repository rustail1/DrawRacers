--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local controllers = script.Parent:WaitForChild("Controllers")
local InputController = require(controllers:WaitForChild("InputController"))
local DrawingController = require(controllers:WaitForChild("DrawingController"))
local DebugTuningPanel = require(controllers:WaitForChild("DebugTuningPanel"))
local RaceCameraController = require(controllers:WaitForChild("RaceCameraController"))
local RiderPresentationController = require(controllers:WaitForChild("RiderPresentationController"))

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Net"):WaitForChild("RemoteNames"))

local STUDIO_GATE_ATTRIBUTE = "DrawRacersStudioGateState"
local DRAW_HUD_WAIT_TIMEOUT = 10

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local drawHudInstance = playerGui:WaitForChild("DrawHUD", DRAW_HUD_WAIT_TIMEOUT)
assert(drawHudInstance and drawHudInstance:IsA("ScreenGui"), "DrawHUD missing from PlayerGui after bounded bootstrap wait")
local drawHud = drawHudInstance :: ScreenGui

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local submitStroke = remotes:WaitForChild(RemoteNames.SubmitStroke)
local strokeResult = remotes:WaitForChild(RemoteNames.StrokeResult)

local inputController = InputController.new()
local drawingController = DrawingController.new(inputController, drawHud, submitStroke, strokeResult)
local raceCameraController = RaceCameraController.new(playerGui)
local riderPresentationController = RiderPresentationController.new()
local productionPresentationStarted = false

local function startProductionPresentation()
	if productionPresentationStarted then
		return
	end
	productionPresentationStarted = true
	raceCameraController:Start()
	riderPresentationController:Start()
end

local debugTuningPanel = DebugTuningPanel.new(playerGui)
debugTuningPanel:Start()

local function createStudioGateBanner(): TextLabel
	local existing = playerGui:FindFirstChild("DrawRacersStudioGate")
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "DrawRacersStudioGate"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2000
	gui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.03)
	label.Size = UDim2.fromOffset(520, 42)
	label.BackgroundTransparency = 0.15
	label.TextScaled = true
	label.Visible = false
	label.Parent = gui
	return label
end

if RunService:IsStudio() then
	local StudioHarnessConfig = require(
		shared:WaitForChild("Config"):WaitForChild("StudioHarnessConfig")
	)
	local devFolder = script.Parent:WaitForChild("Dev")
	local M0G0PresentationHarness = require(devFolder:WaitForChild("M0G0PresentationHarness"))
	local gateBanner = createStudioGateBanner()
	local drawingStarted = false
	local presentationStarted = false

	local function applyStudioGateState()
		local state = ReplicatedStorage:GetAttribute("DrawRacersStudioGateState")
		if state == "READY" then
			gateBanner.Visible = false
			startProductionPresentation()
			if not drawingStarted then
				drawingStarted = true
				drawingController:Start()
			end
			local presentationMode = StudioHarnessConfig.Mode == "G0"
				or StudioHarnessConfig.Mode == "R16FINAL"
				or StudioHarnessConfig.Mode == "R17FINAL"
			if presentationMode and not presentationStarted then
				presentationStarted = true
				M0G0PresentationHarness.start()
			end
		elseif state == "BLOCKED" then
			gateBanner.Text = "G0 BLOCKED — SERVER TEST FAILED"
			gateBanner.Visible = true
		else
			gateBanner.Text = "G0 TESTS RUNNING"
			gateBanner.Visible = true
		end
	end

	ReplicatedStorage:GetAttributeChangedSignal("DrawRacersStudioGateState"):Connect(applyStudioGateState)
	applyStudioGateState()
else
	startProductionPresentation()
	drawingController:Start()
end

print("[DrawRacers] client bootstrap ready")
