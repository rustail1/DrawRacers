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
		error(string.format("[DrawRacers][R17FINAL] %s evidence errored: %s", label, tostring(result)))
	end
	if result ~= true then
		error(string.format("[DrawRacers][R17FINAL] %s evidence FAILED", label))
	end
end

local function observeEvidence(label: string, runEvidence: () -> boolean): boolean
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
	print(string.format("[DrawRacers][R17FINAL] %s NON-GATING evidence PASS", label))
	return true
end

function R17FinalHarness.start()
	assert(RunService:IsStudio(), "R17FinalHarness is Studio-only")
	if started then return end
	started = true

	print("[DrawRacers][R17FINAL] CR2 automated evidence starting")

	-- Historical R16 thresholds remain useful comparison evidence but no longer
	-- define the current CR2 locomotion architecture.
	observeEvidence("R16 baseline", function()
		return R16StageCHarness.RunEvidence()
	end)

	-- R17.3 is now explicitly a historical origin comparison. CR2 fixed pivot is
	-- already production authority and this evidence cannot change it.
	observeEvidence("R17.3 origin", function()
		return R17OriginExperiment.RunEvidence()
	end)

	-- CR2 twin-drive structural evidence is the hard repository-side Studio
	-- prerequisite: two persistent DriveJoint motors must keep the 180-degree
	-- pair target and survive redraw without owner replacement.
	requireEvidence("R17.5 phase", function()
		return R17PhaseEvidence.RunEvidence()
	end)

	-- R17.6 keeps temporary material/reference-feel comparisons. The obsolete
	-- absolute motor-speed sweep is intentionally retired because CR2 computes
	-- extent-aware drive speed continuously from the authoritative ShapeSpec.
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
