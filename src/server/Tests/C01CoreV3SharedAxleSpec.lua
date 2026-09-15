--!strict

local C01CoreV3SharedAxleSpec = {}

local function countHinges(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("HingeConstraint") then
			count += 1
		end
	end
	return count
end


local function isRigidlyWeldedTo(mount: Part, axleRoot: Part): boolean
	for _, child in mount:GetChildren() do
		if child:IsA("WeldConstraint") then
			local connectsAxle = child.Part0 == axleRoot or child.Part1 == axleRoot
			local connectsMount = child.Part0 == mount or child.Part1 == mount
			if connectsAxle and connectsMount then
				return true
			end
		end
	end
	return false
end

local function requireSharedAxle()
	local runtimeFolder = script.Parent.Parent:FindFirstChild("Runtime")
	assert(runtimeFolder ~= nil, "Runtime folder missing")

	local coreFolder = runtimeFolder:FindFirstChild("CoreV3")
	assert(coreFolder ~= nil, "CoreV3 runtime folder missing")

	local module = coreFolder:FindFirstChild("SharedAxle")
	assert(module ~= nil and module:IsA("ModuleScript"), "CoreV3 SharedAxle module missing")
	return require(module)
end

function C01CoreV3SharedAxleSpec.run()
	local SharedAxle = requireSharedAxle()

	local testModel = Instance.new("Model")
	testModel.Name = "C01CoreV3SharedAxleTest"
	testModel.Parent = workspace

	local body = Instance.new("Part")
	body.Name = "BodyCollider"
	body.Size = Vector3.new(3, 3, 3)
	body.CFrame = CFrame.new(12, 8, -7) * CFrame.Angles(0, math.rad(23), 0)
	body.Anchored = true
	body.Parent = testModel

	local container = Instance.new("Folder")
	container.Name = "CoreV3"
	container.Parent = testModel

	local ok, failure = xpcall(function()
		local shared = SharedAxle.new(body, container)

		assert(countHinges(testModel) == 1, "C01 expected exactly one HingeConstraint")

		local joint = shared:GetJoint()
		assert(joint:IsA("HingeConstraint"), "C01 joint must be a HingeConstraint")
		assert(joint.ActuatorType == Enum.ActuatorType.Motor, "C01 hinge must be the single motor")

		local axleRoot = shared:GetAxleRoot()
		local leftMount = shared:GetLeftMount()
		local rightMount = shared:GetRightMount()
		local bodyMount = joint.Attachment0
		assert(bodyMount ~= nil and bodyMount.Parent == body, "C01 hinge must mount directly to BodyCollider")
		assert(bodyMount.Position.Magnitude < 1e-6, "C01 body mount must have no local offset workaround")

		assert(axleRoot.CollisionGroup == "RacerLeg", "C01 AxleRoot must use RacerLeg collision group")
		assert(leftMount.CollisionGroup == "RacerLeg", "C01 LeftMount must use RacerLeg collision group")
		assert(rightMount.CollisionGroup == "RacerLeg", "C01 RightMount must use RacerLeg collision group")
		local axleMaterial = axleRoot.CustomPhysicalProperties
		assert(axleMaterial ~= nil, "C01 AxleRoot must define physical properties")
		assert((axleMaterial :: PhysicalProperties).Density >= 0.25, "C01 AxleRoot density must be solver-stable")
		assert(axleRoot.Size.X >= 1.0 and axleRoot.Size.Y >= 1.0, "C01 AxleRoot must carry non-trivial driven inertia")
		assert(axleRoot.AssemblyMass >= 0.5, "C01 driven axle assembly mass must not be near-zero")
		assert(math.abs((axleMaterial :: PhysicalProperties).Friction) < 1e-6, "C01 AxleRoot friction must be zero")
		local axleLocal = body.CFrame:PointToObjectSpace(axleRoot.Position)
		local leftLocal = body.CFrame:PointToObjectSpace(leftMount.Position)
		local rightLocal = body.CFrame:PointToObjectSpace(rightMount.Position)

		assert(math.abs(axleLocal.X) < 1e-3, "C01 AxleRoot X must equal BodyCollider center X")
		assert(math.abs(axleLocal.Y) < 1e-3, "C01 AxleRoot Y must equal BodyCollider center Y")
		assert(leftLocal.Z < -body.Size.Z * 0.5, "C01 LeftMount must be outside the -Z body face")
		assert(rightLocal.Z > body.Size.Z * 0.5, "C01 RightMount must be outside the +Z body face")
		assert(math.abs(leftLocal.Z + rightLocal.Z) < 1e-3, "C01 LEFT/RIGHT mounts must be symmetric on Z")
		assert(math.abs(leftLocal.X) < 1e-3, "C01 LeftMount must not shift along X")
		assert(math.abs(rightLocal.X) < 1e-3, "C01 RightMount must not shift along X")
		assert(math.abs(leftLocal.Y) < 1e-3, "C01 LeftMount Y must equal BodyCollider center Y")
		assert(math.abs(rightLocal.Y) < 1e-3, "C01 RightMount Y must equal BodyCollider center Y")

		local dot = leftMount.CFrame.RightVector:Dot(rightMount.CFrame.RightVector)
		assert(dot <= -0.999, "C01 RightMount must be rigidly 180 degrees opposed to LeftMount")
		assert(isRigidlyWeldedTo(leftMount, axleRoot), "C01 LeftMount must be rigidly welded to AxleRoot")
		assert(isRigidlyWeldedTo(rightMount, axleRoot), "C01 RightMount must be rigidly welded to AxleRoot")

		assert(countHinges(leftMount) == 0, "C01 LeftMount must not own a second hinge")
		assert(countHinges(rightMount) == 0, "C01 RightMount must not own a second hinge")

		-- Motor OFF must never detach the physical hinge. Core V3 rebuild relies on
		-- body and axle remaining one constrained mechanism while the actuator is idle.
		shared:SetEnabled(false)
		assert(joint.Enabled == true, "C01 motor OFF must keep the hinge constraint physically enabled")
		assert(joint.ActuatorType == Enum.ActuatorType.None, "C01 motor OFF must disable only the actuator")
		shared:SetEnabled(true)
		assert(joint.Enabled == true, "C01 motor ON must keep the hinge constraint enabled")
		assert(joint.ActuatorType == Enum.ActuatorType.Motor, "C01 motor ON must restore the motor actuator")

		shared:Destroy()
		assert(countHinges(testModel) == 0, "C01 Destroy must remove the shared hinge")
	end, debug.traceback)

	testModel:Destroy()
	assert(ok, failure)
	print("[DrawRacers][C01] Core V3 SharedAxle PASS")
end

return C01CoreV3SharedAxleSpec
