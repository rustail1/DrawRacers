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
