--!strict

local CoreV3DriveAcceptanceGate = {}

local MAX_REST_BASELINE_VX = 0.15

export type State = {
	continuousRotationSeconds: number,
	sawPositiveVX: boolean,
	baselineVelocityX: number,
	eligibleFromRest: boolean,
}

function CoreV3DriveAcceptanceGate.new(): State
	return {
		continuousRotationSeconds = 0,
		sawPositiveVX = false,
		baselineVelocityX = 0,
		eligibleFromRest = true,
	}
end

function CoreV3DriveAcceptanceGate.reset(state: State)
	state.continuousRotationSeconds = 0
	state.sawPositiveVX = false
	state.baselineVelocityX = 0
	state.eligibleFromRest = true
end

function CoreV3DriveAcceptanceGate.begin(state: State, baselineVelocityX: number)
	assert(type(baselineVelocityX) == "number", "baselineVelocityX must be number")
	CoreV3DriveAcceptanceGate.reset(state)
	state.baselineVelocityX = baselineVelocityX
	state.eligibleFromRest = math.abs(baselineVelocityX) <= MAX_REST_BASELINE_VX
end

function CoreV3DriveAcceptanceGate.step(
	state: State,
	dt: number,
	hasLegContact: boolean,
	motorCommanded: boolean,
	hasRelativeRotation: boolean,
	bodyVelocityX: number
)
	assert(dt >= 0, "CoreV3DriveAcceptanceGate dt must be non-negative")

	if hasLegContact and motorCommanded and hasRelativeRotation then
		state.continuousRotationSeconds += dt
	else
		-- Acceptance requires one uninterrupted contact+rotation window.
		state.continuousRotationSeconds = 0
	end

	if hasLegContact and motorCommanded and bodyVelocityX > 0.02 then
		state.sawPositiveVX = true
	end
end

return CoreV3DriveAcceptanceGate
