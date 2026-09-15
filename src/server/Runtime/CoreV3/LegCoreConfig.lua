--!strict

return {
	Mount = {
		SideOutset = 0.45,
		-- Put the shared axle below the cube center so even the smallest valid
		-- leg can become the load-bearing contact instead of wedging against a
		-- body that is already flat on the Track.
		VerticalFraction = -0.50,
		RightPhaseDegrees = 180,
		-- Physical inertia carrier for the otherwise-massless drawn geometry.
		-- It is invisible/noncolliding; its job is solver stability only.
		AxleRootSize = 1.50,
	},

	Geometry = {
		PhysicalThickness = 0.54,
		VisualThickness = 0.78,
		MaxSegments = 14,
		SegmentOverlapAllowance = 0.06,
	},

	Motor = {
		RotationSign = -1,
		TargetTipSpeed = 15.0,
		MinimumDriveRadius = 1.75,
		MinAngularVelocity = 1.5,
		MaxAngularVelocity = 8.0,
		Torque = 35000,
		Acceleration = 120,
	},

	Materials = {
		-- Core V3 locomotion traction must come from leg <-> Track contact.
		-- Keep the BodyCollider collidable so it cannot fall through the lane,
		-- but remove horizontal body/Track friction so the body itself cannot
		-- pin the mechanism while the driven leg is trying to roll/step.
		Body = {
			Density = 0.25,
			Friction = 0.0,
			Elasticity = 0.04,
			FrictionWeight = 100,
			ElasticityWeight = 100,
		},
		Leg = {
			Density = 0.60,
			Friction = 1.0,
			Elasticity = 0.02,
			FrictionWeight = 100,
			ElasticityWeight = 100,
		},
		Axle = {
			Density = 0.50,
			Friction = 0.0,
			Elasticity = 0.0,
			FrictionWeight = 0,
			ElasticityWeight = 0,
		},
	},

	Rebuild = {
		PreviewDuration = 0.10,
		HopTargetVelocity = 3.5,
		MaxHopDeltaVelocity = 5.0,
		ClearancePadding = 0.08,
		-- Must cover MaxLift/LiftTargetVelocity plus solver/acceleration margin.
		ClearanceTimeout = 1.25,
		MaxLift = 4.0,
		LiftTargetVelocity = 5.0,
	},
}
