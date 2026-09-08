--!strict

local RunService = game:GetService("RunService")

if RunService:IsStudio() then
	local M0TestScene = require(script.Parent.M0TestScene)
	M0TestScene.build()
end

print("[DrawRacers] server bootstrap ready")
