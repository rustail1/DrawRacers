--!strict

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))

local B07LegAssemblySpec = {}

local SHAPE = {
	Vector2.zero,
	Vector2.new(0.35, 0.72),
	Vector2.new(0.90, 0.15),
	Vector2.new(0.25, -0.82),
}

local function collectPreviewParts(folder: Folder): { [string]: BasePart }
	local result = {}
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") then
			result[child.Name] = child
		end
	end
	return result
end

function B07LegAssemblySpec.run()
	local racer = RacerRuntime.new({
		raceId = "B07_TEST",
		slotIndex = 1,
		laneIndex = 1,
		isBot = false,
		trackId = "B07_FLAT",
		spawnCFrame = CFrame.new(-40, 12, 0),
		laneCenterZ = 0,
	})

	local body = racer:GetBody()
	body.Anchored = true

	local left, right = racer:ApplyShape(SHAPE, false)
	assert(left:GetModel().Name == "LeftLeg")
	assert(right:GetModel().Name == "RightLeg")
	assert(left:GetRoot().CanCollide == false)
	assert(left:GetRoot().Massless == true)

	local driveWeld = left:GetRoot():FindFirstChild("DriveWeld")
	assert(driveWeld and driveWeld:IsA("WeldConstraint"), "B07 missing DriveWeld")

	for _, segment in left:GetSegments() do
		assert(segment.Massless == true, "drawn collider must not change racer mass")
		assert(segment.CollisionGroup == "RacerLeg")
		assert(segment.Transparency == 1)
	end

	local shapeSpec = racer:GetCurrentShapeSpec()
	assert(shapeSpec ~= nil, "B07 missing current ShapeSpec")

	-- Preview must be visual-only and pooled for the whole redraw.
	left:ClearCurrentGeometry()
	left:BeginPreview(shapeSpec)
	local preview = left:GetModel():FindFirstChild("Preview")
	assert(preview and preview:IsA("Folder"), "B07 preview folder missing")

	local initialParts = collectPreviewParts(preview)
	assert(next(initialParts) ~= nil, "B07 preview pool empty")
	assert(#left:GetSegments() == 0, "preview must not create physical colliders")

	for _, progress in { 0.20, 0.45, 0.70, 1.0 } do
		left:SetPreviewProgress(progress)
		local samePreview = left:GetModel():FindFirstChild("Preview")
		assert(samePreview == preview, "preview folder was recreated during progress update")
		for name, part in initialParts do
			assert(samePreview:FindFirstChild(name) == part, "preview part was recreated: " .. name)
		end
	end

	left:CancelPreview()
	assert(left:GetModel():FindFirstChild("Preview") == nil, "preview cleanup failed")

	left:InstallGeometry(shapeSpec)
	assert(#left:GetSegments() == #shapeSpec.segmentPlan, "final collider count mismatch")
	for _, segment in left:GetSegments() do
		assert(segment.Massless == true, "final leg collider must remain massless")
	end

	racer:Destroy()
	print("[DrawRacers][B07] Leg Core v2 one-leg/preview-pool tests PASS")
end

return B07LegAssemblySpec
