--!strict

local C02CoreV3LegGeometrySpec = {}

local function requireLegGeometry()
	local runtimeFolder = script.Parent.Parent:FindFirstChild("Runtime")
	assert(runtimeFolder ~= nil, "Runtime folder missing")

	local coreFolder = runtimeFolder:FindFirstChild("CoreV3")
	assert(coreFolder ~= nil, "CoreV3 runtime folder missing")

	local module = coreFolder:FindFirstChild("LegGeometry")
	assert(module ~= nil and module:IsA("ModuleScript"), "CoreV3 LegGeometry module missing")
	return require(module)
end

local function makeShapeSpec()
	local mappedPoints = {
		Vector2.new(0, 0),
		Vector2.new(1.5, 0),
		Vector2.new(1.5, 1.2),
		Vector2.new(0.2, 1.8),
	}

	return {
		version = 1,
		normalizedPoints = mappedPoints,
		mappedPoints = mappedPoints,
		bounds = {
			min = Vector2.new(0, 0),
			max = Vector2.new(1.5, 1.8),
		},
		extent = 1.8,
		segmentPlan = {
			{ index = 1, a = mappedPoints[1], b = mappedPoints[2], canCollide = true },
			{ index = 2, a = mappedPoints[2], b = mappedPoints[3], canCollide = false },
			{ index = 3, a = mappedPoints[3], b = mappedPoints[4], canCollide = true },
		},
		debugRawPointCount = 4,
		debugPhysicsPointCount = 4,
		debugId = "C02_SYNTHETIC",
	}
end

local function collectNamedParts(root: Instance, prefix: string): { Part }
	local parts = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Part") and string.sub(descendant.Name, 1, #prefix) == prefix then
			table.insert(parts, descendant)
		end
	end
	table.sort(parts, function(a, b)
		return a.Name < b.Name
	end)
	return parts
end

local function assertSameInstances(before: { Part }, after: { Part })
	assert(#before == #after, "C02 preview Part count changed during grow")
	for index, part in before do
		assert(after[index] == part, string.format("C02 preview Part %d was recreated during grow", index))
	end
end

function C02CoreV3LegGeometrySpec.run()
	local LegGeometry = requireLegGeometry()

	local testModel = Instance.new("Model")
	testModel.Name = "C02CoreV3LegGeometryTest"
	testModel.Parent = workspace

	local mount = Instance.new("Part")
	mount.Name = "LeftMount"
	mount.Size = Vector3.new(0.2, 0.2, 0.2)
	mount.CFrame = CFrame.new(10, 8, -4)
	mount.Anchored = true
	mount.CanCollide = false
	mount.Parent = testModel

	local ok, failure = xpcall(function()
		local shapeSpec = makeShapeSpec()
		local leg = LegGeometry.new(mount, "Left")

		leg:BuildPreview(shapeSpec)
		local partsBefore = collectNamedParts(mount, "PreviewSegment_")
		assert(#partsBefore == #shapeSpec.segmentPlan, "C02 preview must allocate exactly one Part per segment")
		for _, part in partsBefore do
			assert(part.CanCollide == false, "C02 preview must never collide")
			assert(part.CanTouch == false, "C02 preview must never touch")
			assert(part.CanQuery == false, "C02 preview must never query")
			assert(part.Massless == true, "C02 preview must be massless")
			assert(part.CollisionGroup == "RacerLeg", "C02 preview must use RacerLeg collision group")
		end

		leg:SetPreviewProgress(0.2)
		leg:SetPreviewProgress(0.5)
		leg:SetPreviewProgress(1.0)

		local partsAfter = collectNamedParts(mount, "PreviewSegment_")
		assertSameInstances(partsBefore, partsAfter)

		leg:BuildPhysical(shapeSpec)
		local physical = leg:GetPhysicalSegments()
		assert(#physical == #shapeSpec.segmentPlan, "C02 physical segment count mismatch")
		local collisionSegments = leg:GetCollisionSegments()
		assert(#collisionSegments == 2, "C02 GetCollisionSegments must expose only authoritative colliders")
		assert(collisionSegments[1] == physical[1], "C02 first authoritative collider mapping mismatch")
		assert(collisionSegments[2] == physical[3], "C02 second authoritative collider mapping mismatch")
		for _, part in physical do
			assert(part.Transparency == 1, "C02 physical segment must be invisible")
			assert(part.Massless == true, "C02 physical segment must be massless")
			assert(part.CollisionGroup == "RacerLeg", "C02 physical segment must use RacerLeg collision group")
			local material = part.CustomPhysicalProperties
			assert(material ~= nil, "C02 physical segment must define physical properties")
			assert(math.abs((material :: PhysicalProperties).Friction - 1.0) < 1e-6, "C02 leg friction mismatch")
			assert(math.abs((material :: PhysicalProperties).FrictionWeight - 100) < 1e-6, "C02 leg friction weight mismatch")
		end

		leg:SetPhysicsEnabled(false)
		for _, part in physical do
			assert(part.CanCollide == false, "C02 PHYSICS_OFF must disable every collider")
			assert(part.CanTouch == false, "C02 PHYSICS_OFF must disable every touch")
		end

		leg:SetPhysicsEnabled(true)
		for index, part in physical do
			local authoritative = shapeSpec.segmentPlan[index].canCollide == true
			assert(part.CanCollide == authoritative, "C02 PHYSICS_ON must honor segmentPlan.canCollide atomically")
			assert(part.CanTouch == authoritative, "C02 PHYSICS_ON touch state must match authoritative collider state")
		end
		assert(physical[2].CanCollide == false, "C02 non-authoritative segment must stay noncolliding when pair is ON")

		leg:SetPhysicsEnabled(false)
		for _, part in physical do
			assert(part.CanCollide == false and part.CanTouch == false, "C02 pair must return fully to PHYSICS_OFF")
		end

		assert(#leg:GetMappedPoints() == #shapeSpec.mappedPoints, "C02 mapped points must match built shape")
		leg:Destroy()
	end, debug.traceback)

	testModel:Destroy()
	assert(ok, failure)
	print("[DrawRacers][C02] Core V3 LegGeometry PASS")
end

return C02CoreV3LegGeometrySpec
