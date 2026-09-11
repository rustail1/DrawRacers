--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local R16TrialRunner = require(script.Parent:WaitForChild("R16TrialRunner"))

local R17ReferenceCourseHarness = {}

local SHAPES = {
	"ROUND_01",
	"LONG_BAR_01",
	"SMALL_ROUND_01",
	"HOOK_01",
	"ASYM_01",
	"SUBOPTIMAL_01",
}

local PIECES = {
	"FlatShort",
	"SmallSteps",
	"SingleWallLow",
	"GapSmall",
	"LowTunnelWide",
}

local function runPiece(pieceId: string, shapeId: string): any
	local acceptance = M0SceneConfig.ReferenceAcceptance
	if pieceId == "FlatShort" then
		return R16TrialRunner.RunFlat(shapeId)
	elseif pieceId == "SmallSteps" then
		return R16TrialRunner.RunPiece(pieceId, shapeId, acceptance.StepsMeasureSeconds, { contactPrefix = "Step" })
	elseif pieceId == "SingleWallLow" then
		return R16TrialRunner.RunPiece(pieceId, shapeId, acceptance.WallMeasureSeconds, {
			contactName = "Wall",
			contactTimeout = acceptance.WallContactTimeout,
		})
	elseif pieceId == "GapSmall" then
		return R16TrialRunner.RunPiece(pieceId, shapeId, acceptance.GapMeasureSeconds, nil)
	elseif pieceId == "LowTunnelWide" then
		return R16TrialRunner.RunPiece(pieceId, shapeId, acceptance.TunnelMeasureSeconds, nil)
	end
	error(string.format("unknown R17 reference piece %s", pieceId))
end

local function printResult(pieceId: string, shapeId: string, result: any)
	local progress = result.progress or 0
	local speed = result.speed or 0
	local completedPiece = result.completedPiece == true
	local landedAfterGap = result.landedAfterGap == true
	local antiStallSeen = result.antiStallSeen == true
	print(string.format(
		"[DrawRacers][R17.7] piece=%s shape=%s valid=%s progress=%.3f speed=%.3f completedPiece=%s landedAfterGap=%s antiStallSeen=%s motors=%s",
		pieceId,
		shapeId,
		tostring(result.valid),
		progress,
		speed,
		tostring(completedPiece),
		tostring(landedAfterGap),
		tostring(antiStallSeen),
		tostring(result.motorsEnabled)
	))
end

function R17ReferenceCourseHarness.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R17ReferenceCourseHarness is Studio-only")
	print("[DrawRacers][R17.7] canonical reference-course matrix starting liveRedrawOwner=R16StageCHarness")
	local structurallyValid = true

	for _, pieceId in PIECES do
		for _, shapeId in SHAPES do
			local result = runPiece(pieceId, shapeId)
			printResult(pieceId, shapeId, result)
			structurallyValid = structurallyValid and result.valid == true and result.motorsEnabled == true
		end
	end

	R16TrialRunner.DestroyActive()
	print(string.format(
		"[DrawRacers][R17.7] matrix complete structural=%s HUMAN REFERENCE FEEL REVIEW PENDING",
		tostring(structurallyValid)
	))
	return structurallyValid
end

return R17ReferenceCourseHarness
