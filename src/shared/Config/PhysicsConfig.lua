--!strict

return {
	StrokeProcessing = {
		RawSampleMinMovementNormalized = 0.010,
		MaxRawPoints = 96,
		MinimumRawPoints = 3,
		DedupeDistance = 0.012,
		RDPEpsilon = 0.022,
		ResampleTargetPoints = 12,
		MaxCleanedPoints = 15,
		MinimumCleanedPolylineLength = 0.18,
		-- R16.3B: DrawInputRect is a wide isotropic semantic surface. Y half-span
		-- is the normalization unit; X receives the matching 1.75x pixel span.
		RawSemanticHalfWidth = 1.75,
		RawSemanticHalfHeight = 1.0,
		-- Kept as legacy symmetric bounds for older pure-math callers/tests. The
		-- authoritative R16.3B stroke path uses RawSemanticHalfWidth/Height.
		NormalizedMin = -1,
		NormalizedMax = 1,
		StrokeSubmitCooldown = 0.20,
		MaxStrokePayloadBytes = 4096,
		StrokeResultTimeout = 3.0,
		MaxPendingStrokes = 4,
	},
	LegGeometry = {
		-- RCP-02: the reference-scale leg reaches roughly twice as far as the
		-- previous 3.15/4.5 mapping while retaining the same authoritative shape.
		LegCanvasHalfSpan = 6.30,
		MaxLegExtentFromHub = 9.0,
		MinUsefulLegExtent = 0.7,
		-- Gameplay collision thickness stays materially smaller than presentation
		-- thickness so larger-looking legs do not gain an oversized collider.
		PhysicalLegSegmentThickness = 0.62,
		VisualLegSegmentThickness = 0.90,
		MaxColliderSegmentsPerLeg = 14,
		InnerHubNoCollisionRadius = 0.65,
		MinimumMappedSegmentLength = 0.08,
		SegmentOverlapAllowance = 0.06,
		HubOffsetX = 0.0,
		HubOffsetY = -0.35,
		-- Legacy/debug hub markers remain slightly outside the visible cube. The
		-- production R17 shared pair mounts its rigid side roots exactly on the
		-- canonical 3-stud cube surfaces using LegSocketZAbs.
		HubOffsetZAbs = 1.62,
		LegSocketZAbs = 1.5,
	},
	LegReshape = {
		-- RCP-04: arcade-fast geometry replacement. Studio evidence may tune this
		-- only inside the approved 0.08..0.15 second window.
		TypicalDuration = 0.10,
		MinimumDuration = 0.08,
		MaximumDuration = 0.15,
	},
	Motor = {
		AngularVelocity = -8.0,
		MotorMaxTorque = 35000,
		MotorMaxAcceleration = 120,
		-- Reference correction: both depth-separated copies remain rigid on one
		-- shared axle and rotate in the same motor direction, while the Right copy
		-- is mounted half a turn from the Left copy around that axle.
		RightPhaseOffsetDegrees = 180,
	},
	PhysicalMaterials = {
		LegSegment = {
			Density = 1.0,
			Friction = 1.0,
			Elasticity = 0.02,
			FrictionWeight = 100,
			ElasticityWeight = 100,
		},
	},
	Stabilization = {
		LaneNormalError = 0.03,
		LaneHardBound = 0.08,
		OrientationResponsiveness = 40,
		OrientationMaxTorque = 60000,
		OrientationMaxAngularVelocity = 30,
	},
	AntiStall = {
		Enabled = true,
		ActivationForwardSpeed = 0.35,
		ActivationDelay = 0.60,
		MaxAccelerationX = 2.0,
		MaxAssistDuration = 0.75,
		DisableForwardSpeed = 1.0,
	},
	Recovery = {
		ProgressSampleWindow = 2.5,
		MeaningfulHorizontalProgress = 0.35,
	},
}
