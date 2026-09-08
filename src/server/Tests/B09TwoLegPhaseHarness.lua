--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B09TwoLegPhaseHarness = {}

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

function B09TwoLegPhaseHarness.start()
	local racer = RacerRuntime.new({
		raceId = "B09_DEMO",
		slotIndex = 7,
		laneIndex = 1,
		isBot = true,
		trackId = "B09_FLAT",
		spawnCFrame = CFrame.new(52, 3.30, 0),
	})

	local body = racer:GetBody()
	body.Transparency = 0.25
	body.Color = Color3.fromRGB(255, 120, 45)
	body.Material = Enum.Material.SmoothPlastic

	local leftLeg, rightLeg = racer:ApplyShape(ROUND_01, true)
	local startX = body.Position.X
	print(string.format(
		"[DrawRacers][B09] two-leg harness ready leftPhase=%.0f rightPhase=%.0f",
		leftLeg:GetInitialPhaseDegrees(),
		rightLeg:GetInitialPhaseDegrees()
	))

	task.spawn(function()
		for second = 1, 6 do
			task.wait(1)
			if body.Parent == nil then
				return
			end

			print(string.format(
				"[DrawRacers][B09] t=%ds deltaX=%.3f speedX=%.3f",
				second,
				body.Position.X - startX,
				body.AssemblyLinearVelocity.X
			))
		end
	end)
end

return B09TwoLegPhaseHarness
