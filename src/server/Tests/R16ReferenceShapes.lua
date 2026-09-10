--!strict

local R16ReferenceShapes = {}

local SHAPES: { [string]: { Vector2 } } = {
	ROUND_01 = {
		Vector2.new(0.72, 0),
		Vector2.new(0.624, 0.36),
		Vector2.new(0.36, 0.624),
		Vector2.new(0, 0.72),
		Vector2.new(-0.36, 0.624),
		Vector2.new(-0.624, 0.36),
		Vector2.new(-0.72, 0),
		Vector2.new(-0.624, -0.36),
		Vector2.new(-0.36, -0.624),
		Vector2.new(0, -0.72),
		Vector2.new(0.36, -0.624),
		Vector2.new(0.624, -0.36),
	},
	LONG_BAR_01 = {
		Vector2.new(-0.92, 0),
		Vector2.new(-0.46, 0),
		Vector2.new(0, 0),
		Vector2.new(0.46, 0),
		Vector2.new(0.92, 0),
	},
	SMALL_ROUND_01 = {
		Vector2.new(0.4, 0),
		Vector2.new(0.3464, 0.2),
		Vector2.new(0.2, 0.3464),
		Vector2.new(0, 0.4),
		Vector2.new(-0.2, 0.3464),
		Vector2.new(-0.3464, 0.2),
		Vector2.new(-0.4, 0),
		Vector2.new(-0.3464, -0.2),
		Vector2.new(-0.2, -0.3464),
		Vector2.new(0, -0.4),
		Vector2.new(0.2, -0.3464),
		Vector2.new(0.3464, -0.2),
	},
	HOOK_01 = {
		Vector2.new(-0.20, -0.20),
		Vector2.new(0.10, -0.10),
		Vector2.new(0.45, 0.05),
		Vector2.new(0.72, 0.34),
		Vector2.new(0.70, 0.70),
		Vector2.new(0.38, 0.88),
		Vector2.new(0.12, 0.72),
	},
}

function R16ReferenceShapes.Get(shapeId: string): { Vector2 }
	local source = SHAPES[shapeId]
	assert(source ~= nil, string.format("unknown R16 reference shape %s", shapeId))
	local copy = table.create(#source)
	for index, point in source do
		copy[index] = point
	end
	return copy
end

function R16ReferenceShapes.Has(shapeId: string): boolean
	return SHAPES[shapeId] ~= nil
end

return R16ReferenceShapes
