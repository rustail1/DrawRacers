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

	local B05StrokeMathMatrixSpec = require(testsFolder:WaitForChild("B05StrokeMathMatrixSpec"))
	B05StrokeMathMatrixSpec.run()

	local B06RacerRuntimeSpec = require(testsFolder:WaitForChild("B06RacerRuntimeSpec"))
	B06RacerRuntimeSpec.run()

	local B07LegAssemblySpec = require(testsFolder:WaitForChild("B07LegAssemblySpec"))
	B07LegAssemblySpec.run()

	local B09TwoLegPhaseSpec = require(testsFolder:WaitForChild("B09TwoLegPhaseSpec"))
	B09TwoLegPhaseSpec.run()

	local B08OneHingeMotorHarness = require(testsFolder:WaitForChild("B08OneHingeMotorHarness"))
	B08OneHingeMotorHarness.start()

	local B09TwoLegPhaseHarness = require(testsFolder:WaitForChild("B09TwoLegPhaseHarness"))
	B09TwoLegPhaseHarness.start()
end

print("[DrawRacers] server bootstrap ready")
