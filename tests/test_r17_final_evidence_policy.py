from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r17final_only_blocks_on_current_structural_evidence() -> None:
    final = read("src/server/Tests/R17FinalHarness.lua")

    assert "local function observeEvidence" in final
    assert 'observeEvidence("R16 baseline"' in final
    assert 'observeEvidence("R17.3 origin"' in final
    assert 'requireEvidence("R17.5 phase"' in final
    assert 'observeEvidence("R17.6 body feel"' in final
    assert 'observeEvidence("R17.7 course"' in final
    assert "NON-GATING" in final
    assert "[DrawRacers][R17FINAL] HUMAN REVIEW READY" in final

    # The current shared-axle live invariant is structural. Historical R16
    # reference-fit/tuning outcomes and R17 comparison sweeps are evidence for
    # the pending human/tuning decision and must not prevent collecting later
    # R17 evidence.
    assert 'requireEvidence("R16"' not in final
    assert 'requireEvidence("R17.6 body feel"' not in final
    assert 'requireEvidence("R17.7 course"' not in final
