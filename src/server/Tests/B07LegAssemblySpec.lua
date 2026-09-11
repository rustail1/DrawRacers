--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local GeometryMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("GeometryMath")
)
local RacerRuntime = require(script.Parent.Parent.Runtime:WaitForChild("RacerRuntime"))
local LegAssembly = require(script.Parent.Parent.Runtime:WaitForChild("LegAssembly"))

local B07LegAssemblySpec = {}

local function assertClose(actual: number, expected: number, epsilon: number, message: string)
	assert(math.abs(actual - expected) <= epsilon, string.format("%s: expected %.6f got %.6f", message, expected, actual))
end

function B07LegAssemblySpec.run()
	local racer = RacerRuntime.new({
		raceId = "B07_TEST",
		slotIndex = 1,
		laneIndex = 1,
		isBot = false,
		trackId = "B07_FLAT",
		spawnCFrame = CFrame.new(-40, 12, 0),
	})

	local body = racer:GetBody()
	body.Anchored = true
	local model = racer:GetModel()
	local legsFolder = model:FindFirstChild("Legs")
	assert(legsFolder and legsFolder:IsA("Folder"), "B07 racer missing Legs")

	local axleRoot = Instance.new("Part")
	axleRoot.Name = "B07AxleRoot"
	axleRoot.Size = Vector3.new(0.2, 0.2, 0.2)
	axleRoot.CFrame = body.CFrame * CFrame.new(
		PhysicsConfig.LegGeometry.HubOffsetX,
		PhysicsConfig.LegGeometry.HubOffsetY,
		0
	)
	axleRoot.Anchored = true
	axleRoot.CanCollide = false
	axleRoot.Parent = legsFolder

	local sourcePoints = {
		Vector2.new(0, 0),
		Vector2.new(0.40, 0.30),
		Vector2.new(1, 1),
	}
	local geometryPlan = GeometryMath.BuildSegmentPlan(sourcePoints, PhysicsConfig.LegGeometry)
	local shapeSpec = {
		normalizedPoints = sourcePoints,
		mappedPoints = geometryPlan.mappedPoints,
		segmentPlan = geometryPlan.segmentPlan,
		extent = geometryPlan.extent,
	}

	local leg = LegAssembly.new({
		racerModel = model,
		side = "Left",
		shapeSpec = shapeSpec,
		axleRoot = axleRoot,
		socketZ = -PhysicsConfig.LegGeometry.LegSocketZAbs,
		phaseDegrees = 0,
	})

	local legModel = leg:GetModel()
	assert(legModel.Name == "LeftLeg")
	assert(model.Legs:FindFirstChild("LeftLeg") == legModel)
	assert(legModel:FindFirstChild("LegRoot") and legModel.LegRoot:IsA("Part"), "B07 missing LegRoot")
	assert(legModel:FindFirstChild("HubJoint") == nil, "R17 side geometry must not own a hinge")
	assert(legModel:FindFirstChild("Segments") and legModel.Segments:IsA("Folder"), "B07 missing Segments")
	assert(legModel:FindFirstChild("Visual") and legModel.Visual:IsA("Folder"), "B07 missing Visual")
	assert(legModel:FindFirstChild("RightLeg") == nil, "B07 must not build RightLeg")

	local expectedSocket = axleRoot.CFrame * CFrame.new(0, 0, -PhysicsConfig.LegGeometry.LegSocketZAbs)
	assert((leg:GetRoot().Position - expectedSocket.Position).Magnitude <= 1e-4, "LegRoot must start on exact cube-side socket")
	assert(leg:GetRoot().CanCollide == false)
	assert(leg:GetRoot().CollisionGroup == "RacerLeg")
	local axleWeld = leg:GetRoot():FindFirstChild("AxleWeld")
	assert(axleWeld and axleWeld:IsA("WeldConstraint"), "rigid side missing AxleWeld")
	assert(axleWeld.Part0 == axleRoot and axleWeld.Part1 == leg:GetRoot(), "side must be rigidly bound to shared axle")

	local mapped = leg:GetMappedPoints()
	assert(#mapped == 3)
	assertClose(mapped[1].Magnitude, 0, 1e-6, "first point maps to socket pivot")
	assertClose(mapped[2].X, 1.26, 1e-6, "isotropic X scale")
	assertClose(mapped[2].Y, 0.945, 1e-6, "isotropic Y scale")
	local expectedCornerMagnitude = math.min(
		PhysicsConfig.LegGeometry.LegCanvasHalfSpan * math.sqrt(2),
		PhysicsConfig.LegGeometry.MaxLegExtentFromHub
	)
	assertClose(mapped[3].Magnitude, expectedCornerMagnitude, 1e-5, "corner mapping respects radial hard cap")
	assert(
		mapped[3].Magnitude <= PhysicsConfig.LegGeometry.MaxLegExtentFromHub + 1e-5,
		"corner mapping exceeded radial hard cap"
	)

	local hardCapGeometry = table.clone(PhysicsConfig.LegGeometry)
	hardCapGeometry.LegCanvasHalfSpan = 4.0
	local hardCapped = GeometryMath.MapPoint(Vector2.new(1, 1), hardCapGeometry)
	assertClose(hardCapped.Magnitude, hardCapGeometry.MaxLegExtentFromHub, 1e-5, "radial hard cap")

	local segments = leg:GetSegments()
	assert(#segments == 2, "expected exactly two legal consecutive segments")
	assert(#segments <= 14, "segment count exceeded launch cap")
	assert(segments[1].CanCollide == false, "inner-socket segment must keep collision disabled")
	assert(segments[2].CanCollide == true, "outer segment must collide with Track")

	for index, segment in segments do
		assert(segment.Name == string.format("Segment_%02d", index))
		assert(segment.CollisionGroup == "RacerLeg")
		assert(segment.Transparency == 1, "physical colliders must stay hidden from presentation")
		local weld = segment:FindFirstChild("RootWeld")
		assert(weld and weld:IsA("WeldConstraint"), "segment missing RootWeld")
		assert(weld.Part0 == leg:GetRoot() and weld.Part1 == segment, "segment weld must rigidly bind to one LegRoot")
	end

	local physicalCountBeforeVisualCheck = #segments
	local visualFolder = legModel.Visual
	local visualPartCount = 0
	for _, descendant in visualFolder:GetDescendants() do
		if descendant:IsA("BasePart") then
			visualPartCount += 1
			assert(descendant.CanCollide == false, "visual representation must never collide")
			assert(descendant.CanTouch == false, "visual representation must never touch")
			assert(descendant.CanQuery == false, "visual representation must never query")
			assert(descendant.Massless == true, "visual representation must stay massless")
		end
	end
	assert(visualPartCount > 0, "R16.3B visual layer produced no visible geometry")
	assert(#leg:GetSegments() == physicalCountBeforeVisualCheck, "physical collider count changed by visual layer")

	leg:Destroy()
	axleRoot:Destroy()
	assert(model.Legs:FindFirstChild("LeftLeg") == nil, "LegAssembly destroy left runtime geometry behind")
	racer:Destroy()

	print("[DrawRacers][B07] one-leg geometry tests PASS")
end

return B07LegAssemblySpec
