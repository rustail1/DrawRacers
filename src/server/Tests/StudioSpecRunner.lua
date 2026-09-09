--!strict

local StudioSpecRunner = {}

function StudioSpecRunner.run(testsFolder: Instance, specNames: { string }): (boolean, { string })
	local failures = {}

	for _, specName in specNames do
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
		#specNames - #failures,
		#failures
	))
	return #failures == 0, failures
end

return StudioSpecRunner
