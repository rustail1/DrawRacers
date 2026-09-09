--!strict

export type StrokePoint = Vector2
export type StrokePoints = { Vector2 }

-- Network-safe semantic representation. Remote payloads never send Vector2 values directly;
-- they use explicit x/y fields so the server can validate the outer schema and every point.
export type SemanticPoint = {
	x: number,
	y: number,
}
export type SemanticPoints = { SemanticPoint }

export type SubmitStrokePayload = {
	sequence: number,
	points: SemanticPoints,
}

export type StrokeResultPayload = {
	sequence: number,
	accepted: boolean,
	shapeVersion: number?,
	acceptedPoints: SemanticPoints?,
	rejectReasonCode: string?,
}

export type ClampOptions = {
	minCoordinate: number,
	maxCoordinate: number,
	maxPoints: number?,
}

export type StrokeMathError =
	"NON_FINITE_POINT"
	| "TOO_MANY_POINTS"
	| "INVALID_BOUNDS"

export type ShapeBounds = {
	min: Vector2,
	max: Vector2,
}

export type ShapeSegmentPlanEntry = {
	index: number,
	a: Vector2,
	b: Vector2,
	canCollide: boolean,
}

export type ShapeSpec = {
	version: number,
	normalizedPoints: { Vector2 },
	mappedPoints: { Vector2 },
	bounds: ShapeBounds,
	extent: number,
	segmentPlan: { ShapeSegmentPlanEntry },
	debugRawPointCount: number,
	debugPhysicsPointCount: number,
	debugId: string,
}

export type LegShapeResult = {
	accepted: boolean,
	shapeVersion: number?,
	shapeSpec: ShapeSpec?,
	rejectReasonCode: string?,
}

return {}
