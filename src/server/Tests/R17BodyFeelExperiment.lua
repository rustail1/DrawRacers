--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local M0SceneConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("M0SceneConfig")
)
local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local R16TrialRunner = require(script.Parent:WaitForChild("R16TrialRunner"))

local R17BodyFeelExperiment = {}

local BODY_DENSITY_CANDIDATES = { 1.00, 0.60, 0.45, 0.35 }
local LEG_DENSITY_CANDIDATES = { 1.00, 0.60, 0.40 }
local MOTOR_SPEED_CANDIDATES = { -8.0, -10.0, -11.5, -12.5 }
local FRICTION_CANDIDATES = { 0.45, 0.25, 0.10 }
local SHAPE_ID = "ROUND_01"
local STEPS_ID = "SmallSteps"
local WALL_ID = "SingleWallLow"

local BASE_BODY_DENSITY = 1.0
local BASE_BODY_FRICTION = 0.45
local BASE_LEG_DENSITY = PhysicsConfig.PhysicalMaterials.LegSegment.Density
local BASE_MOTOR_SPEED = PhysicsConfig.Motor.AngularVelocity

local function tuningWith(overrides: any): any
	return {
		bodyDensity = overrides.bodyDensity or BASE_BODY_DENSITY,
		bodyFriction = overrides.bodyFriction or BASE_BODY_FRICTION,
		legDensity = overrides.legDensity or BASE_LEG_DENSITY,
		motorAngularVelocity = overrides.motorAngularVelocity or BASE_MOTOR_SPEED,
	}
end

local function runSteps(tuning: any): any
	return R16TrialRunner.RunPiece(
		STEPS_ID,
		SHAPE_ID,
		M0SceneConfig.ReferenceAcceptance.StepsMeasureSeconds,
		{
			contactPrefix = "Step",
			tuning = tuning,
		}
	)
end

local function runWall(tuning: any): any
	return R16TrialRunner.RunPiece(
		WALL_ID,
		SHAPE_ID,
		M0SceneConfig.ReferenceAcceptance.WallMeasureSeconds,
		{
			contactName = "Wall",
			contactTimeout = M0SceneConfig.ReferenceAcceptance.WallContactTimeout,
			tuning = tuning,
		}
	)
end

local function printFlatTrial(family: string, value: number, result: any)
	local bellyRatio = if result.duration > 0 then result.bodyContactTime / result.duration else 0
	print(string.format(
		"[DrawRacers][R17.6] family=%s value=%.3f flat valid=%s speed=%.3f distance=%.3f bellyRatio=%.3f bodyContact=%.3f legContact=%.3f air=%.3f stuck=%.3f maxBounceHeight=%.3f solverInstability=%s antiStall=%s motors=%s",
		family,
		value,
		tostring(result.valid),
		result.averageSpeed,
		result.forwardDistance,
		bellyRatio,
		result.bodyContactTime,
		result.legContactTime,
		result.airTime,
		result.stuckTime,
		result.maxBounceHeight,
		tostring(result.solverInstability),
		tostring(result.antiStallSeen),
		tostring(result.motorsEnabled)
	))
end

local function printPieceTrial(family: string, value: number, pieceId: string, result: any)
	print(string.format(
		"[DrawRacers][R17.6] family=%s value=%.3f piece=%s valid=%s progress=%.3f speed=%.3f completed=%s bounce=%.3f solverInstability=%s antiStall=%s motors=%s",
		family,
		value,
		pieceId,
		tostring(result.valid),
		result.progress,
		result.speed,
		tostring(result.completedPiece),
		result.maxBounceHeight,
		tostring(result.solverInstability),
		tostring(result.antiStallSeen),
		tostring(result.motorsEnabled)
	))
end

local function structurallyUsable(result: any): boolean
	return result.valid == true and result.motorsEnabled == true
end

local function runBodyDensitySweep(): boolean
	local valid = true
	for _, bodyDensity in BODY_DENSITY_CANDIDATES do
		local tuning = tuningWith({ bodyDensity = bodyDensity })
		local flat = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, { tuning = tuning })
		local steps = runSteps(tuning)
		printFlatTrial("bodyDensity", bodyDensity, flat)
		printPieceTrial("bodyDensity", bodyDensity, STEPS_ID, steps)
		valid = valid and structurallyUsable(flat) and structurallyUsable(steps)
	end
	return valid
end

local function runLegDensitySweep(): boolean
	local valid = true
	for _, legDensity in LEG_DENSITY_CANDIDATES do
		local tuning = tuningWith({ legDensity = legDensity })
		local flat = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, { tuning = tuning })
		local wall = runWall(tuning)
		printFlatTrial("legDensity", legDensity, flat)
		printPieceTrial("legDensity", legDensity, WALL_ID, wall)
		valid = valid and structurallyUsable(flat) and structurallyUsable(wall)
	end
	return valid
end

local function runMotorSpeedSweep(): boolean
	local valid = true
	for _, motorAngularVelocity in MOTOR_SPEED_CANDIDATES do
		local tuning = tuningWith({ motorAngularVelocity = motorAngularVelocity })
		local flat = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, { tuning = tuning })
		local steps = runSteps(tuning)
		local wall = runWall(tuning)
		printFlatTrial("motorAngularVelocity", motorAngularVelocity, flat)
		printPieceTrial("motorAngularVelocity", motorAngularVelocity, STEPS_ID, steps)
		printPieceTrial("motorAngularVelocity", motorAngularVelocity, WALL_ID, wall)
		valid = valid
			and structurallyUsable(flat)
			and structurallyUsable(steps)
			and structurallyUsable(wall)
	end
	return valid
end

local function runFrictionSweep(): boolean
	local valid = true
	for _, bodyFriction in FRICTION_CANDIDATES do
		local tuning = tuningWith({ bodyFriction = bodyFriction })
		local flat = R16TrialRunner.RunFlatTelemetry(SHAPE_ID, { tuning = tuning })
		local wall = runWall(tuning)
		printFlatTrial("bodyFriction", bodyFriction, flat)
		printPieceTrial("bodyFriction", bodyFriction, WALL_ID, wall)
		valid = valid and structurallyUsable(flat) and structurallyUsable(wall)
	end
	return valid
end

function R17BodyFeelExperiment.RunEvidence(): boolean
	assert(RunService:IsStudio(), "R17BodyFeelExperiment is Studio-only")
	print(string.format(
		"[DrawRacers][R17.6] ordered reference-feel evidence starting baseline bodyDensity=%.3f legDensity=%.3f motor=%.3f bodyFriction=%.3f torque=%.0f acceleration=%.0f",
		BASE_BODY_DENSITY,
		BASE_LEG_DENSITY,
		BASE_MOTOR_SPEED,
		BASE_BODY_FRICTION,
		PhysicsConfig.Motor.MotorMaxTorque,
		PhysicsConfig.Motor.MotorMaxAcceleration
	))

	local bodyDensityValid = runBodyDensitySweep()
	local legDensityValid = runLegDensitySweep()
	local motorSpeedValid = runMotorSpeedSweep()
	local frictionValid = runFrictionSweep()
	R16TrialRunner.DestroyActive()

	-- Each trial creates and destroys a temporary racer, so production config and
	-- the next trial always begin from the same baseline. A human still chooses
	-- winners from the printed evidence; this harness never writes tuning back.
	print("[DrawRacers][R17.6] HUMAN BODY FEEL CHOICE PENDING")
	return bodyDensityValid and legDensityValid and motorSpeedValid and frictionValid
end

return R17BodyFeelExperiment
