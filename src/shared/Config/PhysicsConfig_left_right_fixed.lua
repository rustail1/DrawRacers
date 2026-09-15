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
		RawSemanticHalfWidth = 1.75,
		RawSemanticHalfHeight = 1.0,
		-- Legacy symmetric bounds remain for low-level helpers only.
		NormalizedMin = -1,
		NormalizedMax = 1,
		StrokeSubmitCooldown = 0.20,
		MaxStrokePayloadBytes = 4096,
		StrokeResultTimeout = 3.0,
		MaxPendingStrokes = 4,
	},
	LegGeometry = {
		-- CR3 starting scale and explicit lower-body leg mount placement.
		-- Mount fractions are measured against body half-extents and remain HUMAN STUDIO tuning hypotheses.
		LegCanvasHalfSpan = 3.2,
		MaxLegExtentFromHub = 4.5,
		MinUsefulLegExtent = 0.7,
		-- Racer travels along +X, so left/right mounts are separated laterally on +/-Z.
		LegMountLateralFraction = 0.78,
		LegMountVerticalFraction = -0.72,
		PhysicalLegSegmentThickness = 0.54,
		VisualLegSegmentThickness = 0.78,
		MaxColliderSegmentsPerLeg = 14,
		InnerHubNoCollisionRadius = 0.65,
		MinimumMappedSegmentLength = 0.08,
		SegmentOverlapAllowance = 0.06,
	},
	LegReshape = {
		-- Visual-only staging window. Old physical geometry remains active until commit.
		TypicalDuration = 0.10,
		MinimumDuration = 0.08,
		MaximumDuration = 0.15,
	},
	Motor = {
		RotationSign = -1,
		TargetTipSpeed = 10.5,
		MinimumDriveRadius = 1.75,
		MinAngularVelocity = 1.5,
		MaxAngularVelocity = 6.0,
		MotorMaxTorque = 35000,
		MotorMaxAcceleration = 120,
		RightPhaseOffsetDegrees = 180,
	},
	RedrawSafety = {
		CandidateCount = 24,
		CandidateStepDegrees = 15,
		-- Shrink the overlap probe slightly so legal surface contact is not treated as penetration.
		OverlapProbeInset = 0.10,
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