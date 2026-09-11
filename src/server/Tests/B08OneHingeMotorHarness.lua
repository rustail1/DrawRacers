--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local B08OneHingeMotorHarness = {}
local activeRacer: any = nil

function B08OneHingeMotorHarness.start()
	if activeRacer ~= nil then
		return
	end

	local racer = RacerRuntime.new({
		raceId = "B08_ONE_HINGE",
		slotIndex = 1,
		laneIndex = 1,
		isBot = true,
		trackId = "B08_FLAT",
		spawnCFrame = CFrame.new(-42, 4, 0),
		laneCenterZ = 0,
	})
	activeRacer = racer
	racer:ApplyShape(R16ReferenceShapes.Get("ROUND_01"), true)

	local pair = racer:GetLegPair()
	assert(pair ~= nil, "B08 shared pair missing")
	local joint = pair:GetJoint()
	assert(joint.Name == "AxleJoint" and joint:IsA("HingeConstraint"), "B08 requires one AxleJoint")
	assert(joint.Enabled == true, "B08 AxleJoint motor must be enabled")

	local hingeCount = 0
	for _, descendant in racer:GetModel():GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			hingeCount += 1
		end
	end
	assert(hingeCount == 1, string.format("B08 expected one shared hinge, got %d", hingeCount))

	local body = racer:GetBody()
	local startX = body.Position.X
	print("[DrawRacers][B08] one-hinge flat harness ready")

	task.delay(2, function()
		if activeRacer ~= racer or racer:IsDestroyed() then
			return
		end
		local deltaX = body.Position.X - startX
		print(string.format("[DrawRacers][B08] deltaX=%.3f", deltaX))
	end)
end

function B08OneHingeMotorHarness.stop()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
end

return B08OneHingeMotorHarness
