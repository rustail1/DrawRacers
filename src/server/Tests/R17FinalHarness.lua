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
			"[DrawRacers][R17FINAL] %s NON-GATING evidence FAIL — recorded for R17 tuning/review",
			label
		))
		return false
	end
	print(string.format("[DrawRacers][R17FINAL] %s NON-GATING evidence PASS", label))
	return true
end

function R17FinalHarness.start()
	assert(RunService:IsStudio(), "R17FinalHarness is Studio-only")
	if started then
		return
	end
	started = true

	print("[DrawRacers][R17FINAL] automated evidence starting")

	-- B03-B16 already form the hard Studio regression boundary before this
	-- harness starts. R16 Stage C is retained as a historical/reference-fit
	-- baseline, but R17 deliberately changed the locomotion architecture and is
	-- still collecting tuning evidence. A poor old R16 score therefore must not
	-- prevent the current R17 experiments from running.
	observeEvidence("R16 baseline", function()
		return R16StageCHarness.RunEvidence()
	end)

	-- R17.3 is comparison evidence only. It intentionally does not select or
	-- migrate the production mechanical origin.
	observeEvidence("R17.3 origin", function()
		return R17OriginExperiment.RunEvidence()
	end)

	-- The live one-axle/co-phase invariant is current structural evidence. If it
	-- fails, human feel review is unsafe because the implementation itself is not
	-- honoring the approved R17 mechanical contract.
	requireEvidence("R17.5 phase", function()
		return R17PhaseEvidence.RunEvidence()
	end)

	-- R17.6 sweeps temporary racer instances only. Candidate outcomes are the
	-- evidence being collected, not a precondition for collecting later evidence.
	observeEvidence("R17.6 body feel", function()
		return R17BodyFeelExperiment.RunEvidence()
	end)

	-- R17.7 is likewise a comparison matrix. Individual shapes are expected to
	-- succeed/fail differently, so its current gameplay outcome remains
	-- NON-GATING until the pending reference-feel/tuning choice is made.
	observeEvidence("R17.7 course", function()
		return R17ReferenceCourseHarness.RunEvidence()
	end)

	-- Only the current structural invariant above is a hard R17 gate. The human
	-- can now review the complete baseline + comparison output instead of being
	-- blocked by superseded R16 tuning thresholds.
	M0HumanHarness.start()
	print("[DrawRacers][R17FINAL] HUMAN REVIEW READY")
end

function R17FinalHarness.stop()
	M0HumanHarness.stop()
	R16StageCHarness.stop()
	started = false
end

return R17FinalHarness
