--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local R16TrialRunner = require(script.Parent:WaitForChild("R16TrialRunner"))

local R17BodyFeelExperiment = {}

local DENSITY_CANDIDATES = { 1.00, 0.60, 0.40 }
local FRICTION_CANDIDATES = { 0.45, 0.25, 0.10 }
local COLLIDER_SIZE_CANDIDATES = { 3.0, 2.8, 2.6 }
local SHAPE_ID = "ROUND_01"

local BASE_DENSITY = 1.0
local BASE_FRICTION = 0.45
local BASE_COLLIDER_SIZE = 3.0

local function printTrial(axis: string, value: number, result: any)
	local bellyRatio = if result.duration > 0 then result.bodyContactTime / result.duration else 0
	print(string.format(
		"[DrawRacers][R17.6] axis=%s value=%.3f valid=%s duration=%.3f bodyContactTime=%.3f bellyRatio=%.3f legContactTime=%.3f airTime=%.3f forwardDistance=%.3f averageSpeed=%.3f stuckTime=%.3f antiStall=%s motors=%s",
		axis,
		value,
		tostring(result.valid),
		result.duration,
		result.bodyContactTime,
		bellyRatio,
		result.legContactTime,
		result.airTime,
		result.forwardDistance,
		result.averageSpeed,
		result.stuckTime,
		tostring(result.antiStallSeen),
		tostring(result.motorsEnabled)
	))
end

local function runDensitySweep(): boolean
	local valid = true
	for _, density in DENSITY_CANDIDATES do
		local result = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, {
			density = density,
			friction = BASE_FRICTION,
			colliderSize = BASE_COLLIDER_SIZE,
		})
		printTrial("density", density, result)
		valid = valid and result.valid and result.motorsEnabled
	end
	return valid
end

local function runFrictionSweep(): boolean
	local valid = true
	for _, friction in FRICTION_CANDIDATES do
		local result = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, {
			density = BASE_DENSITY,
			friction = friction,
			colliderSize = BASE_COLLIDER_SIZE,
		})
		printTrial("friction", friction, result)
		valid = valid and result.valid and result.motorsEnabled
	end
	return valid
end

local function runColliderSweep(): boolean
	local valid = true
	for _, colliderSize in COLLIDER_SIZE_CANDIDATES do
		local result = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, {
			density = BASE_DENSITY,
			friction = BASE_FRICTION,
			colliderSize = colliderSize,
		})
		printTrial("colliderSize", colliderSize, result)
		valid = valid and result.valid and result.motorsEnabled
	end
	return valid
end

function R17BodyFeelExperiment.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R17BodyFeelExperiment is Studio-only")
	print(string.format(
		"[DrawRacers][R17.6] body-feel evidence starting motor=(%.3f,%.0f,%.0f)",
		PhysicsConfig.Motor.AngularVelocity,
		PhysicsConfig.Motor.MotorMaxTorque,
		PhysicsConfig.Motor.MotorMaxAcceleration
	))

	local densityValid = runDensitySweep()
	local frictionValid = runFrictionSweep()
	local colliderValid = runColliderSweep()
	R16TrialRunner.DestroyActive()
	print("[DrawRacers][R17.6] HUMAN BODY FEEL CHOICE PENDING")
	return densityValid and frictionValid and colliderValid
end

return R17BodyFeelExperiment
