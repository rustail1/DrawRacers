--!strict

local C03CoreV3ClearanceSpec = {}

local function requireCoreV3Modules()
	local runtimeFolder = script.Parent.Parent:FindFirstChild("Runtime")
	assert(runtimeFolder ~= nil, "Runtime folder missing")

	local coreFolder = runtimeFolder:FindFirstChild("CoreV3")
	assert(coreFolder ~= nil, "CoreV3 runtime folder missing")

	local clearanceModule = coreFolder:FindFirstChild("LegClearanceController")
	assert(clearanceModule ~= nil and clearanceModule:IsA("ModuleScript"), "CoreV3 LegClearanceController module missing")

	local configModule = coreFolder:FindFirstChild("LegCoreConfig")
	assert(configModule ~= nil and configModule:IsA("ModuleScript"), "CoreV3 LegCoreConfig module missing")

	return require(clearanceModule), require(configModule)
end

local function makeGhostSegment(parent: Instance, name: string, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(2.0, 0.5, 0.5)
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Transparency = 1
	part.Parent = parent
	return part
end

local function makeLeg(parts: { BasePart }, collisionParts: { BasePart }?)
	local authoritative = collisionParts or parts
	return {
		GetPhysicalSegments = function()
			return parts
		end,
		GetCollisionSegments = function()
			return authoritative
		end,
	}
end

local function snapshotPart(part: BasePart)
	return {
		cframe = part.CFrame,
		canCollide = part.CanCollide,
		canTouch = part.CanTouch,
		canQuery = part.CanQuery,
	}
end

local function assertSnapshotUnchanged(part: BasePart, before, label: string)
	assert(part.CFrame == before.cframe, label .. " CFrame mutated")
	assert(part.CanCollide == before.canCollide, label .. " CanCollide mutated")
	assert(part.CanTouch == before.canTouch, label .. " CanTouch mutated")
	assert(part.CanQuery == before.canQuery, label .. " CanQuery mutated")
end

function C03CoreV3ClearanceSpec.run()
	local Clearance, LegCoreConfig = requireCoreV3Modules()

	local testModel = Instance.new("Model")
	testModel.Name = "C03CoreV3ClearanceTest"
	testModel.Parent = workspace

	local trackRoot = Instance.new("Model")
	trackRoot.Name = "TrackRoot"
	trackRoot.Parent = testModel

	local track = Instance.new("Part")
	track.Name = "FlatTrack"
	track.Size = Vector3.new(40, 1, 20)
	track.CFrame = CFrame.new(0, 0, 0)
	track.Anchored = true
	track.CanCollide = true
	track.CanTouch = true
	track.CanQuery = true
	track.Parent = trackRoot

	local body = Instance.new("Part")
	body.Name = "BodyCollider"
	body.Size = Vector3.new(3, 3, 3)
	body.CFrame = CFrame.new(0, 5, 0)
	body.Anchored = true
	body.CanCollide = true
	body.Parent = testModel

	local leftPart = makeGhostSegment(testModel, "LeftGhost", CFrame.new(0, 3, -2))
	local rightPart = makeGhostSegment(testModel, "RightGhost", CFrame.new(0, 3, 2))
	local leftLeg = makeLeg({ leftPart })
	local rightLeg = makeLeg({ rightPart })

	local ok, failure = xpcall(function()
		-- Case A: the complete pair is already clear.
		local clearResult = Clearance.Evaluate(body, leftLeg, rightLeg, trackRoot)
		assert(clearResult.clear == true, "C03 clear pair must report clear")
		assert(clearResult.requiredLift == 0, "C03 clear pair must require zero lift")

		-- Case B: both sides intersect the floor and require a bounded +Y lift.
		leftPart.CFrame = CFrame.new(0, 0.5, -2)
		rightPart.CFrame = CFrame.new(0, 0.5, 2)
		local blockedResult = Clearance.Evaluate(body, leftLeg, rightLeg, trackRoot)
		assert(blockedResult.clear == false, "C03 intersecting pair must not report clear")
		assert(blockedResult.requiredLift > 0, "C03 intersecting pair must require positive lift")
		assert(
			blockedResult.requiredLift <= LegCoreConfig.Rebuild.MaxLift,
			"C03 requiredLift must stay bounded by Core V3 max lift"
		)

		-- Case C: pair-wide semantics. One clear side does not make the pair clear.
		leftPart.CFrame = CFrame.new(0, 3, -2)
		rightPart.CFrame = CFrame.new(0, 0.5, 2)
		local oneSideBlocked = Clearance.Evaluate(body, leftLeg, rightLeg, trackRoot)
		assert(oneSideBlocked.clear == false, "C03 pair must remain blocked when only one side intersects")
		assert(oneSideBlocked.requiredLift > 0, "C03 blocked side must contribute to pair requiredLift")

		-- Case D: a non-authoritative hub segment may overlap Track without
		-- blocking activation. Clearance evaluates only canCollide=true geometry.
		local leftHub = makeGhostSegment(testModel, "LeftNonColliderHub", CFrame.new(0, 0.5, -2))
		local rightHub = makeGhostSegment(testModel, "RightNonColliderHub", CFrame.new(0, 0.5, 2))
		leftPart.CFrame = CFrame.new(0, 3, -2)
		rightPart.CFrame = CFrame.new(0, 3, 2)
		local hubOnlyOverlap = Clearance.Evaluate(
			body,
			makeLeg({ leftHub, leftPart }, { leftPart }),
			makeLeg({ rightHub, rightPart }, { rightPart }),
			trackRoot
		)
		assert(hubOnlyOverlap.clear == true, "C03 non-authoritative hub overlap must not block pair")
		assert(hubOnlyOverlap.requiredLift == 0, "C03 non-authoritative hub overlap must require zero lift")

		-- Case E: Evaluate is pure with respect to body/leg/track Instance state.
		local bodyBefore = snapshotPart(body)
		local leftBefore = snapshotPart(leftPart)
		local rightBefore = snapshotPart(rightPart)
		local trackBefore = snapshotPart(track)

		Clearance.Evaluate(body, leftLeg, rightLeg, trackRoot)

		assertSnapshotUnchanged(body, bodyBefore, "C03 body")
		assertSnapshotUnchanged(leftPart, leftBefore, "C03 left leg")
		assertSnapshotUnchanged(rightPart, rightBefore, "C03 right leg")
		assertSnapshotUnchanged(track, trackBefore, "C03 track")
	end, debug.traceback)

	testModel:Destroy()
	assert(ok, failure)
	print("[DrawRacers][C03] Core V3 whole-pair clearance PASS")
end

return C03CoreV3ClearanceSpec
