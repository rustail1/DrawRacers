--!strict

local RunService = game:GetService("RunService")
local DebugTelemetry = require(script.Parent:WaitForChild("Runtime"):WaitForChild("DebugTelemetry"))

DebugTelemetry.start()

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

	local B10StabilizationSpec = require(testsFolder:WaitForChild("B10StabilizationSpec"))
	B10StabilizationSpec.run()

	local B11LegShapeServiceSpec = require(testsFolder:WaitForChild("B11LegShapeServiceSpec"))
	B11LegShapeServiceSpec.run()

	local B12StrokeRemoteSpec = require(testsFolder:WaitForChild("B12StrokeRemoteSpec"))
	B12StrokeRemoteSpec.run()

	local B13AtomicRedrawSpec = require(testsFolder:WaitForChild("B13AtomicRedrawSpec"))
	B13AtomicRedrawSpec.run()

	local B14RedrawStressSpec = require(testsFolder:WaitForChild("B14RedrawStressSpec"))
	B14RedrawStressSpec.run()

	local B15ObstacleLabSpec = require(testsFolder:WaitForChild("B15ObstacleLabSpec"))
	B15ObstacleLabSpec.run()

	local B16DebugTuningSpec = require(testsFolder:WaitForChild("B16DebugTuningSpec"))
	B16DebugTuningSpec.run()

	local B08OneHingeMotorHarness = require(testsFolder:WaitForChild("B08OneHingeMotorHarness"))
	B08OneHingeMotorHarness.start()

	local B09TwoLegPhaseHarness = require(testsFolder:WaitForChild("B09TwoLegPhaseHarness"))
	B09TwoLegPhaseHarness.start()

	local B10StabilizationHarness = require(testsFolder:WaitForChild("B10StabilizationHarness"))
	B10StabilizationHarness.start()
end

print("[DrawRacers] server bootstrap ready")
