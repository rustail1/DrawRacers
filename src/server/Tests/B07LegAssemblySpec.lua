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
	local leftHub = model:FindFirstChild("LeftHub")
	assert(leftHub and leftHub:IsA("Part"), "B07 racer missing LeftHub")

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
		motorEnabled = false,
	})

	local legModel = leg:GetModel()
	assert(legModel.Name == "LeftLeg")
	assert(model.Legs:FindFirstChild("LeftLeg") == legModel)
	assert(legModel:FindFirstChild("LegRoot") and legModel.LegRoot:IsA("Part"), "B07 missing LegRoot")
	assert(legModel:FindFirstChild("HubJoint") and legModel.HubJoint:IsA("HingeConstraint"), "B07 missing HubJoint")
	assert(legModel:FindFirstChild("Segments") and legModel.Segments:IsA("Folder"), "B07 missing Segments")
	assert(legModel:FindFirstChild("Visual") and legModel.Visual:IsA("Folder"), "B07 missing Visual")
	assert(legModel:FindFirstChild("RightLeg") == nil, "B07 must not build RightLeg")

	assert((leg:GetRoot().Position - leftHub.Position).Magnitude <= 1e-4, "LegRoot must be centered on LeftHub")
	assert(leg:GetRoot().CanCollide == false)
	assert(leg:GetRoot().CollisionGroup == "RacerLeg")

	local mapped = leg:GetMappedPoints()
	assert(#mapped == 3)
	assertClose(mapped[1].Magnitude, 0, 1e-6, "center maps to hub pivot")
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
	assert(segments[1].CanCollide == false, "inner-hub segment must keep collision disabled")
	assert(segments[2].CanCollide == true, "outer segment must collide with Track")

	for index, segment in segments do
		assert(segment.Name == string.format("Segment_%02d", index))
		assert(segment.CollisionGroup == "RacerLeg")
		local weld = segment:FindFirstChild("RootWeld")
		assert(weld and weld:IsA("WeldConstraint"), "segment missing RootWeld")
		assert(weld.Part0 == leg:GetRoot() and weld.Part1 == segment, "segment weld must rigidly bind to one LegRoot")
	end

	local joint = leg:GetJoint()
	assert(joint.Attachment0 == leftHub.MotorAttachment)
	assert(joint.Attachment1 == leg:GetRoot().MotorAttachment)
	assert(joint.Enabled == false, "B07 deterministic geometry spec must not run its motor")

	leg:Destroy()
	assert(model.Legs:FindFirstChild("LeftLeg") == nil, "LegAssembly destroy left runtime geometry behind")
	racer:Destroy()

	print("[DrawRacers][B07] one-leg geometry tests PASS")
end

return B07LegAssemblySpec
