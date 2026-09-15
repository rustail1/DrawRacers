--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local C04CoreV3ControllerSpec = {}

local function requireCoreV3Modules()
	local runtimeFolder = script.Parent.Parent:FindFirstChild("Runtime")
	assert(runtimeFolder ~= nil, "Runtime folder missing")

	local coreFolder = runtimeFolder:FindFirstChild("CoreV3")
	assert(coreFolder ~= nil, "CoreV3 runtime folder missing")

	local controllerModule = coreFolder:FindFirstChild("LegCoreController")
	assert(controllerModule ~= nil and controllerModule:IsA("ModuleScript"), "CoreV3 LegCoreController module missing")

	local clearanceModule = coreFolder:FindFirstChild("LegClearanceController")
	assert(clearanceModule ~= nil and clearanceModule:IsA("ModuleScript"), "CoreV3 LegClearanceController module missing")

	local configModule = coreFolder:FindFirstChild("LegCoreConfig")
	assert(configModule ~= nil and configModule:IsA("ModuleScript"), "CoreV3 LegCoreConfig module missing")

	return require(controllerModule), require(clearanceModule), controllerModule, require(configModule)
end

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

local function makeShape(version: number, y: number, extent: number): any
	local a = Vector2.new(-1.2, y)
	local b = Vector2.new(0, y + 0.35)
	local c = Vector2.new(1.2, y)
	return {
		version = version,
		normalizedPoints = { a, b, c },
		mappedPoints = { a, b, c },
		bounds = {
			min = Vector2.new(-1.2, y),
			max = Vector2.new(1.2, y + 0.35),
		},
		extent = extent,
		segmentPlan = {
			{ index = 1, a = a, b = b, canCollide = true },
			{ index = 2, a = b, b = c, canCollide = false },
		},
		debugRawPointCount = 3,
		debugPhysicsPointCount = 3,
		debugId = string.format("C04-shape-%d", version),
	}
end

local function assertPairPhysicsOff(core: any)
	for _, leg in { core:GetLeftLeg(), core:GetRightLeg() } do
		if leg ~= nil then
			for _, part in leg:GetPhysicalSegments() do
				assert(part.CanCollide == false, "C04 pair collider enabled before ACTIVE")
				assert(part.CanTouch == false, "C04 pair touch enabled before ACTIVE")
			end
		end
	end
end

