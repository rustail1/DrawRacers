--!strict

local MODES = {
	NONE = "NONE",
	B08 = "B08",
	B09 = "B09",
	B10 = "B10",
	G0 = "G0",
	COREV3_TEST = "COREV3_TEST",
	COREV3 = "COREV3",
	R16B = "R16B",
	R16C = "R16C",
	R16FINAL = "R16FINAL",
	R17FINAL = "R17FINAL",
}

return {
	Modes = MODES,
	-- Core V3 Task 8 human flat-physics mode. This starts only CoreV3FlatHarness;
	-- legacy obstacle/regression/evidence harnesses stay out of the startup path.
	Mode = "COREV3",
}
