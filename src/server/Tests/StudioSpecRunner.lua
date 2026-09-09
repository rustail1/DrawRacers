--!strict

local StudioSpecRunner = {}

local SPEC_NAMES = {
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

function StudioSpecRunner.run(testsFolder: Instance): (boolean, { string })
	local failures = {}

	for _, specName in SPEC_NAMES do
		local ok, failure = xpcall(function()
			local module = testsFolder:WaitForChild(specName)
			local spec = require(module)
			assert(type(spec) == "table" and type(spec.run) == "function", specName .. " missing run()")
			spec.run()
		end, debug.traceback)

		if ok then
			print(string.format("[DrawRacers][StudioGate] %s PASS", specName))
		else
			local message = string.format("%s: %s", specName, tostring(failure))
			table.insert(failures, message)
			warn("[DrawRacers][StudioGate] FAIL " .. message)
		end
	end

	print(string.format(
		"[DrawRacers][StudioGate] TOTAL %d PASS / %d FAIL",
		#SPEC_NAMES - #failures,
		#failures
	))
	return #failures == 0, failures
end

return StudioSpecRunner
