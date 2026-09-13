from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def current_block(doc: str) -> str:
    marker = "CR3 CURRENT OVERRIDE"
    assert marker in doc, "missing CR3 current override"
    return doc.split(marker, 1)[1].split("##", 1)[0]


def test_cr3_required_status_entrypoints_route_to_current_source_before_history() -> None:
    entrypoints = {
        "README.md": read("README.md"),
        "docs/README.md": read("docs/README.md"),
        "SESSION.md": read("docs/SESSION.md"),
        "FEATURE_LIST.md": read("docs/FEATURE_LIST.md"),
    }

    for path, doc in entrypoints.items():
        assert "CR3 CURRENT OVERRIDE" in doc, f"{path} missing CR3 current override"
        assert "CR3_CURRENT_SOURCE_OF_TRUTH.md" in doc, f"{path} does not route to canonical CR3 source"
        block = current_block(doc)
        assert "free draw" in block.lower(), f"{path} missing free-draw current contract"
        assert "support anchor" in block.lower(), f"{path} missing support-anchor current contract"
        assert "LeftLegMount" in block and "RightLegMount" in block, f"{path} missing explicit lower mounts"
        assert "single" in block.lower() and "phase" in block.lower(), f"{path} missing single phase-owner contract"
        assert "HUMAN STUDIO" in block and "PENDING" in block, f"{path} must keep human Studio gate pending"
        assert "B17/G0" in block and "HUMAN_GATE" in block, f"{path} must retain G0 hard stop"

        cr3_pos = doc.index("CR3 CURRENT OVERRIDE")
        for historical_marker in ["CR2 CURRENT OVERRIDE", "R17 CURRENT OVERRIDE"]:
            history_pos = doc.find(historical_marker)
            if history_pos != -1:
                assert cr3_pos < history_pos, f"{path} must present CR3 before historical {historical_marker}"


def test_cr3_current_blocks_do_not_reintroduce_superseded_cr2_or_claim_human_pass() -> None:
    for path in ["README.md", "docs/README.md", "docs/SESSION.md", "docs/FEATURE_LIST.md"]:
        block = current_block(read(path))
        for retired in ["fixed visible pivot", "START FROM THE DOT", "START_OFF_PIVOT", "phase correction"]:
            assert retired.lower() not in block.lower(), f"{path} current block reintroduces retired CR2 contract: {retired}"
        assert "HUMAN STUDIO PASS" not in block
        assert "B17/G0 PASS" not in block
