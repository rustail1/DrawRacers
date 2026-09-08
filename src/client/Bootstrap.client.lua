--!strict

local Players = game:GetService("Players")

local controllers = script.Parent:WaitForChild("Controllers")
local InputController = require(controllers:WaitForChild("InputController"))
local DrawingController = require(controllers:WaitForChild("DrawingController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local drawHud = playerGui:WaitForChild("DrawHUD") :: ScreenGui

local inputController = InputController.new()
local drawingController = DrawingController.new(inputController, drawHud)
drawingController:Start()

print("[DrawRacers] client bootstrap ready")
