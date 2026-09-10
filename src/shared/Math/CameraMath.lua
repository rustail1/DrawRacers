--!strict

local CameraMath = {}

function CameraMath.ExpAlpha(dt: number, dampingTime: number): number
	if dampingTime <= 0 then
		return 1
	end
	local safeDt = math.max(dt, 0)
	return 1 - math.exp(-safeDt / dampingTime)
end

function CameraMath.SmoothNumber(current: number, target: number, dt: number, dampingTime: number): number
	local alpha = CameraMath.ExpAlpha(dt, dampingTime)
	return current + (target - current) * alpha
end

function CameraMath.SmoothVector(current: Vector3, target: Vector3, dt: number, dampingTime: number): Vector3
	local alpha = CameraMath.ExpAlpha(dt, dampingTime)
	return current:Lerp(target, alpha)
end

function CameraMath.StepVerticalDeadZone(
	current: number,
	raw: number,
	deadZone: number,
	dt: number,
	dampingTime: number
): number
	local halfBand = math.max(deadZone, 0)
	local delta = raw - current
	if math.abs(delta) <= halfBand then
		return current
	end

	local target = raw - math.sign(delta) * halfBand
	return CameraMath.SmoothNumber(current, target, dt, dampingTime)
end

function CameraMath.ClampOrbit(
	yawDegrees: number,
	pitchDegrees: number,
	yawLimitDegrees: number,
	pitchLimitDegrees: number
): (number, number)
	local yawLimit = math.abs(yawLimitDegrees)
	local pitchLimit = math.abs(pitchLimitDegrees)
	return math.clamp(yawDegrees, -yawLimit, yawLimit), math.clamp(pitchDegrees, -pitchLimit, pitchLimit)
end

return CameraMath
