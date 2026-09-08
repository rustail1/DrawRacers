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
	},
}
