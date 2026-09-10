--!strict

local RunService = game:GetService("RunService")

local M0HumanHarness = require(script.Parent:WaitForChild("M0HumanHarness"))
local R16StageCHarness = require(script.Parent:WaitForChild("R16StageCHarness"))

local R16FinalHarness = {}

local started = false

function R16FinalHarness.start()
	assert(RunService:IsStudio(), "R16FinalHarness is Studio-only")
	if started then
		return
	end
	started = true
	print("[DrawRacers][R16FINAL] automated evidence starting")

	-- Intentionally synchronous: Bootstrap.server must not publish StudioGate READY
	-- until Stage B/C evidence has actually completed.
	local passed = R16StageCHarness.RunEvidence()
	if not passed then
		started = false
		error("R16FINAL automated evidence failed; human G0 must not start")
	end

	M0HumanHarness.start()
	print("[DrawRacers][R16FINAL] HUMAN G0 READY")
end

function R16FinalHarness.stop()
	M0HumanHarness.stop()
	R16StageCHarness.stop()
	started = false
end

return R16FinalHarness
