--!strict

local Workspace = game:GetService("Workspace")

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B06RacerRuntimeSpec = {}

local function assertVectorClose(actual: Vector3, expected: Vector3, epsilon: number, message: string)
	assert((actual - expected).Magnitude <= epsilon, string.format("%s: expected %s got %s", message, tostring(expected), tostring(actual)))
end

function B06RacerRuntimeSpec.run()
	local template = RacerRuntime.EnsureTemplate()
	assert(template.Name == "RacerTemplate")
	assert(template.Parent ~= nil and template.Parent.Name == "RacerTemplates")
	assert(template:FindFirstChildWhichIsA("Humanoid", true) == nil, "RacerTemplate must not contain Humanoid")

	local body = template:FindFirstChild("BodyCollider")
	assert(body and body:IsA("Part"), "RacerTemplate missing BodyCollider")
	assert(template.PrimaryPart == body, "BodyCollider must be RacerTemplate.PrimaryPart")
	assert(body.Size == Vector3.new(3, 3, 3), "BodyCollider must be exact 3x3x3 baseline")
	assert(body.Anchored == false)
	assert(body.CanCollide == true)
	assert(body.CanTouch == true)
	assert(body.CanQuery == true)
	assert(body.Transparency == 1)
	assert(body.CollisionGroup == "RacerBody")

	local visualRoot = template:FindFirstChild("VisualRoot")
	assert(visualRoot and (visualRoot:IsA("Folder") or visualRoot:IsA("Model")), "RacerTemplate missing VisualRoot")

	local leftHub = template:FindFirstChild("LeftHub")
	local rightHub = template:FindFirstChild("RightHub")
	assert(leftHub and leftHub:IsA("Part"), "RacerTemplate missing LeftHub")
	assert(rightHub and rightHub:IsA("Part"), "RacerTemplate missing RightHub")
	assert(leftHub:FindFirstChild("MotorAttachment") and leftHub.MotorAttachment:IsA("Attachment"), "LeftHub missing MotorAttachment")
	assert(rightHub:FindFirstChild("MotorAttachment") and rightHub.MotorAttachment:IsA("Attachment"), "RightHub missing MotorAttachment")

	assertVectorClose(body.CFrame:PointToObjectSpace(leftHub.Position), Vector3.new(0, -0.75, -1.62), 1e-4, "LeftHub offset")
	assertVectorClose(body.CFrame:PointToObjectSpace(rightHub.Position), Vector3.new(0, -0.75, 1.62), 1e-4, "RightHub offset")

	local runtimeAttachments = template:FindFirstChild("RuntimeAttachments")
	assert(runtimeAttachments and runtimeAttachments:IsA("Folder"), "RacerTemplate missing RuntimeAttachments")
	assert(runtimeAttachments:FindFirstChild("LaneAlignAttachment") and runtimeAttachments.LaneAlignAttachment:IsA("Attachment"), "missing LaneAlignAttachment")
	assert(runtimeAttachments:FindFirstChild("OrientationAttachment") and runtimeAttachments.OrientationAttachment:IsA("Attachment"), "missing OrientationAttachment")

	local racersRoot = Workspace:WaitForChild("Runtime"):WaitForChild("Racers")
	local racer = RacerRuntime.new({
		raceId = "B06_TEST",
		slotIndex = 1,
		laneIndex = 1,
		isBot = false,
		trackId = "B06_FLAT",
		spawnCFrame = CFrame.new(0, 8, 0),
	})

	local model = racer:GetModel()
	assert(model.Parent == racersRoot, "runtime racer must spawn under Workspace.Runtime.Racers")
	assert(model.Name == "Racer_B06_TEST_1")
	assert(model:GetAttribute("RaceId") == "B06_TEST")
	assert(model:GetAttribute("SlotIndex") == 1)
	assert(model:GetAttribute("LaneIndex") == 1)
	assert(model:GetAttribute("IsBot") == false)
	assert(model:GetAttribute("ShapeVersion") == 0)
	assert(model:GetAttribute("TrackId") == "B06_FLAT")
	assert(model:GetAttribute("Finished") == false)
	assert(model:FindFirstChild("Legs") and model.Legs:IsA("Folder"), "runtime racer missing Legs root")
	assert(model:FindFirstChild("Presentation") and model.Presentation:IsA("Folder"), "runtime racer missing Presentation root")
	assert(model:FindFirstChildWhichIsA("Humanoid", true) == nil, "runtime racer must not contain Humanoid")
	assertVectorClose(racer:GetBody().Position, Vector3.new(0, 8, 0), 1e-4, "runtime spawn position")

	racer:Destroy()
	assert(racer:IsDestroyed(), "RacerRuntime must report destroyed state")
	assert(model.Parent == nil, "destroy must remove runtime model from Workspace")
	assert(racersRoot:FindFirstChild("Racer_B06_TEST_1") == nil, "destroy left racer model behind")

	print("[DrawRacers][B06] RacerTemplate/RacerRuntime tests PASS")
end

return B06RacerRuntimeSpec
