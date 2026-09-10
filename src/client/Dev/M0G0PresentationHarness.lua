--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StudioHarnessConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("StudioHarnessConfig")
)

local M0G0PresentationHarness = {}

local connection: RBXScriptConnection? = nil
local debugProxy: Part? = nil

local function findDebugBody(): BasePart?
	local runtime = Workspace:FindFirstChild("Runtime")
	local racers = runtime and runtime:FindFirstChild("Racers")
	if racers == nil then
		return nil
	end
	for _, racer in racers:GetChildren() do
		if racer:IsA("Model") and racer:GetAttribute("DebugTarget") == true then
			local body = racer:FindFirstChild("BodyCollider")
			if body and body:IsA("BasePart") then
				return body
			end
		end
	end
	return nil
end

local function ensureDebugProxy(body: BasePart): Part
	if debugProxy ~= nil and debugProxy.Parent ~= nil then
		return debugProxy
	end

	local proxy = Instance.new("Part")
	proxy.Name = "G0DebugBodyProxy"
	proxy.Anchored = true
	proxy.CanCollide = false
	proxy.CanTouch = false
	proxy.CanQuery = false
	proxy.Massless = true
	proxy.Size = body.Size + Vector3.new(0.08, 0.08, 0.08)
	proxy.Material = Enum.Material.SmoothPlastic
	proxy.Color = Color3.fromRGB(80, 180, 245)
	proxy.Transparency = 0
	proxy.CastShadow = false

	local runtime = Workspace:FindFirstChild("Runtime")
	local presentation = runtime and runtime:FindFirstChild("RacePresentation")
	proxy.Parent = presentation or Workspace
	debugProxy = proxy
	return proxy
end

local function updatePresentation()
	local body = findDebugBody()
	if body == nil then
		if debugProxy ~= nil then
			debugProxy.Transparency = 1
		end
		return
	end

	local proxy = ensureDebugProxy(body)
	proxy.Size = body.Size + Vector3.new(0.08, 0.08, 0.08)
	proxy.CFrame = body.CFrame
	proxy.Transparency = 0
end

function M0G0PresentationHarness.start()
	if not RunService:IsStudio() then
		return
	end
	if StudioHarnessConfig.Mode ~= "G0" and StudioHarnessConfig.Mode ~= "R16FINAL" then
		return
	end
	if connection ~= nil then
		return
	end

	connection = RunService.RenderStepped:Connect(updatePresentation)
	updatePresentation()
	print("[DrawRacers][R16.3B] G0 debug presentation harness ready")
end

function M0G0PresentationHarness.stop()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
	if debugProxy ~= nil then
		debugProxy:Destroy()
		debugProxy = nil
	end
end

return M0G0PresentationHarness
