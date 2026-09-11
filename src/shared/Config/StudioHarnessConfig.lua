--!strict

local MODES = {
	NONE = "NONE",
	B08 = "B08",
	B09 = "B09",
	B10 = "B10",
	G0 = "G0",
	R16B = "R16B",
	R16C = "R16C",
	R16FINAL = "R16FINAL",
	R17FINAL = "R17FINAL",
}

return {
	Modes = MODES,
	-- R17 reference acceptance is the current active Studio validation target.
	-- Keep G0 selectable, but default fresh synced Studio runs to the full R17 evidence path
	-- so a tester cannot accidentally validate only the legacy G0 harness.
	Mode = "R17FINAL",
}
