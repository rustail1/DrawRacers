from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r12_long_semantic_stroke_compacts_instead_of_freezing_at_cap() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert "function DrawingController:_compactSemanticPixelPoints" in drawing

    compact_start = drawing.index("function DrawingController:_compactSemanticPixelPoints")
    compact_end = drawing.index("function DrawingController:_tryAppendSemanticPoint", compact_start)
    compact_block = drawing[compact_start:compact_end]
    assert "table.clear(self._semanticPixelPoints)" in compact_block

    append_start = drawing.index("function DrawingController:_tryAppendSemanticPoint")
    append_end = drawing.index("function DrawingController:_compactLivePoints", append_start)
    append_block = drawing[append_start:append_end]
    assert "self:_compactSemanticPixelPoints()" in append_block
    assert "if #samples >= config.MaxRawPoints then\n\t\treturn\n\tend" not in append_block


def test_r12_new_character_does_not_reenable_retired_character_physics() -> None:
    harness = read("src/server/Tests/M0HumanHarness.lua")

    assert "local function disconnectCharacterDescendantWatcher" in harness

    isolate_start = harness.index("local function isolateCharacter")
    isolate_end = harness.index("local function disconnectCharacterWatcher", isolate_start)
    isolate_block = harness[isolate_start:isolate_end]
    assert "disconnectCharacterDescendantWatcher()" in isolate_block
    assert "restoreCharacter()" not in isolate_block

    restore_start = harness.index("local function restoreCharacter")
    restore_end = harness.index("local function isolateCharacter", restore_start)
    restore_block = harness[restore_start:restore_end]
    assert "disconnectCharacterDescendantWatcher()" in restore_block
