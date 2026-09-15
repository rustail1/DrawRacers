--!strict

local RunService = game:GetService("RunService")

local R16StageCHarness = require(script.Parent:WaitForChild("R16StageCHarness"))
local R17OriginExperiment = require(script.Parent:WaitForChild("R17OriginExperiment"))
local R17PhaseEvidence = require(script.Parent:WaitForChild("R17PhaseEvidence"))
local R17BodyFeelExperiment = require(script.Parent:WaitForChild("R17BodyFeelExperiment"))
local R17ReferenceCourseHarness = require(script.Parent:WaitForChild("R17ReferenceCourseHarness"))
local M0HumanHarness = require(script.Parent:WaitForChild("M0HumanHarness"))

local R17FinalHarness = {}
local started = false

local function requireEvidence(label: string, runEvidence: () -> boolean)
	local ok, result = xpcall(runEvidence, debug.traceback)
	if not ok then
		error(string.format(
			"[DrawRacers][R17FINAL] %s evidence errored: %s",
			label,
			tostring(result)
		))
	end
	if result ~= true then
		error(string.format(
			"[DrawRacers][R17FINAL] %s evidence FAILED",
			label
		))
	end
end

local function observeEvidence(
	label: string,
	runEvidence: () -> boolean
): boolean
	local ok, result = xpcall(runEvidence, debug.traceback)
	if not ok then
		warn(string.format(
			"[DrawRacers][R17FINAL] %s NON-GATING evidence ERROR: %s",
			label,
			tostring(result)
		))
		return false
	end

	if result ~= true then
		warn(string.format(
			"[DrawRacers][R17FINAL] %s NON-GATING evidence FAIL — recorded for tuning/review",
			label
		))
		return false
	end

	print(string.format(
		"[DrawRacers][R17FINAL] %s NON-GATING evidence PASS",
		label
	))
	return true
end

function R17FinalHarness.start()
	assert(RunService:IsStudio(), "R17FinalHarness is Studio-only")
	if started then
		return
	end
	started = true

	print("[DrawRacers][R17FINAL] Leg Core v2 automated evidence starting")

	observeEvidence("R16 baseline", function()
		return R16StageCHarness.RunEvidence()
	end)

	observeEvidence("R17.3 origin", function()
		return R17OriginExperiment.RunEvidence()
	end)

	-- Hard structural gate: one persistent DriveJoint/SharedLegDrive must survive
	-- redraw and the fixed 180-degree side relationship must have no drift.
	requireEvidence("R17.5 shared-drive", function()
		return R17PhaseEvidence.RunEvidence()
	end)

	observeEvidence("R17.6 body feel", function()
		return R17BodyFeelExperiment.RunEvidence()
	end)

	observeEvidence("R17.7 course", function()
		return R17ReferenceCourseHarness.RunEvidence()
	end)

	M0HumanHarness.start()
	print("[DrawRacers][R17FINAL] HUMAN REVIEW READY")
end

function R17FinalHarness.stop()
	M0HumanHarness.stop()
	R16StageCHarness.stop()
	started = false
end

return R17FinalHarness
