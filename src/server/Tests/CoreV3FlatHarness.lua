--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Net"):WaitForChild("RemoteNames"))
local M0SceneConfig = require(shared:WaitForChild("Config"):WaitForChild("M0SceneConfig"))
local CollisionGroups = require(script.Parent.Parent.Runtime:WaitForChild("CollisionGroups"))
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegClearanceController = require(
	script.Parent.Parent.Runtime:WaitForChild("CoreV3"):WaitForChild("LegClearanceController")
)
local StrokeRemoteTransport = require(script.Parent.Parent.Services:WaitForChild("StrokeRemoteTransport"))
local DriveAcceptanceGate = require(script.Parent:WaitForChild("CoreV3DriveAcceptanceGate"))

local CoreV3FlatHarness = {}

-- Keep the Core V3 flat gate in the canonical M0 test-lab coordinate system.
-- Obstacles stay absent, but camera scale/spawn/lane dimensions remain familiar.
local TRACK_START_X = 0
local TRACK_END_X = M0SceneConfig.Lane.Length
local TRACK_TOP_Y = M0SceneConfig.Lane.TopY
local TRACK_THICKNESS = M0SceneConfig.Lane.Thickness
local TRACK_WIDTH = M0SceneConfig.Lane.Width
local RACER_SPAWN = Vector3.new(
	M0SceneConfig.Spawn.X,
	M0SceneConfig.ReferenceBenchmark.SpawnY,
	M0SceneConfig.Spawn.Z
)
local DEBUG_SAMPLE_INTERVAL = 0.05
local LOCOMOTION_DIAGNOSTIC_INTERVAL = 0.10
local TRACK_PROXIMITY_PADDING = 0.08
local FORCE_EPSILON = 1e-6
local REFERENCE_SHAPES = "ROUND,SMALL_ROUND,LONG,HOOK,ASYMMETRIC"

