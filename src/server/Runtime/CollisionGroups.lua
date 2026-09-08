--!strict

local PhysicsService = game:GetService("PhysicsService")

local CollisionGroups = {
	Track = "Track",
	RacerBody = "RacerBody",
	RacerLeg = "RacerLeg",
}

local initialized = false

local function register(name: string)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

function CollisionGroups.ensure()
	if initialized then
		return
	end

	register(CollisionGroups.Track)
	register(CollisionGroups.RacerBody)
	register(CollisionGroups.RacerLeg)

	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.RacerBody, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.RacerLeg, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.RacerLeg, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Track, true)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Track, true)

	initialized = true
end

return CollisionGroups
