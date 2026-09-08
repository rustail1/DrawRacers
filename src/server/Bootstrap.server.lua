--!strict

local RunService = game:GetService("RunService")

if RunService:IsStudio() then
	local M0TestScene = require(script.Parent.M0TestScene)
	M0TestScene.build()

	local testsFolder = script.Parent:WaitForChild("Tests")
	local B03StrokeMathSpec = require(testsFolder:WaitForChild("B03StrokeMathSpec"))
	B03StrokeMathSpec.run()

	local B04StrokeMathSpec = require(testsFolder:WaitForChild("B04StrokeMathSpec"))
	B04StrokeMathSpec.run()
end

print("[DrawRacers] server bootstrap ready")
