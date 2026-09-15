--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local B09TwoLegPhaseHarness = {}

function B09TwoLegPhaseHarness.start()
	local racer = RacerRuntime.new({
		raceId = "B09_DEMO",
		slotIndex = 7,
		laneIndex = 1,
		isBot = true,
		trackId = "B09_FLAT",
		spawnCFrame = CFrame.new(52, 3.30, 0),
		laneCenterZ = 0,
	})

	local body = racer:GetBody()
	body.Transparency = 0.25
	body.Color = Color3.fromRGB(255, 120, 45)
	body.Material = Enum.Material.SmoothPlastic

	racer:ApplyShape(R16ReferenceShapes.Get("ROUND_01"), true)

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B09 shared-drive pair missing")
	local drive = pair:GetDrive()
	local startX = body.Position.X

	print(string.format(
		"[DrawRacers][B09] shared-drive ready axlePhase=%.1f fixedRightPhase=%d",
		drive:GetPhaseDegrees(),
		PhysicsConfig.LegGeometry.RightLegFixedPhaseDegrees
	))

	task.spawn(function()
		for second = 1, 6 do
			task.wait(1)
			if body.Parent == nil then
				return
			end
			print(string.format(
				"[DrawRacers][B09] t=%ds deltaX=%.3f speedX=%.3f pairPhaseError=%.1f",
				second,
				body.Position.X - startX,
				body.AssemblyLinearVelocity.X,
				pair:GetPhaseErrorDegrees()
			))
		end
	end)
end

return B09TwoLegPhaseHarness
