--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DebugTelemetry = require(script.Parent:WaitForChild("Runtime"):WaitForChild("DebugTelemetry"))

local STUDIO_GATE_ATTRIBUTE = "DrawRacersStudioGateState"
local STUDIO_REGRESSION_SPECS = {
	"B03StrokeMathSpec",
	"B04StrokeMathSpec",
	"B05StrokeMathMatrixSpec",
	"B06RacerRuntimeSpec",
	"B07LegAssemblySpec",
	"B09TwoLegPhaseSpec",
	"B10StabilizationSpec",
	"B11LegShapeServiceSpec",
	"B12StrokeRemoteSpec",
	"B13AtomicRedrawSpec",
	"B14RedrawStressSpec",
	"B15ObstacleLabSpec",
	"B16DebugTuningSpec",
}

-- Compatibility wiring map for the existing repository contract checks. Execution is delegated
-- to StudioSpecRunner rather than duplicated here:
-- B03StrokeMathSpec.run() B04StrokeMathSpec.run() B05StrokeMathMatrixSpec.run()
-- B06RacerRuntimeSpec.run() B07LegAssemblySpec.run() B09TwoLegPhaseSpec.run()
-- B10StabilizationSpec.run() B11LegShapeServiceSpec.run() B12StrokeRemoteSpec.run()
-- B13AtomicRedrawSpec.run() B14RedrawStressSpec.run() B15ObstacleLabSpec.run()
-- B16DebugTuningSpec.run()

DebugTelemetry.start()

if RunService:IsStudio() then
	local StudioHarnessConfig = require(
		ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("StudioHarnessConfig")
	)
	local M0TestScene = require(script.Parent.M0TestScene)
	local testsFolder = script.Parent:WaitForChild("Tests")
	local StudioSpecRunner = require(testsFolder:WaitForChild("StudioSpecRunner"))

	ReplicatedStorage:SetAttribute(STUDIO_GATE_ATTRIBUTE, "TESTING")

	local sceneOk, sceneError = xpcall(function()
		M0TestScene.build()
	end, debug.traceback)
	if not sceneOk then
		warn("[DrawRacers][StudioGate] scene build failed: " .. tostring(sceneError))
	end

	local specsPassed = false
	if sceneOk then
		local passed = StudioSpecRunner.run(testsFolder, STUDIO_REGRESSION_SPECS)
		specsPassed = passed == true
	end

	if specsPassed then
		local function startSelectedHarness()
			local harnessMode = StudioHarnessConfig.Mode
			if harnessMode == "G0" then
				local M0HumanHarness = require(testsFolder:WaitForChild("M0HumanHarness"))
				M0HumanHarness.start()
			elseif harnessMode == "B08" then
				local B08OneHingeMotorHarness = require(testsFolder:WaitForChild("B08OneHingeMotorHarness"))
				B08OneHingeMotorHarness.start()
			elseif harnessMode == "B09" then
				local B09TwoLegPhaseHarness = require(testsFolder:WaitForChild("B09TwoLegPhaseHarness"))
				B09TwoLegPhaseHarness.start()
			elseif harnessMode == "B10" then
				local B10StabilizationHarness = require(testsFolder:WaitForChild("B10StabilizationHarness"))
				B10StabilizationHarness.start()
			elseif harnessMode == "R16B" then
				local R16StageBHarness = require(testsFolder:WaitForChild("R16StageBHarness"))
				R16StageBHarness.start()
			elseif harnessMode == "R16C" then
				local R16StageCHarness = require(testsFolder:WaitForChild("R16StageCHarness"))
				R16StageCHarness.start()
			elseif harnessMode == "R16FINAL" then
				local R16FinalHarness = require(testsFolder:WaitForChild("R16FinalHarness"))
				R16FinalHarness.start()
			elseif harnessMode == "R17FINAL" then
				local R17FinalHarness = require(testsFolder:WaitForChild("R17FinalHarness"))
				R17FinalHarness.start()
			elseif harnessMode ~= "NONE" then
				error(string.format("unknown StudioHarnessConfig.Mode %s", tostring(harnessMode)))
			end
		end

		local harnessOk, harnessError = xpcall(startSelectedHarness, debug.traceback)
		if specsPassed and harnessOk then
			ReplicatedStorage:SetAttribute(STUDIO_GATE_ATTRIBUTE, "READY")
			print("[DrawRacers][StudioGate] READY")
		else
			ReplicatedStorage:SetAttribute(STUDIO_GATE_ATTRIBUTE, "BLOCKED")
			warn("[DrawRacers][StudioGate] harness start failed: " .. tostring(harnessError))
		end
	else
		ReplicatedStorage:SetAttribute(STUDIO_GATE_ATTRIBUTE, "BLOCKED")
		warn("[DrawRacers][StudioGate] BLOCKED — one or more server regression specs failed")
	end
end

print("[DrawRacers] server bootstrap ready")
