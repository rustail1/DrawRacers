from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cr2_required_status_entrypoints_route_to_current_source_before_history() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")

    for path, doc in [("SESSION.md", session), ("FEATURE_LIST.md", features)]:
        assert "CR2 CURRENT OVERRIDE" in doc, f"{path} missing CR2 current override"
        assert "CR2_CURRENT_SOURCE_OF_TRUTH.md" in doc, f"{path} does not route to canonical CR2 source"
        assert "fixed visible pivot" in doc.lower(), f"{path} missing fixed-pivot current contract"
        assert "twin-drive" in doc.lower(), f"{path} missing twin-drive current contract"
        assert "shared axle" in doc.lower() and "retired" in doc.lower(), f"{path} must explicitly retire shared axle"
        assert "HUMAN STUDIO PENDING" in doc, f"{path} must keep human Studio gate pending"
        assert "B17/G0" in doc and "HUMAN_GATE" in doc, f"{path} must retain G0 hard stop"
        cr2_pos = doc.index("CR2 CURRENT OVERRIDE")
        history_pos = doc.find("R17 CURRENT OVERRIDE")
        if history_pos != -1:
            assert cr2_pos < history_pos, f"{path} must present CR2 before historical R17 override"


def test_cr2_status_entrypoints_do_not_claim_human_pass() -> None:
    for path in ["docs/SESSION.md", "docs/FEATURE_LIST.md"]:
        doc = read(path)
        cr2 = doc.split("CR2 CURRENT OVERRIDE", 1)[1].split("##", 1)[0]
        assert "HUMAN STUDIO PASS" not in cr2
        assert "B17/G0 PASS" not in cr2