local function assertPairPhysicsOn(core: any)
	for _, leg in { core:GetLeftLeg(), core:GetRightLeg() } do
		assert(leg ~= nil, "C04 ACTIVE requires both leg owners")
		local segments = leg:GetPhysicalSegments()
		assert(#segments == 2, "C04 synthetic shape must build two segments per side")
		assert(segments[1].CanCollide == true, "C04 authoritative collider must be ON in ACTIVE")
		assert(segments[1].CanTouch == true, "C04 authoritative touch must be ON in ACTIVE")
		assert(segments[2].CanCollide == false, "C04 canCollide=false segment must remain OFF")
		assert(segments[2].CanTouch == false, "C04 non-authoritative touch must remain OFF")
	end
end


local function assertMotorState(core: any, enabled: boolean, label: string)
	local joint = core:GetSharedAxle():GetJoint()
	assert(joint.Enabled == true, label .. " must keep physical hinge enabled")
	local expected = if enabled then Enum.ActuatorType.Motor else Enum.ActuatorType.None
	assert(joint.ActuatorType == expected, label .. " actuator state mismatch")
end

local function assertAxleConnected(core: any, label: string)
	local axle = core:GetSharedAxle()
	local joint = axle:GetJoint()
	assert(joint.Enabled == true, label .. " hinge must remain physically connected")
	local a0 = joint.Attachment0
	local a1 = joint.Attachment1
	assert(a0 ~= nil and a1 ~= nil, label .. " hinge attachments missing")
	local errorDistance = ((a0 :: Attachment).WorldPosition - (a1 :: Attachment).WorldPosition).Magnitude
	assert(errorDistance < 0.20, string.format("%s axle/body separation %.3f", label, errorDistance))
end

local function waitForState(core: any, target: string, timeout: number)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if core:GetState() == target then
			return
		end
		RunService.Heartbeat:Wait()
	end
	error(string.format("C04 timed out waiting for state %s; current=%s", target, core:GetState()))
end

local function waitForActiveAndObserve(
	core: any,
	body: Part,
	requireLiftEvidence: boolean,
	minimumInitialLift: number?
): number?
	local sawPreview = core:GetState() == "PREVIEW"
	local sawWaitClear = false
	local waitClearYs = {}
	local initialRequiredLift = nil :: number?
	local deadline = os.clock() + 3.0

	while os.clock() < deadline do
		local state = core:GetState()
		if state == "PREVIEW" then
			sawPreview = true
			assertMotorState(core, false, "C04 PREVIEW motor")
			assertAxleConnected(core, "C04 PREVIEW")
			assertPairPhysicsOff(core)
		elseif state == "WAIT_CLEAR" then
			sawWaitClear = true
			assertMotorState(core, false, "C04 WAIT_CLEAR motor")
			assertAxleConnected(core, "C04 WAIT_CLEAR")
			assertPairPhysicsOff(core)
			table.insert(waitClearYs, body.Position.Y)

			if initialRequiredLift == nil then
				local runtime = Workspace:FindFirstChild("Runtime")
				local tracks = if runtime ~= nil then runtime:FindFirstChild("Tracks") else nil
				assert(tracks ~= nil, "C04 Tracks root missing during clearance observation")
				local _, Clearance = requireCoreV3Modules()
				local result = Clearance.Evaluate(body, core:GetLeftLeg(), core:GetRightLeg(), tracks)
				initialRequiredLift = result.requiredLift
			end

			local liftForce = body:FindFirstChild("CoreV3ClearanceLift")
			if liftForce ~= nil and liftForce:IsA("VectorForce") then
				assert(math.abs(liftForce.Force.X) < 1e-6, "C04 clearance lift must not apply X force")
				assert(math.abs(liftForce.Force.Z) < 1e-6, "C04 clearance lift must not apply Z force")
			end
		elseif state == "ACTIVE" then
			break
		elseif state == "EMPTY" then
			error("C04 rebuild failed closed before expected ACTIVE state")
		end

		RunService.Heartbeat:Wait()
	end

	assert(core:GetState() == "ACTIVE", "C04 rebuild did not reach ACTIVE")
	assert(sawPreview, "C04 must expose PREVIEW state")
	assert(sawWaitClear, "C04 must expose WAIT_CLEAR state")
	assertPairPhysicsOn(core)
	assertMotorState(core, true, "C04 ACTIVE motor")
	assertAxleConnected(core, "C04 ACTIVE")

	if requireLiftEvidence then
		assert(initialRequiredLift ~= nil and initialRequiredLift > 0, "C04 lift scenario must initially require clearance")
		if minimumInitialLift ~= nil then
			assert(
				(initialRequiredLift :: number) > minimumInitialLift,
				string.format(
					"C04 high-lift scenario must require >%.2f studs; got %.3f",
					minimumInitialLift,
					(initialRequiredLift :: number)
				)
			)
		end
		assert(#waitClearYs >= 2, "C04 lift must unfold across multiple Heartbeats")
		local rose = false
		for index = 2, #waitClearYs do
			local delta = waitClearYs[index] - waitClearYs[index - 1]
			if delta > 1e-4 then
				rose = true
			end
			assert(
				math.abs(delta) < (initialRequiredLift :: number),
				"C04 body must not jump by the full required clearance in one Heartbeat"
			)
		end
		assert(rose, "C04 blocked redraw must raise the body physically over time")
	end

	return initialRequiredLift
end

function C04CoreV3ControllerSpec.run()
	local LegCoreController = nil :: any
	local controller = nil :: any
	local testModel = nil :: Model?
	local trackModel = nil :: Model?
	local createdRuntime = false
	local createdTracks = false

	local ok, failure = xpcall(function()
		local Clearance
		local ControllerModule
		local LegCoreConfig
		LegCoreController, Clearance, ControllerModule, LegCoreConfig = requireCoreV3Modules()
		assert(
			LegCoreConfig.Rebuild.ClearanceTimeout >= LegCoreConfig.Rebuild.MaxLift / LegCoreConfig.Rebuild.LiftTargetVelocity + 0.35,
			"C04 clearance timeout must cover the full configured physical lift envelope"
		)

		local runtimeFolder, runtimeCreated = ensureFolder(Workspace, "Runtime")
		createdRuntime = runtimeCreated
		local tracksFolder, tracksCreated = ensureFolder(runtimeFolder, "Tracks")
		createdTracks = tracksCreated

		trackModel = Instance.new("Model")
		trackModel.Name = "C04CoreV3Track"
		trackModel.Parent = tracksFolder

		local track = Instance.new("Part")
		track.Name = "FlatTrack"
		track.Size = Vector3.new(120, 1, 24)
		track.CFrame = CFrame.new(0, 0, 0)
		track.Anchored = true
		track.CanCollide = true
		track.CanTouch = true
		track.CanQuery = true
		track.Parent = trackModel

		testModel = Instance.new("Model")
		testModel.Name = "C04CoreV3ControllerTest"
		testModel.Parent = Workspace

		local body = Instance.new("Part")
		body.Name = "BodyCollider"
		body.Size = Vector3.new(3, 3, 3)
		body.CFrame = CFrame.new(0, 2.2, 0)
		body.Anchored = false
		body.CanCollide = true
		body.CanTouch = true
		body.CanQuery = true
		body.Parent = testModel
		testModel.PrimaryPart = body

		controller = LegCoreController.new(testModel)
		assert(controller:GetState() == "EMPTY", "C04 controller must begin EMPTY")
		assertMotorState(controller, false, "C04 initial motor")

		local firstShape = makeShape(1, 0.15, 1.4)
		local firstOk, firstError = controller:ApplyShape(firstShape, true)
		assert(firstOk == true, firstError or "C04 first ApplyShape rejected")
		assert(controller:GetState() == "PREVIEW", "C04 ApplyShape must enter PREVIEW immediately")
		waitForActiveAndObserve(controller, body, false, nil)

		local oldLeft = controller:GetLeftLeg()
		local oldRight = controller:GetRightLeg()
		assert(oldLeft ~= nil and oldRight ~= nil, "C04 first pair missing")
		local oldLeftParts = oldLeft:GetPhysicalSegments()
		local oldRightParts = oldRight:GetPhysicalSegments()

		-- Reset to a deterministic near-floor pose before the clearance redraw.
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		body.CFrame = CFrame.new(body.Position.X, 2.2, 0)
		RunService.Heartbeat:Wait()

		local xVelocityBefore = body.AssemblyLinearVelocity.X
		local secondShape = makeShape(2, -2.4, 2.6)
		local redrawOk, redrawError = controller:ApplyShape(secondShape, true)
		assert(redrawOk == true, redrawError or "C04 redraw rejected")
		assert(controller:GetState() == "PREVIEW", "C04 redraw must re-enter PREVIEW")
		assertMotorState(controller, false, "C04 redraw motor")
		assertAxleConnected(controller, "C04 redraw start")
		assert(math.abs(body.AssemblyLinearVelocity.X - xVelocityBefore) < 1e-4, "C04 redraw hop must not overwrite X velocity")
		-- Redraw hop is applied once to the body assembly. The always-enabled hinge
		-- must carry the axle with it without requiring a second external impulse.
		for _ = 1, 3 do
			RunService.Heartbeat:Wait()
			assertAxleConnected(controller, "C04 redraw hop")
		end

		for _, part in oldLeftParts do
			assert(part.Parent == nil, "C04 old LEFT physical geometry must be destroyed immediately")
		end
		for _, part in oldRightParts do
			assert(part.Parent == nil, "C04 old RIGHT physical geometry must be destroyed immediately")
		end

		waitForActiveAndObserve(controller, body, true, nil)

		-- Runtime envelope regression: this query-only blocker requires a real
		-- physical lift greater than the old 2.5-stud timeout envelope, but less
		-- than MaxLift. The rebuild must still reach ACTIVE.
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		body.CFrame = CFrame.new(body.Position.X, 2.2, 0)
		RunService.Heartbeat:Wait()

		local highLiftBlocker = Instance.new("Part")
		highLiftBlocker.Name = "C04HighLiftBlocker"
		highLiftBlocker.Size = Vector3.new(8, 4.3, 8)
		highLiftBlocker.CFrame = CFrame.new(body.Position.X, 2.15, 0)
		highLiftBlocker.Anchored = true
		highLiftBlocker.CanCollide = false
		highLiftBlocker.CanTouch = false
		highLiftBlocker.CanQuery = true
		highLiftBlocker.Parent = trackModel

		local highLiftShape = makeShape(3, 0.15, 1.4)
		local highLiftOk, highLiftError = controller:ApplyShape(highLiftShape, true)
		assert(highLiftOk == true, highLiftError or "C04 high-lift redraw rejected")
		local highLiftRequired = waitForActiveAndObserve(controller, body, true, 2.5)
		assert(highLiftRequired ~= nil, "C04 high-lift scenario did not report requiredLift")
		assert(
			(highLiftRequired :: number) < LegCoreConfig.Rebuild.MaxLift,
			"C04 high-lift scenario must remain inside MaxLift"
		)
		highLiftBlocker:Destroy()

		-- Clearance failure must fail closed: no partial physics and motor OFF.
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
		local impossibleShape = makeShape(4, -20, 20)
		local impossibleOk, impossibleError = controller:ApplyShape(impossibleShape, true)
		assert(impossibleOk == true, impossibleError or "C04 impossible redraw did not start")
		waitForState(controller, "EMPTY", 2.0)
		assert(controller:GetLeftLeg() == nil and controller:GetRightLeg() == nil, "C04 failed clearance must destroy ghost pair")
		assertMotorState(controller, false, "C04 failed-clearance motor")

		controller:Destroy()
		assert(controller:GetState() == "DESTROYED", "C04 Destroy must enter DESTROYED")
	end, debug.traceback)

	if controller ~= nil then
		controller:Destroy()
	end
	if testModel ~= nil then
		testModel:Destroy()
	end
	if trackModel ~= nil then
		trackModel:Destroy()
	end

	local runtimeFolder = Workspace:FindFirstChild("Runtime")
	local tracksFolder = if runtimeFolder ~= nil then runtimeFolder:FindFirstChild("Tracks") else nil
	if createdTracks and tracksFolder ~= nil and #tracksFolder:GetChildren() == 0 then
		tracksFolder:Destroy()
	end
	if createdRuntime and runtimeFolder ~= nil and #runtimeFolder:GetChildren() == 0 then
		runtimeFolder:Destroy()
	end

	assert(ok, failure)
	print("[DrawRacers][C04] Core V3 lifecycle controller PASS")
end

return C04CoreV3ControllerSpec
