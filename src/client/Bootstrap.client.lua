--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local controllers = script.Parent:WaitForChild("Controllers")
local InputController = require(controllers:WaitForChild("InputController"))

local function startB01StudioHarness()
	if not RunService:IsStudio() then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local drawHud = playerGui:WaitForChild("DrawHUD") :: ScreenGui

	local oldHarness = drawHud:FindFirstChild("B01InputHarness")
	if oldHarness then
		oldHarness:Destroy()
	end

	local harness = Instance.new("Frame")
	harness.Name = "B01InputHarness"
	harness.AnchorPoint = Vector2.new(0.5, 1)
	harness.Position = UDim2.fromScale(0.5, 0.975)
	harness.Size = UDim2.fromScale(0.46, 0.255)
	harness.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
	harness.BackgroundTransparency = 0.18
	harness.BorderSizePixel = 0
	harness.ZIndex = 25
	harness.Parent = drawHud

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 22)
	corner.Parent = harness

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = harness

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.94, 0.82)
	label.Position = UDim2.fromScale(0.03, 0.09)
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(245, 248, 255)
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = "B01 INPUT HARNESS\nDRAG HERE WITH MOUSE / TOUCH"
	label.ZIndex = 26
	label.Parent = harness

	local inputController = InputController.new()
	local moveCount = 0

	inputController:Connect(function(event)
		if event.phase == "start" then
			moveCount = 0
		elseif event.phase == "move" then
			moveCount += 1
		end

		label.Text = string.format(
			"B01 INPUT HARNESS\n%s  |  %s  |  id %d\nmove events: %d\n(%.0f, %.0f)",
			string.upper(event.family),
			string.upper(event.phase),
			event.pointerId,
			moveCount,
			event.position.X,
			event.position.Y
		)

		if event.phase ~= "move" or moveCount % 10 == 0 then
			print(string.format(
				"[DrawRacers][B01] family=%s phase=%s pointer=%d moves=%d pos=(%.0f,%.0f)",
				event.family,
				event.phase,
				event.pointerId,
				moveCount,
				event.position.X,
				event.position.Y
			))
		end
	end)

	inputController:Bind(harness)

	print("[DrawRacers][B01] Studio input harness ready")
end

startB01StudioHarness()

print("[DrawRacers] client bootstrap ready")
