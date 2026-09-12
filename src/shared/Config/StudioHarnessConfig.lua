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
	-- Normal Studio Play is the fast human core-iteration loop: scene + G0 racer,
	-- with no automatic B03-B16/R17 evidence startup. Select a focused/R16/R17
	-- evidence mode explicitly when that evidence is actually needed.
	Mode = "G0",
}
