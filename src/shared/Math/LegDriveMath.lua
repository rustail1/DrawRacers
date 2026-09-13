--!strict

local LegDriveMath = {}

local function finite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

function LegDriveMath.NormalizeDegrees(value: number): number
	assert(type(value) == "number" and finite(value), "NormalizeDegrees requires finite number")
	local normalized = value % 360
	if normalized < 0 then
		normalized += 360
	end
	return normalized
end

function LegDriveMath.SignedShortestDeltaDegrees(fromDegrees: number, toDegrees: number): number
	local from = LegDriveMath.NormalizeDegrees(fromDegrees)
	local to = LegDriveMath.NormalizeDegrees(toDegrees)
	local delta = (to - from + 180) % 360 - 180
	return delta
end

function LegDriveMath.PairPhaseErrorDegrees(
	leftDegrees: number,
	rightDegrees: number,
	targetOffsetDegrees: number
): number
	local actualOffset = LegDriveMath.NormalizeDegrees(rightDegrees - leftDegrees)
	return LegDriveMath.SignedShortestDeltaDegrees(targetOffsetDegrees, actualOffset)
end

function LegDriveMath.ComputeAngularVelocity(extent: number, motorConfig: any): number
	assert(type(extent) == "number" and finite(extent) and extent >= 0, "extent must be finite and non-negative")
	local radius = math.max(extent, motorConfig.MinimumDriveRadius)
	local targetTipSpeed = motorConfig.TargetTipSpeed
	local omegaMagnitude = targetTipSpeed / radius
	omegaMagnitude = math.clamp(omegaMagnitude, motorConfig.MinAngularVelocity, motorConfig.MaxAngularVelocity)
	return motorConfig.RotationSign * omegaMagnitude
end

function LegDriveMath.ComputePhaseCorrection(errorDegrees: number, motorConfig: any): number
	assert(type(errorDegrees) == "number" and finite(errorDegrees), "phase error must be finite")
	if math.abs(errorDegrees) <= motorConfig.PhaseDeadbandDegrees then
		return 0
	end
	return math.clamp(
		errorDegrees * motorConfig.PhaseCorrectionGain,
		-motorConfig.MaxPhaseCorrection,
		motorConfig.MaxPhaseCorrection
	)
end

return LegDriveMath
