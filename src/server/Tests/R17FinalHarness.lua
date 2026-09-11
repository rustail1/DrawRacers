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

function R17FinalHarness.start()
	assert(RunService:IsStudio(), "R17FinalHarness is Studio-only")
	if started then
		return
	end
	started = true

	print("[DrawRacers][R17FINAL] automated evidence starting")

	-- Keep the old full core evidence as the first boundary so R17 does not hide
	-- an R16 regression behind later experiments.
	requireEvidence("R16", function()
		return R16StageCHarness.RunEvidence()
	end)

	-- R17.3 is comparison evidence only. It intentionally does not select or
	-- migrate the production mechanical origin.
	requireEvidence("R17.3 origin", function()
		return R17OriginExperiment.RunEvidence()
	end)

	requireEvidence("R17.5 phase", function()
		return R17PhaseEvidence.RunEvidence()
	end)

	-- R17.6 sweeps only temporary racer instances. Production body tuning remains
	-- unchanged until the human reviews the emitted measurements/feel.
	requireEvidence("R17.6 body feel", function()
		return R17BodyFeelExperiment.RunEvidence()
	end)

	requireEvidence("R17.7 course", function()
		return R17ReferenceCourseHarness.RunEvidence()
	end)

	-- Only after all automated Studio evidence is structurally valid do we expose
	-- the existing human harness for camera/rider/leg/reference-feel review.
	M0HumanHarness.start()
	print("[DrawRacers][R17FINAL] HUMAN REVIEW READY")
end

function R17FinalHarness.stop()
	M0HumanHarness.stop()
	R16StageCHarness.stop()
	started = false
end

return R17FinalHarness
