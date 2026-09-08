--!strict

export type StrokePoint = Vector2
export type StrokePoints = { Vector2 }

export type ClampOptions = {
	minCoordinate: number,
	maxCoordinate: number,
	maxPoints: number?,
}

export type StrokeMathError =
	"NON_FINITE_POINT"
	| "TOO_MANY_POINTS"
	| "INVALID_BOUNDS"

return {}
