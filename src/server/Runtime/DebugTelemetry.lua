--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)

local DebugTelemetry = {}

local connection: RBXScriptConnection? = nil
local elapsed = 0
local progressStateByModel: any = setmetatable({}, { __mode = "k" })

local function environmentAllowed(): boolean
	if RunService:IsStudio() then
		return true
	end
	local environment = game:GetAttribute("DrawRacersEnvironment")
	return environment == "DEV" or environment == "STAGING"
end

local function countColliderSegments(model: Model): number
	local count = 0
	local legs = model:FindFirstChild("Legs")
	if not legs then
		return count
	end

	for _, descendant in legs:GetDescendants() do
		if descendant:IsA("BasePart")
			and string.match(descendant.Name, "^Segment_%d+$")
		then
			count += 1
		end
	end
	return count
end

local function getMotorState(model: Model): (boolean, number)
	local legs = model:FindFirstChild("Legs")
	if not legs then
		return false, 0
	end

	local drive = legs:FindFirstChild("SharedLegDrive")
	if not (drive and drive:IsA("Model")) then
		return false, 0
	end

	local joint = drive:FindFirstChild("DriveJoint", true)
	if not (joint and joint:IsA("HingeConstraint")) then
		return false, 0
	end

	return joint.Enabled, joint.AngularVelocity
end

local function getNumberAttribute(model: Model, name: string, fallback: number): number
	local value = model:GetAttribute(name)
	if type(value) == "number" then
		return value
	end
	return fallback
end

local function sampleStuckState(model: Model, body: BasePart, now: number): boolean
	local recovery = PhysicsConfig.Recovery
	local state = progressStateByModel[model]
	if state == nil then
		state = {
			windowStartAt = now,
			windowStartX = body.Position.X,
			stuck = false,
		}
		progressStateByModel[model] = state
		return false
	end

	local windowElapsed = now - state.windowStartAt
	if windowElapsed >= recovery.ProgressSampleWindow then
		local horizontalProgress = body.Position.X - state.windowStartX
		state.stuck = horizontalProgress < recovery.MeaningfulHorizontalProgress
		state.windowStartAt = now
		state.windowStartX = body.Position.X
	end

	return state.stuck
end

function DebugTelemetry.sampleRacer(model: Model, nowOverride: number?)
	local body = model:FindFirstChild("BodyCollider")
	if not body or not body:IsA("BasePart") then
		return
	end

	local now = nowOverride or os.clock()
	local laneCenterZ = getNumberAttribute(model, "LaneCenterZ", body.Position.Z)
	local bodySpeed = body.AssemblyLinearVelocity.Magnitude
	local shapeVersion = getNumberAttribute(model, "ShapeVersion", 0)
	local rawPoints = getNumberAttribute(model, "DebugRawPoints", 0)
	local simplifiedPoints = getNumberAttribute(model, "DebugSimplifiedPoints", 0)
	local physicsPoints = getNumberAttribute(model, "DebugPhysicsPoints", 0)
	local checkpoint = getNumberAttribute(model, "Checkpoint", 0)
	local progress = getNumberAttribute(model, "Progress", 0)
	local motorEnabled, motorAngularVelocity = getMotorState(model)

	model:SetAttribute("DebugShapeVersion", shapeVersion)
	model:SetAttribute("DebugRawPoints", rawPoints)
	model:SetAttribute("DebugSimplifiedPoints", simplifiedPoints)
	model:SetAttribute("DebugPhysicsPoints", physicsPoints)
	model:SetAttribute("DebugColliderSegments", countColliderSegments(model))
	model:SetAttribute("DebugBodySpeed", bodySpeed)
	model:SetAttribute("DebugMotorEnabled", motorEnabled)
	model:SetAttribute("DebugMotorAngularVelocity", motorAngularVelocity)
	model:SetAttribute("DebugStuckState", sampleStuckState(model, body, now))
	model:SetAttribute("DebugAntiStallActive", model:GetAttribute("AntiStallActive") == true)
	model:SetAttribute("DebugLaneDeviation", body.Position.Z - laneCenterZ)
	model:SetAttribute("DebugCheckpoint", checkpoint)
	model:SetAttribute("DebugProgress", progress)
end

function DebugTelemetry.start()
	if connection ~= nil or not environmentAllowed() then
		return
	end

	local runtime = Workspace:WaitForChild("Runtime")
	local racers = runtime:WaitForChild("Racers")

	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.20 then
			return
		end
		elapsed = 0

		for _, child in racers:GetChildren() do
			if child:IsA("Model") then
				DebugTelemetry.sampleRacer(child)
			end
		end
	end)
end

function DebugTelemetry.stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	elapsed = 0
	table.clear(progressStateByModel)
end

return DebugTelemetry
