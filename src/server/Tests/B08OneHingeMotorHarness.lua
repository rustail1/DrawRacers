--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local R16ReferenceShapes = require(script.Parent:WaitForChild("R16ReferenceShapes"))

local B08OneHingeMotorHarness = {}
local activeRacer: any = nil

function B08OneHingeMotorHarness.start()
	if activeRacer ~= nil then return end

	local racer = RacerRuntime.new({
		raceId = "B08_TWIN_HINGE",
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
	assert(pair ~= nil, "B08 twin-drive pair missing")
	local leftJoint = pair:GetLeftDrive():GetJoint()
	local rightJoint = pair:GetRightDrive():GetJoint()
	assert(leftJoint.Name == "DriveJoint" and leftJoint:IsA("HingeConstraint"), "B08 left DriveJoint missing")
	assert(rightJoint.Name == "DriveJoint" and rightJoint:IsA("HingeConstraint"), "B08 right DriveJoint missing")
	assert(leftJoint.Enabled == true and rightJoint.Enabled == true, "B08 twin motors must be enabled")

	local hingeCount = 0
	for _, descendant in racer:GetModel():GetDescendants() do
		if descendant:IsA("HingeConstraint") then hingeCount += 1 end
	end
	assert(hingeCount == 2, string.format("B08 expected two CR2 drive hinges, got %d", hingeCount))

	local body = racer:GetBody()
	local startX = body.Position.X
	print("[DrawRacers][B08] CR2 twin-hinge flat harness ready")

	task.delay(2, function()
		if activeRacer ~= racer or racer:IsDestroyed() then return end
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
