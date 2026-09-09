--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local controllers = script.Parent:WaitForChild("Controllers")
local InputController = require(controllers:WaitForChild("InputController"))
local DrawingController = require(controllers:WaitForChild("DrawingController"))
local DebugTuningPanel = require(controllers:WaitForChild("DebugTuningPanel"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local drawHud = playerGui:WaitForChild("DrawHUD") :: ScreenGui

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local submitStroke = remotes:WaitForChild("SubmitStroke")
local strokeResult = remotes:WaitForChild("StrokeResult")

local inputController = InputController.new()
local drawingController = DrawingController.new(inputController, drawHud, submitStroke, strokeResult)
drawingController:Start()

local debugTuningPanel = DebugTuningPanel.new(playerGui)
debugTuningPanel:Start()

if RunService:IsStudio() then
	local StudioHarnessConfig = require(
		ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("StudioHarnessConfig")
	)
	if StudioHarnessConfig.Mode == "G0" then
		local devFolder = script.Parent:WaitForChild("Dev")
		local M0G0PresentationHarness = require(devFolder:WaitForChild("M0G0PresentationHarness"))
		M0G0PresentationHarness.start()
	end
end

print("[DrawRacers] client bootstrap ready")
