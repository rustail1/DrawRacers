--!strict

local PhysicsService = game:GetService("PhysicsService")

local CollisionGroups = {
	Default = "Default",
	Track = "Track",
	RacerBody = "RacerBody",
	RacerLeg = "RacerLeg",
	Decoration = "Decoration",
	Trigger = "Trigger",
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
	register(CollisionGroups.Decoration)
	register(CollisionGroups.Trigger)

	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.RacerBody, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.RacerLeg, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.RacerLeg, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Track, true)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Track, true)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Default, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Default, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Track, CollisionGroups.Decoration, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Track, CollisionGroups.Trigger, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Decoration, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerBody, CollisionGroups.Trigger, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Decoration, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.RacerLeg, CollisionGroups.Trigger, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Decoration, CollisionGroups.Decoration, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Decoration, CollisionGroups.Trigger, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Trigger, CollisionGroups.Trigger, false)

	initialized = true
end

return CollisionGroups