local started = false
local activePlayer: Player? = nil
local activeRacer: any = nil
local flatScene: Folder? = nil
local transportConnection: RBXScriptConnection? = nil
local playerAddedConnection: RBXScriptConnection? = nil
local playerRemovingConnection: RBXScriptConnection? = nil
local activeCharacterConnection: RBXScriptConnection? = nil
local activeAppearanceConnection: RBXScriptConnection? = nil
local debugConnection: RBXScriptConnection? = nil
local debugElapsed = 0
local locomotionDiagnosticElapsed = 0
local lastDiagnosticAngle: number? = nil
local lastDiagnosticBodyX: number? = nil
local lastDiagnosticShapeVersion = -1
local stallUnderContactSeconds = 0
local stallWarnedShapeVersion = -1
local driveAcceptanceShapeVersion = -1
local driveAcceptanceStartX: number? = nil
local driveAcceptanceStartedAt: number? = nil
local driveAcceptanceResolved = false
local driveAcceptancePassed = false
local driveAcceptanceInconclusive = false
local driveAcceptanceGateState = DriveAcceptanceGate.new()
local lastState = ""
local lastShapeVersion = -1
local lastForwardAssistActive = false

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing:IsA("Folder"), name .. " must be Folder")
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensureRemote(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing:IsA("RemoteEvent"), name .. " must be RemoteEvent")
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function ensureDrawHud(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("DrawHUD")
	if existing ~= nil then
		assert(existing:IsA("ScreenGui"), "DrawHUD must be ScreenGui")
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "DrawHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui
end

local function makeRealCharacterNonPhysical(character: Model)
	-- The real Roblox character is only the source for the rider presentation.
	-- It must never participate in racer physics. Do not change Transparency here:
	-- the client presentation may still need the authored avatar appearance.
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CollisionGroup = CollisionGroups.Decoration
		end
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		root.Anchored = true
	end
end

local function parkRealCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local observerPosition = RACER_SPAWN + Vector3.new(-12, 15, 40)
	character:PivotTo(CFrame.lookAt(observerPosition, RACER_SPAWN))
end

local function disconnectAppearanceWatcher()
	if activeAppearanceConnection ~= nil then
		activeAppearanceConnection:Disconnect()
		activeAppearanceConnection = nil
	end
end

local function isolateRealCharacter(player: Player, character: Model)
	disconnectAppearanceWatcher()
	makeRealCharacterNonPhysical(character)

	-- Do not move the source avatar away before Roblox finishes loading its
	-- appearance. RiderPresentationController clones that appearance for the
	-- visible jockey on top of the cube.
	if player:HasAppearanceLoaded() then
		parkRealCharacter(character)
		return
	end

	activeAppearanceConnection = player.CharacterAppearanceLoaded:Connect(function(loadedCharacter)
		if loadedCharacter ~= character then
			return
		end
		disconnectAppearanceWatcher()
		makeRealCharacterNonPhysical(character)
		parkRealCharacter(character)
	end)
end

local function bindCharacterIsolation(player: Player)
	if activeCharacterConnection ~= nil then
		activeCharacterConnection:Disconnect()
		activeCharacterConnection = nil
	end
	disconnectAppearanceWatcher()

	if player.Character ~= nil then
		isolateRealCharacter(player, player.Character)
	end
	activeCharacterConnection = player.CharacterAdded:Connect(function(character)
		isolateRealCharacter(player, character)
	end)
end

local function ensureInfrastructure(): (Folder, RemoteEvent, RemoteEvent)
	CollisionGroups.ensure()

	local runtime = ensureFolder(Workspace, "Runtime")
	local racers = ensureFolder(runtime, "Racers")
	local tracks = ensureFolder(runtime, "Tracks")
	local presentation = ensureFolder(runtime, "RacePresentation")

	-- COREV3 is an isolated validation mode. Runtime leftovers must not become
	-- invisible obstacles or a second racer architecture during the flat gate.
	for _, child in tracks:GetChildren() do
		child:Destroy()
	end
	for _, child in racers:GetChildren() do
		child:Destroy()
	end
	for _, child in presentation:GetChildren() do
		child:Destroy()
	end

	local templates = ensureFolder(ServerStorage, "RacerTemplates")
	local oldTemplate = templates:FindFirstChild("RacerTemplate")
	if oldTemplate ~= nil then
		oldTemplate:Destroy()
	end

	local remotes = ensureFolder(ReplicatedStorage, "Remotes")
	local submitStroke = ensureRemote(remotes, RemoteNames.SubmitStroke)
	local strokeResult = ensureRemote(remotes, RemoteNames.StrokeResult)
	return tracks, submitStroke, strokeResult
end

local function buildFlatTrack(tracksRoot: Folder): Folder
	local scene = Instance.new("Folder")
	scene.Name = "CoreV3FlatHarness"
	scene.Parent = tracksRoot

	local track = Instance.new("Part")
	track.Name = "FlatCoreV3Track"
	track.Anchored = true
	track.CanCollide = true
	track.CanTouch = true
	track.CanQuery = true
	track.Size = Vector3.new(TRACK_END_X - TRACK_START_X, TRACK_THICKNESS, TRACK_WIDTH)
	track.Position = Vector3.new(
		(TRACK_START_X + TRACK_END_X) * 0.5,
		TRACK_TOP_Y - TRACK_THICKNESS * 0.5,
		0
	)
	track.Material = Enum.Material.SmoothPlastic
	track.Color = Color3.fromRGB(112, 118, 128)
	track.CollisionGroup = CollisionGroups.Track
	track.Parent = scene

	flatScene = scene
	return scene
end

local function addCubeVisual(racerModel: Model, body: Part)
	local visualRoot = racerModel:FindFirstChild("VisualRoot")
	assert(visualRoot ~= nil, "Core V3 racer missing VisualRoot")

	local visual = Instance.new("Part")
	visual.Name = "CoreV3CubeVisual"
	visual.Size = body.Size - Vector3.new(0.12, 0.12, 0.12)
	visual.CFrame = body.CFrame
	visual.Anchored = false
	visual.CanCollide = false
	visual.CanTouch = false
	visual.CanQuery = false
	visual.Massless = true
	visual.Material = Enum.Material.SmoothPlastic
	visual.Color = Color3.fromRGB(80, 180, 245)
	visual.CastShadow = true
	visual.Parent = visualRoot

	local weld = Instance.new("WeldConstraint")
	weld.Name = "CoreV3CubeVisualWeld"
	weld.Part0 = body
	weld.Part1 = visual
	weld.Parent = visual
end

local function countHinges(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end

local function legPhysicsEnabled(leg: any?, shapeSpec: any?): boolean
	if leg == nil or shapeSpec == nil or type(shapeSpec.segmentPlan) ~= "table" then
		return false
	end
	local parts = leg:GetPhysicalSegments()
	if #parts == 0 then
		return false
	end

	local hasAuthoritativeCollider = false
	for index, part in parts do
		local planEntry = shapeSpec.segmentPlan[index]
		local shouldCollide = planEntry ~= nil and planEntry.canCollide == true
		if shouldCollide then
			hasAuthoritativeCollider = true
		end
		if part.CanCollide ~= shouldCollide or part.CanTouch ~= shouldCollide then
			return false
		end
	end
	return hasAuthoritativeCollider
end

local function hasHorizontalAssist(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("VectorForce") then
			if math.abs(descendant.Force.X) > FORCE_EPSILON then
				return true
			end
		elseif descendant:IsA("LinearVelocity") then
			if math.abs(descendant.VectorVelocity.X) > FORCE_EPSILON then
				return true
			end
		elseif descendant:IsA("BodyVelocity") then
			if math.abs(descendant.Velocity.X) > FORCE_EPSILON then
				return true
			end
		end
	end
	return false
end

local function activeColliderCount(core: any?): number
	if core == nil then
		return 0
	end
	local count = 0
	for _, leg in { core:GetLeftLeg(), core:GetRightLeg() } do
		if leg ~= nil then
			for _, part in leg:GetPhysicalSegments() do
				if part.CanCollide then
					count += 1
				end
			end
		end
	end
	return count
end

local function axleAttachmentError(core: any?): number
	if core == nil then
		return 0
	end
	local joint = core:GetSharedAxle():GetJoint()
	local a0 = joint.Attachment0
	local a1 = joint.Attachment1
	if a0 == nil or a1 == nil then
		return math.huge
	end
	return (a0.WorldPosition - a1.WorldPosition).Magnitude
end

local function orientedBottomY(part: BasePart): number
	local half = part.Size * 0.5
	local yExtent = math.abs(part.CFrame.RightVector.Y) * half.X
		+ math.abs(part.CFrame.UpVector.Y) * half.Y
		+ math.abs(part.CFrame.LookVector.Y) * half.Z
	return part.Position.Y - yExtent
end

local function touchesTrack(part: BasePart, tracksRoot: Instance): boolean
	if not part.CanTouch then
		return false
	end
	local ok, touching = pcall(function()
		return part:GetTouchingParts()
	end)
	if not ok then
		return false
	end
	for _, other in touching do
		if other:IsDescendantOf(tracksRoot) then
			return true
		end
	end
	return false
end

local function nearTrack(part: BasePart, tracksRoot: Instance): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { tracksRoot }
	params.MaxParts = 8

	local padding = Vector3.new(
		TRACK_PROXIMITY_PADDING,
		TRACK_PROXIMITY_PADDING,
		TRACK_PROXIMITY_PADDING
	)
	local hits = Workspace:GetPartBoundsInBox(part.CFrame, part.Size + padding, params)
	return #hits > 0
end

local function collectTrackContactEvidence(core: any?, tracksRoot: Instance): (number, number, number, number)
	if core == nil then
		return 0, 0, 0, 0
	end

	local activeCount = 0
	local touchingCount = 0
	local nearCount = 0
	local lowestY = math.huge
	for _, leg in { core:GetLeftLeg(), core:GetRightLeg() } do
		if leg ~= nil then
			for _, part in leg:GetPhysicalSegments() do
				if part.CanCollide then
					activeCount += 1
					lowestY = math.min(lowestY, orientedBottomY(part))
					if touchesTrack(part, tracksRoot) then
						touchingCount += 1
					end
					if nearTrack(part, tracksRoot) then
						nearCount += 1
					end
				end
			end
		end
	end

	if lowestY == math.huge then
		lowestY = 0
	end
	return activeCount, touchingCount, nearCount, lowestY
end

local function wrappedAngleDeltaDegrees(current: number, previous: number): number
	return (current - previous + 180) % 360 - 180
end

local function clearanceRequiredLift(racer: any, core: any, tracksRoot: Folder): number
	if core == nil or core:GetState() ~= "WAIT_CLEAR" then
		return 0
	end
	local left = core:GetLeftLeg()
	local right = core:GetRightLeg()
	if left == nil or right == nil then
		return 0
	end
	local ok, result = pcall(function()
		return LegClearanceController.Evaluate(racer:GetBody(), left, right, tracksRoot)
	end)
	if not ok or type(result) ~= "table" or type(result.requiredLift) ~= "number" then
		return -1
	end
	return result.requiredLift
end

local function publishLocomotionEvidence(racer: any, tracksRoot: Folder, sampleDt: number)
	local model = racer:GetModel()
	local core = racer:GetLegCore()
	if core == nil or core:GetState() ~= "ACTIVE" then
		lastDiagnosticAngle = nil
		lastDiagnosticBodyX = nil
		lastDiagnosticShapeVersion = racer:GetShapeVersion()
		stallUnderContactSeconds = 0
		if driveAcceptanceShapeVersion ~= racer:GetShapeVersion() then
			driveAcceptanceShapeVersion = racer:GetShapeVersion()
			driveAcceptanceStartX = nil
			driveAcceptanceStartedAt = nil
			driveAcceptanceResolved = false
			driveAcceptancePassed = false
			driveAcceptanceInconclusive = false
			DriveAcceptanceGate.reset(driveAcceptanceGateState)
		end
		return
	end

	local body = racer:GetBody()
	local axle = core:GetSharedAxle()
	local joint = axle:GetJoint()
	local axleRoot = axle:GetAxleRoot()
	local currentAngle = joint.CurrentAngle
	local shapeVersion = racer:GetShapeVersion()
	local angleRateDeg = 0
	local deltaX = 0

	if lastDiagnosticShapeVersion == shapeVersion and lastDiagnosticAngle ~= nil and sampleDt > 1e-4 then
		angleRateDeg = wrappedAngleDeltaDegrees(currentAngle, lastDiagnosticAngle) / sampleDt
	end
	if lastDiagnosticShapeVersion == shapeVersion and lastDiagnosticBodyX ~= nil then
		deltaX = body.Position.X - lastDiagnosticBodyX
	end

	lastDiagnosticAngle = currentAngle
	lastDiagnosticBodyX = body.Position.X
	lastDiagnosticShapeVersion = shapeVersion

	local hingeAxis = Vector3.zAxis
	if joint.Attachment1 ~= nil then
		hingeAxis = joint.Attachment1.WorldAxis
	elseif joint.Attachment0 ~= nil then
		hingeAxis = joint.Attachment0.WorldAxis
	end
	local axleOmega = axleRoot.AssemblyAngularVelocity:Dot(hingeAxis)
	local bodyOmega = body.AssemblyAngularVelocity:Dot(hingeAxis)
	local relativeOmega = axleOmega - bodyOmega
	local targetOmega = if joint.ActuatorType == Enum.ActuatorType.Motor then joint.AngularVelocity else 0
	local activeCount, touchingCount, nearCount, lowestLegY = collectTrackContactEvidence(core, tracksRoot)
	local bodyTouchingTrack = touchesTrack(body, tracksRoot)
	local bodyNearTrack = nearTrack(body, tracksRoot)
	local bodyBottomY = orientedBottomY(body)
	local bodyVelocityX = body.AssemblyLinearVelocity.X
	local bodyMass = body.AssemblyMass
	local axleMass = axleRoot.AssemblyMass
	local driveStalled = math.abs(targetOmega) >= 1.0
		and touchingCount > 0
		and math.abs(angleRateDeg) < 5
		and math.abs(bodyVelocityX) < 0.05
	if driveStalled then
		stallUnderContactSeconds += sampleDt
	else
		stallUnderContactSeconds = 0
	end
	if stallUnderContactSeconds >= 0.50 and stallWarnedShapeVersion ~= shapeVersion then
		stallWarnedShapeVersion = shapeVersion
		warn("[DrawRacers][COREV3][DRIVE_STALL] motor commanded + leg contact + no relative rotation + no forward motion")
	end

	if driveAcceptanceShapeVersion ~= shapeVersion then
		driveAcceptanceShapeVersion = shapeVersion
		driveAcceptanceStartX = nil
		driveAcceptanceStartedAt = nil
		driveAcceptanceResolved = false
		driveAcceptancePassed = false
		driveAcceptanceInconclusive = false
		DriveAcceptanceGate.begin(driveAcceptanceGateState, bodyVelocityX)
		if not driveAcceptanceGateState.eligibleFromRest then
			driveAcceptanceResolved = true
			driveAcceptanceInconclusive = true
			warn(string.format(
				"[DrawRacers][COREV3][DRIVE_ACCEPTANCE] MOVING_BASELINE v=%d baselineVX=%.3f — locomotion acceptance inconclusive",
				shapeVersion,
				bodyVelocityX
			))
		end
	end

	local acceptanceForwardAssist = hasHorizontalAssist(model)
	local acceptanceHingeCount = countHinges(model)
	local acceptanceAttachmentError = axleAttachmentError(core)
	local acceptanceRelativeRotation = math.abs(relativeOmega) >= 0.50 or math.abs(angleRateDeg) >= 5
	DriveAcceptanceGate.step(
		driveAcceptanceGateState,
		sampleDt,
		touchingCount > 0,
		math.abs(targetOmega) >= 1.0,
		acceptanceRelativeRotation,
		bodyVelocityX
	)
	local driveAcceptanceRotationSeconds = driveAcceptanceGateState.continuousRotationSeconds
	local driveAcceptanceSawPositiveVX = driveAcceptanceGateState.sawPositiveVX

	if not driveAcceptanceResolved and touchingCount > 0 then
		if driveAcceptanceStartX == nil then
			driveAcceptanceStartX = body.Position.X
			driveAcceptanceStartedAt = os.clock()
		elseif driveAcceptanceStartedAt ~= nil then
			local elapsed = os.clock() - (driveAcceptanceStartedAt :: number)
			local forwardDelta = body.Position.X - (driveAcceptanceStartX :: number)
			local hingeConnected = joint.Enabled
			local acceptanceReady = forwardDelta > 0.50
				and driveAcceptanceSawPositiveVX
				and bodyVelocityX > 0.02
				and driveAcceptanceRotationSeconds >= 0.50
				and acceptanceHingeCount == 1
				and hingeConnected
				and acceptanceAttachmentError <= 0.15
				and not acceptanceForwardAssist

			if acceptanceReady then
				driveAcceptanceResolved = true
				driveAcceptancePassed = true
				print(string.format(
					"[DrawRacers][COREV3][DRIVE_ACCEPTANCE] PASS v=%d dx=%.3f t=%.2f rotation=%.2fs hinges=%d separation=%.3f",
					shapeVersion,
					forwardDelta,
					elapsed,
					driveAcceptanceRotationSeconds,
					acceptanceHingeCount,
					acceptanceAttachmentError
				))
			elseif elapsed >= 2.0 then
				driveAcceptanceResolved = true
				driveAcceptancePassed = false
				warn(string.format(
					"[DrawRacers][COREV3][DRIVE_ACCEPTANCE] FAIL v=%d dx=%.3f bodyVX=%.3f rotation=%.2fs hinges=%d hingeConnected=%s separation=%.3f assist=%s",
					shapeVersion,
					forwardDelta,
					bodyVelocityX,
					driveAcceptanceRotationSeconds,
					acceptanceHingeCount,
					tostring(hingeConnected),
					acceptanceAttachmentError,
					tostring(acceptanceForwardAssist)
				))
			end
		end
	end

	model:SetAttribute("CoreV3MotorTargetOmega", targetOmega)
	model:SetAttribute("CoreV3AxleOmega", axleOmega)
	model:SetAttribute("CoreV3BodyOmega", bodyOmega)
	model:SetAttribute("CoreV3RelativeOmega", relativeOmega)
	model:SetAttribute("CoreV3JointAngle", currentAngle)
	model:SetAttribute("CoreV3JointAngleRateDeg", angleRateDeg)
	model:SetAttribute("CoreV3LegTrackTouchCount", touchingCount)
	model:SetAttribute("CoreV3LegTrackNearCount", nearCount)
	model:SetAttribute("CoreV3BodyTrackTouching", bodyTouchingTrack)
	model:SetAttribute("CoreV3BodyTrackNear", bodyNearTrack)
	model:SetAttribute("CoreV3LowestLegY", lowestLegY)
	model:SetAttribute("CoreV3BodyBottomY", bodyBottomY)
	model:SetAttribute("CoreV3TrackTopY", TRACK_TOP_Y)
	model:SetAttribute("CoreV3BodyAssemblyMass", bodyMass)
	model:SetAttribute("CoreV3AxleAssemblyMass", axleMass)
	model:SetAttribute("CoreV3DiagnosticDeltaX", deltaX)
	model:SetAttribute("CoreV3DriveStallSeconds", stallUnderContactSeconds)
	model:SetAttribute("CoreV3DriveAcceptanceResolved", driveAcceptanceResolved)
	model:SetAttribute("CoreV3DriveAcceptancePassed", driveAcceptancePassed)
	model:SetAttribute("CoreV3DriveAcceptanceInconclusive", driveAcceptanceInconclusive)
	model:SetAttribute("CoreV3DriveAcceptanceEligibleFromRest", driveAcceptanceGateState.eligibleFromRest)
	model:SetAttribute("CoreV3DriveAcceptanceBaselineVX", driveAcceptanceGateState.baselineVelocityX)
	model:SetAttribute("CoreV3DriveAcceptanceRotationSeconds", driveAcceptanceRotationSeconds)
	model:SetAttribute("CoreV3DriveAcceptanceSawPositiveVX", driveAcceptanceSawPositiveVX)

	print(string.format(
		"[DrawRacers][COREV3][LOCOMOTION] v=%d targetOmega=%.3f axleOmega=%.3f bodyOmega=%.3f relativeOmega=%.3f angle=%.2f angleRate=%.1fdeg/s stall=%.2fs colliders=%d legTouch=%d legNear=%d bodyTouch=%s bodyNear=%s bodyVX=%.3f dX=%.3f bodyBottomY=%.3f legBottomY=%.3f trackTopY=%.3f bodyMass=%.3f axleMass=%.3f massRatio=%.2f",
		shapeVersion,
		targetOmega,
		axleOmega,
		bodyOmega,
		relativeOmega,
		currentAngle,
		angleRateDeg,
		stallUnderContactSeconds,
		activeCount,
		touchingCount,
		nearCount,
		tostring(bodyTouchingTrack),
		tostring(bodyNearTrack),
		bodyVelocityX,
		deltaX,
		bodyBottomY,
		lowestLegY,
		TRACK_TOP_Y,
		bodyMass,
		axleMass,
		bodyMass / math.max(axleMass, 1e-6)
	))
end

local function publishEvidence(racer: any, tracksRoot: Folder)
	local model = racer:GetModel()
	local core = racer:GetLegCore()
	local state = if core ~= nil then core:GetState() else "EMPTY"
	local motorEnabled = false
	local leftEnabled = false
	local rightEnabled = false
	local shapeSpec = racer:GetCurrentShapeSpec()

	if core ~= nil then
		local axle = core:GetSharedAxle()
		motorEnabled = axle:GetJoint().Enabled and axle:GetJoint().ActuatorType == Enum.ActuatorType.Motor
		leftEnabled = legPhysicsEnabled(core:GetLeftLeg(), shapeSpec)
		rightEnabled = legPhysicsEnabled(core:GetRightLeg(), shapeSpec)
	end

	local forwardAssistActive = hasHorizontalAssist(model)
	model:SetAttribute("CoreV3State", state)
	model:SetAttribute("CoreV3HingeCount", countHinges(model))
	model:SetAttribute("CoreV3MotorEnabled", motorEnabled)
	model:SetAttribute("CoreV3HingeConnected", if core ~= nil then core:GetSharedAxle():GetJoint().Enabled else false)
	model:SetAttribute("CoreV3AxleAttachmentError", axleAttachmentError(core))
	model:SetAttribute("CoreV3ActiveColliderCount", activeColliderCount(core))
	model:SetAttribute("CoreV3LeftPhysicsEnabled", leftEnabled)
	model:SetAttribute("CoreV3RightPhysicsEnabled", rightEnabled)
	model:SetAttribute("CoreV3ClearanceRequiredLift", clearanceRequiredLift(racer, core, tracksRoot))
	model:SetAttribute("CoreV3RedrawCount", racer:GetShapeVersion())
	model:SetAttribute("CoreV3ForwardAssistActive", forwardAssistActive)
	model:SetAttribute("CoreV3PairAtomic", leftEnabled == rightEnabled)
	model:SetAttribute("CoreV3ReferenceShapes", REFERENCE_SHAPES)
	model:SetAttribute("CoreV3BodyX", racer:GetBody().Position.X)
	model:SetAttribute("CoreV3VelocityX", racer:GetBody().AssemblyLinearVelocity.X)

	if state ~= lastState then
		lastState = state
		print(string.format("[DrawRacers][COREV3] state=%s", state))
	end
	local shapeVersion = racer:GetShapeVersion()
	if shapeVersion ~= lastShapeVersion then
		lastShapeVersion = shapeVersion
		print(string.format("[DrawRacers][COREV3] accepted redraw count=%d", shapeVersion))
	end
	if forwardAssistActive and not lastForwardAssistActive then
		warn("[DrawRacers][COREV3] INVALID: horizontal movement assist detected")
	end
	if core ~= nil then
		local joint = core:GetSharedAxle():GetJoint()
		local attachmentError = axleAttachmentError(core)
		if not joint.Enabled then
			warn("[DrawRacers][COREV3] INVALID: physical hinge disconnected")
		elseif attachmentError > 0.15 then
			warn(string.format("[DrawRacers][COREV3] INVALID: axle/body separation %.3f", attachmentError))
		end
		if state == "ACTIVE" and activeColliderCount(core) == 0 then
			warn("[DrawRacers][COREV3] INVALID: ACTIVE pair has zero colliders")
		end
	end
	lastForwardAssistActive = forwardAssistActive
end

local function createActiveRacer(player: Player)
	local racer = RacerRuntime.new({
		raceId = "COREV3_FLAT",
		slotIndex = 1,
		laneIndex = 1,
		isBot = false,
		trackId = "COREV3_FLAT_TRACK",
		spawnCFrame = CFrame.new(RACER_SPAWN),
		laneCenterZ = RACER_SPAWN.Z,
	})
	local model = racer:GetModel()
	local body = racer:GetBody()
	model:SetAttribute("DebugTarget", true)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("CameraMinFollowY", M0SceneConfig.CameraMinFollowY)
	model:SetAttribute("CoreV3Harness", true)
	model:SetAttribute("CoreV3ForwardAssistActive", false)
	model:SetAttribute("CoreV3ReferenceShapes", REFERENCE_SHAPES)
	addCubeVisual(model, body)
	activeRacer = racer
	return racer
end

local function destroyActiveRacer()
	if activeCharacterConnection ~= nil then
		activeCharacterConnection:Disconnect()
		activeCharacterConnection = nil
	end
	disconnectAppearanceWatcher()
	if activeRacer ~= nil then
		activeRacer:Destroy()
		activeRacer = nil
	end
	activePlayer = nil
	lastState = ""
	lastShapeVersion = -1
	lastForwardAssistActive = false
	driveAcceptanceShapeVersion = -1
	driveAcceptanceStartX = nil
	driveAcceptanceStartedAt = nil
	driveAcceptanceResolved = false
	driveAcceptancePassed = false
	driveAcceptanceInconclusive = false
	DriveAcceptanceGate.reset(driveAcceptanceGateState)
end

local function attachPlayer(player: Player)
	if activePlayer ~= nil then
		return
	end
	activePlayer = player
	ensureDrawHud(player)
	bindCharacterIsolation(player)
	createActiveRacer(player)
	print(string.format(
		"[DrawRacers][COREV3] player=%s flat racer ready; draw %s",
		player.Name,
		REFERENCE_SHAPES
	))
end

local function attachNextAvailablePlayer()
	if activePlayer ~= nil then
		return
	end
	local players = Players:GetPlayers()
	if #players > 0 then
		attachPlayer(players[1])
	end
end

function CoreV3FlatHarness.start()
	assert(RunService:IsStudio(), "CoreV3FlatHarness is Studio-only")
	if started then
		return
	end
	started = true

	local tracksRoot, submitStroke, strokeResult = ensureInfrastructure()
	buildFlatTrack(tracksRoot)

	transportConnection = StrokeRemoteTransport.Bind({
		submitStroke = submitStroke,
		strokeResult = strokeResult,
		resolveRacer = function(player)
			if player == activePlayer then
				return activeRacer
			end
			return nil
		end,
	})

	playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		attachPlayer(player)
	end)
	playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		if player == activePlayer then
			destroyActiveRacer()
			task.defer(attachNextAvailablePlayer)
		end
	end)

	debugConnection = RunService.Heartbeat:Connect(function(dt)
		debugElapsed += dt
		locomotionDiagnosticElapsed += dt
		if activeRacer ~= nil and locomotionDiagnosticElapsed >= LOCOMOTION_DIAGNOSTIC_INTERVAL then
			local sampleDt = locomotionDiagnosticElapsed
			locomotionDiagnosticElapsed = 0
			publishLocomotionEvidence(activeRacer, tracksRoot, sampleDt)
		end
		if debugElapsed < DEBUG_SAMPLE_INTERVAL then
			return
		end
		debugElapsed = 0
		if activeRacer ~= nil then
			publishEvidence(activeRacer, tracksRoot)
		end
	end)

	attachNextAvailablePlayer()
	print("[DrawRacers][COREV3] flat harness ready — canonical M0 flat lane, no walls/steps/gaps/tunnels")
	print("[DrawRacers][COREV3] HUMAN PHYSICS PENDING — test ROUND, SMALL_ROUND, LONG, HOOK, ASYMMETRIC and 20 redraws")
end

function CoreV3FlatHarness.stop()
	if debugConnection ~= nil then
		debugConnection:Disconnect()
		debugConnection = nil
	end
	if transportConnection ~= nil then
		transportConnection:Disconnect()
		transportConnection = nil
	end
	if playerAddedConnection ~= nil then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
	if playerRemovingConnection ~= nil then
		playerRemovingConnection:Disconnect()
		playerRemovingConnection = nil
	end

	destroyActiveRacer()
	if flatScene ~= nil then
		flatScene:Destroy()
		flatScene = nil
	end
	debugElapsed = 0
	locomotionDiagnosticElapsed = 0
	lastDiagnosticAngle = nil
	lastDiagnosticBodyX = nil
	lastDiagnosticShapeVersion = -1
	started = false
end

return CoreV3FlatHarness
