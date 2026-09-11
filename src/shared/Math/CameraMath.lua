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

local function projectedHorizontalAnchor(
	cameraX: number,
	lookAhead: number,
	cameraHeight: number,
	sideDistance: number,
	verticalFovDegrees: number,
	aspectRatio: number
): number
	local cameraPosition = Vector3.new(cameraX, cameraHeight, sideDistance)
	local lookTarget = Vector3.new(lookAhead, 0, 0)
	local frame = CFrame.lookAt(cameraPosition, lookTarget, Vector3.yAxis)
	local localRacer = frame:PointToObjectSpace(Vector3.zero)
	local forwardDepth = math.max(-localRacer.Z, 1e-4)
	local verticalHalfTangent = math.tan(math.rad(verticalFovDegrees) * 0.5)
	local horizontalHalfTangent = math.max(verticalHalfTangent * aspectRatio, 1e-4)
	local ndcX = (localRacer.X / forwardDepth) / horizontalHalfTangent
	return 0.5 * (ndcX + 1)
end

function CameraMath.ScreenAnchorCameraX(
	lookAhead: number,
	cameraHeight: number,
	sideDistance: number,
	verticalFovDegrees: number,
	aspectRatio: number,
	screenAnchor: number
): number
	assert(aspectRatio > 0, "camera aspectRatio must be positive")
	assert(verticalFovDegrees > 0 and verticalFovDegrees < 179, "camera vertical FOV must be valid")
	assert(screenAnchor > 0 and screenAnchor < 0.5, "forward look-ahead screen anchor must be left of center")

	-- With a positive look-ahead the racer must sit left of the view center.
	-- Moving the camera backward on X monotonically brings the racer toward
	-- center while retaining the canonical look target ahead of it. Solve the
	-- finite composition offset directly so viewport aspect is respected.
	local upperX = 0
	local lowerX = -math.max(math.abs(lookAhead) + math.abs(sideDistance) * 4, 64)
	local upperAnchor = projectedHorizontalAnchor(
		upperX,
		lookAhead,
		cameraHeight,
		sideDistance,
		verticalFovDegrees,
		aspectRatio
	)
	if screenAnchor <= upperAnchor then
		return upperX
	end

	for _ = 1, 32 do
		local midpoint = (lowerX + upperX) * 0.5
		local midpointAnchor = projectedHorizontalAnchor(
			midpoint,
			lookAhead,
			cameraHeight,
			sideDistance,
			verticalFovDegrees,
			aspectRatio
		)
		if midpointAnchor > screenAnchor then
			lowerX = midpoint
		else
			upperX = midpoint
		end
	end
	return (lowerX + upperX) * 0.5
end

return CameraMath
