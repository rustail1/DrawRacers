--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B10StabilizationHarness = {}

local ROUND_01 = {
	Vector2.new(0.72, 0),
	Vector2.new(0.624, 0.36),
	Vector2.new(0.36, 0.624),
	Vector2.new(0, 0.72),
	Vector2.new(-0.36, 0.624),
	Vector2.new(-0.624, 0.36),
	Vector2.new(-0.72, 0),
	Vector2.new(-0.624, -0.36),
	Vector2.new(-0.36, -0.624),
	Vector2.new(0, -0.72),
	Vector2.new(0.36, -0.624),
	Vector2.new(0.624, -0.36),
}

function B10StabilizationHarness.start()
	local racer = RacerRuntime.new({
		raceId = "B10_MOTION",
		slotIndex = 6,
		laneIndex = 1,
		isBot = true,
		trackId = "B10_FLAT",
		spawnCFrame = CFrame.new(55, 3.30, 0),
		laneCenterZ = 0,
	})

	local body = racer:GetBody()
	body.Transparency = 0.30
	body.Color = Color3.fromRGB(125, 235, 120)
	body.Material = Enum.Material.SmoothPlastic
	racer:ApplyShape(ROUND_01, true)

	local startX = body.Position.X
	print("[DrawRacers][B10] stabilized two-leg harness ready")

	task.spawn(function()
		for second = 1, 6 do
			task.wait(1)
			if body.Parent == nil then
				return
			end

			local rx, _, rz = body.CFrame:ToOrientation()
			local deltaX = body.Position.X - startX
			local zError = math.abs(body.Position.Z)
			print(string.format(
				"[DrawRacers][B10] t=%ds deltaX=%.3f zError=%.3f pitch=%.1f roll=%.1f hard=%s",
				second,
				deltaX,
				zError,
				math.deg(rx),
				math.deg(rz),
				tostring(racer:GetModel():GetAttribute("LaneHardBoundExceeded"))
			))
		end
	end)
end

return B10StabilizationHarness
