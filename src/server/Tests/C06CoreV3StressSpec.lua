--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegShapeService = require(script.Parent.Parent.Services:WaitForChild("LegShapeService"))
local DriveAcceptanceGate = require(script.Parent:WaitForChild("CoreV3DriveAcceptanceGate"))

local C06CoreV3StressSpec = {}

local SHAPE_A = {
	Vector2.zero,
	Vector2.new(-0.55, 0.70),
	Vector2.new(0.10, 0.92),
	Vector2.new(0.72, 0.45),
	Vector2.new(1.30, -0.05),
	Vector2.new(0.45, -0.78),
	Vector2.new(-0.45, -0.68),
}

local SHAPE_B = {
	Vector2.zero,
	Vector2.new(-0.25, 0.75),
	Vector2.new(0.55, 0.60),
	Vector2.new(0.85, -0.30),
	Vector2.new(0.10, -0.85),
	Vector2.new(-0.70, -0.55),
}

local REDRAW_COUNT = 20
local STATE_TIMEOUT = 2.0

local LEGACY_SOURCE_KEYS = {
	"GetLeftDrive",
	"GetRightDrive",
	"PendingSegments",
	"PendingVisual",
	"retiredGeometry",
	"currentRetiredForRedraw",
	"NO_SAFE_REDRAW_PHASE",
}

local LEGACY_INSTANCE_NAME_FRAGMENTS = {
	"pending",
	"retired",
	"preparedgeometry",
	"stagevisual",
}

local function ensureFolder(parent: Instance, name: string): (Folder, boolean)
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing:IsA("Folder"), name .. " must be Folder")
		return existing, false
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder, true
end

local function waitForState(core: any, target: string, timeout: number)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if core:GetState() == target then
			return
		end
		RunService.Heartbeat:Wait()
	end
	error(string.format("C06 timed out waiting for state %s; current=%s", target, core:GetState()))
end

local function countClass(root: Instance, className: string): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA(className) then
			count += 1
		end
	end
	return count
end

local function countNamedModels(root: Instance, name: string): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == name then
			count += 1
		end
	end
	return count
end

local function collectLegOwners(root: Instance): { Model }
	local owners = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Model") and descendant:GetAttribute("CoreV3Leg") == true then
			table.insert(owners, descendant)
		end
	end
	return owners
end

local function collectPreviewFolders(root: Instance): { Folder }
	local folders = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Folder") and descendant.Name == "Preview" then
			table.insert(folders, descendant)
		end
	end
	return folders
end

local function assertNoLegacyGeometryNames(root: Instance)
	for _, descendant in root:GetDescendants() do
		local loweredName = string.lower(descendant.Name)
		for _, fragment in LEGACY_INSTANCE_NAME_FRAGMENTS do
			assert(
				string.find(loweredName, fragment, 1, true) == nil,
				string.format("C06 legacy geometry name leaked into Core V3 runtime: %s", descendant:GetFullName())
			)
		end
	end
end

local function assertNoLegacyApiKeys(label: string, value: any)
	if type(value) ~= "table" then
		return
	end

	for _, banned in LEGACY_SOURCE_KEYS do
		assert(value[banned] == nil, string.format("C06 %s exposes forbidden legacy API/key %s", label, banned))
	end
end

