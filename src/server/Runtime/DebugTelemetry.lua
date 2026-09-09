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

	for _, leg in legs:GetChildren() do
		if leg:IsA("Model") then
			local segments = leg:FindFirstChild("Segments")
			if segments and segments:IsA("Folder") then
				for _, child in segments:GetChildren() do
					if child:IsA("BasePart") then
						count += 1
					end
				end
			end
		end
	end
	return count
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
	local simplifiedPoints = getNumberAttribute(model, "DebugSimplifiedPoints", 0)
	local checkpoint = getNumberAttribute(model, "Checkpoint", 0)
	local progress = getNumberAttribute(model, "Progress", 0)

	model:SetAttribute("DebugShapeVersion", shapeVersion)
	model:SetAttribute("DebugSimplifiedPoints", simplifiedPoints)
	model:SetAttribute("DebugColliderSegments", countColliderSegments(model))
	model:SetAttribute("DebugBodySpeed", bodySpeed)
	model:SetAttribute("DebugMotorAngularVelocity", PhysicsConfig.Motor.AngularVelocity)
	model:SetAttribute("DebugStuckState", sampleStuckState(model, body, now))
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
