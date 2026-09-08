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
		NormalizedMin = -1,
		NormalizedMax = 1,
		StrokeSubmitCooldown = 0.20,
		MaxStrokePayloadBytes = 4096,
	},
	LegGeometry = {
		LegCanvasHalfSpan = 3.15,
		MaxLegExtentFromHub = 4.5,
		PhysicalLegSegmentThickness = 0.45,
		MaxColliderSegmentsPerLeg = 14,
		InnerHubNoCollisionRadius = 0.65,
		MinimumMappedSegmentLength = 0.08,
		SegmentOverlapAllowance = 0.06,
	},
	Motor = {
		AngularVelocity = -8.0,
		MotorMaxTorque = 35000,
		MotorMaxAcceleration = 120,
		RightPhaseOffsetDegrees = 180,
	},
	Stabilization = {
		LaneCorrectionDeadzone = 0.15,
		LaneNormalError = 0.35,
		LaneHardBound = 0.75,
		LaneMaxForceZ = 12000,
		LaneResponsiveness = 6,
		LaneMaxVelocity = 8,
		OrientationResponsiveness = 8,
		OrientationMaxTorque = 18000,
		OrientationMaxAngularVelocity = 8,
	},
}
