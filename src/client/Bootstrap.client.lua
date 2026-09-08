--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local controllers = script.Parent:WaitForChild("Controllers")
local InputController = require(controllers:WaitForChild("InputController"))
local DrawingController = require(controllers:WaitForChild("DrawingController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local drawHud = playerGui:WaitForChild("DrawHUD") :: ScreenGui

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local submitStroke = remotes:WaitForChild("SubmitStroke")
local strokeResult = remotes:WaitForChild("StrokeResult")

local inputController = InputController.new()
local drawingController = DrawingController.new(inputController, drawHud, submitStroke, strokeResult)
drawingController:Start()

print("[DrawRacers] client bootstrap ready")