local function assertNoHorizontalForce(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("VectorForce") then
			assert(math.abs(descendant.Force.X) < 1e-6, "C06 Core V3 must never create horizontal VectorForce")
			assert(math.abs(descendant.Force.Z) < 1e-6, "C06 Core V3 clearance force must be vertical-only")
		end
	end
end

local function assertNoOrphanParts(model: Model, axleRootModel: Instance)
	local body = model:FindFirstChild("BodyCollider")
	assert(body ~= nil and body:IsA("Part"), "C06 racer missing BodyCollider")

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= body then
			assert(
				descendant:IsDescendantOf(axleRootModel),
				string.format("C06 orphan runtime BasePart found outside SharedAxle: %s", descendant:GetFullName())
			)
		end
	end
end

local function assertPairAtomic(core: any, shapeSpec: any)
	assert(core:GetState() == "ACTIVE", "C06 pair atomic check requires ACTIVE state")
	local left = core:GetLeftLeg()
	local right = core:GetRightLeg()
	assert(left ~= nil and right ~= nil, "C06 ACTIVE state requires two leg owners")

	for _, leg in { left, right } do
		local segments = leg:GetPhysicalSegments()
		assert(#segments == #shapeSpec.segmentPlan, "C06 physical segment count drifted from ShapeSpec")
		for index, part in segments do
			local planEntry = shapeSpec.segmentPlan[index]
			local expected = planEntry ~= nil and planEntry.canCollide == true
			assert(part.CanCollide == expected, "C06 ACTIVE pair contains partial/wrong collision state")
			assert(part.CanTouch == expected, "C06 ACTIVE pair contains partial/wrong touch state")
		end
	end
end

local function assertNoLeakedPreviews(model: Model, shapeSpec: any)
	local legOwners = collectLegOwners(model)
	assert(#legOwners == 2, "C06 ACTIVE racer must have exactly two Core V3 leg owners")

	local previews = collectPreviewFolders(model)
	assert(#previews == 2, "C06 ACTIVE racer must retain exactly two current visual preview pools and no leaked old pools")

	for _, preview in previews do
		local owner = preview.Parent
		assert(owner ~= nil and owner:IsA("Model"), "C06 preview pool must belong to a current leg owner")
		assert(owner:GetAttribute("CoreV3Leg") == true, "C06 preview pool escaped current Core V3 leg owner")

		local segmentCount = 0
		for _, child in preview:GetChildren() do
			if child:IsA("Part") and string.sub(child.Name, 1, #"PreviewSegment_") == "PreviewSegment_" then
				segmentCount += 1
			end
		end
		assert(segmentCount == #shapeSpec.segmentPlan, "C06 current visual pool segment count drifted")
	end
end

local function snapshotCounts(model: Model): { descendants: number, baseParts: number }
	return {
		descendants = #model:GetDescendants(),
		baseParts = countClass(model, "BasePart"),
	}
end

local function assertSameCounts(actual: { descendants: number, baseParts: number }, expected: { descendants: number, baseParts: number }, label: string)
	assert(actual.descendants == expected.descendants, string.format(
		"C06 %s descendant count leaked: expected %d, got %d",
		label,
		expected.descendants,
		actual.descendants
	))
	assert(actual.baseParts == expected.baseParts, string.format(
		"C06 %s BasePart count leaked: expected %d, got %d",
		label,
		expected.baseParts,
		actual.baseParts
	))
end

local function assertActiveStructure(racer: any, core: any, axle: any, joint: HingeConstraint, expectedCounts: { descendants: number, baseParts: number }?): { descendants: number, baseParts: number }
	local model = racer:GetModel()
	local shapeSpec = racer:GetCurrentShapeSpec()
	assert(shapeSpec ~= nil, "C06 ACTIVE racer must publish current ShapeSpec")

	assert(racer:GetLegCore() == core, "C06 redraw replaced LegCoreController")
	assert(core:GetSharedAxle() == axle, "C06 redraw replaced SharedAxle")
	assert(axle:GetJoint() == joint, "C06 redraw replaced HingeConstraint")
	assert(countClass(model, "HingeConstraint") == 1, "C06 racer must contain exactly one HingeConstraint")
	assert(countNamedModels(model, "SharedAxle") == 1, "C06 racer must contain exactly one SharedAxle model")
	assert(#collectLegOwners(model) == 2, "C06 racer must contain exactly two Core V3 leg owners")
	assert(model:FindFirstChild("CoreV3ClearanceLift", true) == nil, "C06 ACTIVE state leaked clearance VectorForce")
	assert(model:FindFirstChild("AntiStallForce", true) == nil, "C06 Core V3 validation leaked AntiStall helper")
	assert(model:FindFirstChild("BodyFloatForce", true) == nil, "C06 Core V3 validation leaked persistent BodyFloat helper")
	assert(model:FindFirstChild("OrientationAlign", true) == nil, "C06 Core V3 validation leaked stabilizer helper")
	assert(model:FindFirstChild("CoreV3ClearanceLiftAttachment", true) == nil, "C06 ACTIVE state leaked clearance Attachment")
	assertNoLeakedPreviews(model, shapeSpec)
	assertNoLegacyGeometryNames(model)
	assertPairAtomic(core, shapeSpec)
	assertNoHorizontalForce(model)
	local axleModel = axle:GetAxleRoot().Parent
	assert(axleModel ~= nil, "C06 SharedAxle root lost parent")
	assertNoOrphanParts(model, axleModel)

	local counts = snapshotCounts(model)
	if expectedCounts ~= nil then
		assertSameCounts(counts, expectedCounts, "stable redraw")
	end
	return counts
end

local function startStableRedraw(racer: any, body: Part, normalizedPoints: { Vector2 })
	-- Keep normal stress geometry deterministic without asking production Core V3
	-- to fight gravity. The body is unanchored only for the redraw hop itself so
	-- ApplyImpulse always targets a finite-mass assembly, then the test freezes it
	-- while PREVIEW/WAIT_CLEAR complete above the flat track.
	body.Anchored = false
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero

	local ok, failure = xpcall(function()
		racer:ApplyShape(normalizedPoints, false)
	end, debug.traceback)

	body.Anchored = true
	assert(ok, failure)
end

local function assertContinuousDriveGate()
	local gate = DriveAcceptanceGate.new()
	DriveAcceptanceGate.begin(gate, 0.30)
	assert(gate.eligibleFromRest == false, "C06 moving baseline must make flat locomotion acceptance inconclusive")
	assert(math.abs(gate.baselineVelocityX - 0.30) < 1e-6, "C06 drive gate must preserve baseline VX evidence")

	DriveAcceptanceGate.begin(gate, 0.0)
	assert(gate.eligibleFromRest == true, "C06 near-rest baseline must be eligible for flat locomotion acceptance")
	DriveAcceptanceGate.step(gate, 0.30, true, true, true, 0.10)
	assert(math.abs(gate.continuousRotationSeconds - 0.30) < 1e-6, "C06 drive gate must accumulate valid continuous rotation")
	assert(gate.sawPositiveVX == true, "C06 drive gate must remember positive forward velocity evidence")

	DriveAcceptanceGate.step(gate, 0.20, false, true, true, 0.10)
	assert(gate.continuousRotationSeconds == 0, "C06 drive gate must reset rotation window when leg contact is lost")

	DriveAcceptanceGate.step(gate, 0.30, true, true, true, 0.10)
	DriveAcceptanceGate.step(gate, 0.10, true, true, false, 0.10)
	assert(gate.continuousRotationSeconds == 0, "C06 drive gate must reset rotation window when relative rotation stops")

	DriveAcceptanceGate.step(gate, 0.30, true, true, true, 0.10)
	DriveAcceptanceGate.step(gate, 0.25, true, true, true, 0.10)
	assert(gate.continuousRotationSeconds >= 0.50, "C06 drive gate must accept one uninterrupted >=0.5s rotation window")
end

function C06CoreV3StressSpec.run()
	assertContinuousDriveGate()
	local runtimeFolder, createdRuntime = ensureFolder(Workspace, "Runtime")
	local racersFolder, createdRacers = ensureFolder(runtimeFolder, "Racers")
	local tracksFolder, createdTracks = ensureFolder(runtimeFolder, "Tracks")
	local templatesFolder, createdTemplates = ensureFolder(ServerStorage, "RacerTemplates")
	local templateExistedBefore = templatesFolder:FindFirstChild("RacerTemplate") ~= nil

	local track = Instance.new("Part")
	track.Name = "C06FlatTrack"
	track.Size = Vector3.new(180, 1, 36)
	track.CFrame = CFrame.new(0, 0, 0)
	track.Anchored = true
	track.CanCollide = true
	track.CanTouch = true
	track.CanQuery = true
	track.Parent = tracksFolder

	local blocker = nil :: Part?
	local racer = nil :: any
	local ok, failure = xpcall(function()
		racer = RacerRuntime.new({
			raceId = "C06_COREV3",
			slotIndex = 1,
			laneIndex = 1,
			isBot = false,
			trackId = "C06_FLAT",
			spawnCFrame = CFrame.new(0, 12, 0),
			laneCenterZ = 0,
		})

		local model = racer:GetModel()
		local body = racer:GetBody()
		assertNoLegacyApiKeys("RacerRuntime module", RacerRuntime)

		-- Seed one valid shape and freeze the structural identities that must
		-- survive every later redraw.
		startStableRedraw(racer, body, SHAPE_A)
		local core = racer:GetLegCore()
		assert(core ~= nil, "C06 seed shape must create Core V3 controller")
		waitForState(core, "ACTIVE", STATE_TIMEOUT)
		assertNoLegacyApiKeys("LegCoreController object", core)

		local axle = core:GetSharedAxle()
		local joint = axle:GetJoint()
		local countsByShape = {} :: { [string]: { descendants: number, baseParts: number } }
		countsByShape.A = assertActiveStructure(racer, core, axle, joint, nil)

		for redrawIndex = 1, REDRAW_COUNT do
			local oldLeft = core:GetLeftLeg()
			local oldRight = core:GetRightLeg()
			assert(oldLeft ~= nil and oldRight ~= nil, "C06 pre-redraw ACTIVE pair missing")
			local oldPhysicalParts = {}
			for _, leg in { oldLeft, oldRight } do
				for _, part in leg:GetPhysicalSegments() do
					table.insert(oldPhysicalParts, part)
				end
			end

			local useShapeB = redrawIndex % 2 == 1
			local shapeLabel = if useShapeB then "B" else "A"
			startStableRedraw(racer, body, if useShapeB then SHAPE_B else SHAPE_A)

			assert(core:GetState() == "ACTIVE", "C06 accepted redraw must already be mechanically ACTIVE")
			assert(racer:GetLegCore() == core, "C06 redraw replaced controller")
			assert(core:GetSharedAxle() == axle, "C06 redraw replaced axle")
			assert(axle:GetJoint() == joint, "C06 redraw replaced hinge")
			assert(joint.Enabled == true, "C06 redraw must keep physical hinge connected")
			for _, oldPart in oldPhysicalParts do
				assert(oldPart.Parent == nil, "C06 old physical geometry survived committed redraw")
			end

			local expectedCounts = countsByShape[shapeLabel]
			local currentCounts = assertActiveStructure(racer, core, axle, joint, expectedCounts)
			if expectedCounts == nil then
				countsByShape[shapeLabel] = currentCounts
			end
		end

		assert(racer:GetShapeVersion() == REDRAW_COUNT + 1, "C06 shape version must advance once per accepted stress redraw")

		-- Failure-path stress: add a query-only blocker around the complete pair.
		-- The body stays physically unanchored so the controller exercises its
		-- real +Y lift path, but the oversized blocker remains impossible to clear
		-- before the bounded timeout.
		local impossibleBlocker = Instance.new("Part")
		impossibleBlocker.Name = "C06ImpossibleClearanceBlocker"
		impossibleBlocker.Size = Vector3.new(40, 80, 40)
		impossibleBlocker.CFrame = CFrame.new(body.Position.X, body.Position.Y, body.Position.Z)
		impossibleBlocker.Anchored = true
		impossibleBlocker.CanCollide = false
		impossibleBlocker.CanTouch = false
		impossibleBlocker.CanQuery = true
		impossibleBlocker.Transparency = 1
		impossibleBlocker.Parent = tracksFolder
		blocker = impossibleBlocker

		body.Anchored = false
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		local versionBeforeFailure = racer:GetShapeVersion()
		local failedRedraw = LegShapeService.ValidateAndBuild(racer, SHAPE_B, false)
		assert(failedRedraw.accepted == false, "C06 impossible redraw must be rejected after mechanical failure")
		assert(failedRedraw.rejectReasonCode == "CLEARANCE_FAILED", "C06 failure reason must cross RacerRuntime/LegShapeService boundary")
		assert(core:GetState() == "EMPTY", "C06 rejected clearance redraw must already be fail-closed EMPTY")
		assert(racer:GetShapeVersion() == versionBeforeFailure, "C06 failed redraw must not advance ShapeVersion")
		assert(racer:GetCurrentShapeSpec() == nil, "C06 failed redraw must not leave stale current ShapeSpec")

		assert(racer:GetLegCore() == core, "C06 clearance failure replaced controller")
		assert(core:GetSharedAxle() == axle, "C06 clearance failure replaced axle")
		assert(axle:GetJoint() == joint, "C06 clearance failure replaced hinge")
		assert(joint.Enabled == true, "C06 failed clearance must keep physical hinge connected")
		assert(joint.ActuatorType == Enum.ActuatorType.None, "C06 failed clearance must leave motor actuator OFF")
		assert(core:GetLeftLeg() == nil and core:GetRightLeg() == nil, "C06 failed clearance must destroy the complete ghost pair")
		assert(countClass(model, "HingeConstraint") == 1, "C06 failure path created a second hinge")
		assert(countNamedModels(model, "SharedAxle") == 1, "C06 failure path created a second axle")
		assert(#collectLegOwners(model) == 0, "C06 failure path leaked leg owners")
		assert(#collectPreviewFolders(model) == 0, "C06 failure path leaked preview geometry")
		assert(model:FindFirstChild("CoreV3ClearanceLift", true) == nil, "C06 failure path leaked clearance force")
		assert(model:FindFirstChild("CoreV3ClearanceLiftAttachment", true) == nil, "C06 failure path leaked clearance attachment")
		assertNoLegacyGeometryNames(model)
		assertNoHorizontalForce(model)
	end, debug.traceback)

	if racer ~= nil then
		racer:Destroy()
	end
	if blocker ~= nil then
		blocker:Destroy()
	end
	track:Destroy()

	local template = templatesFolder:FindFirstChild("RacerTemplate")
	if not templateExistedBefore and template ~= nil then
		template:Destroy()
	end
	if createdTemplates and #templatesFolder:GetChildren() == 0 then
		templatesFolder:Destroy()
	end
	if createdTracks and #tracksFolder:GetChildren() == 0 then
		tracksFolder:Destroy()
	end
	if createdRacers and #racersFolder:GetChildren() == 0 then
		racersFolder:Destroy()
	end
	if createdRuntime and #runtimeFolder:GetChildren() == 0 then
		runtimeFolder:Destroy()
	end

	assert(ok, failure)
	print("[DrawRacers][C06] Core V3 20-redraw structural stress PASS")
end

return C06CoreV3StressSpec
