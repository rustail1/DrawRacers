from __future__ import annotations

import importlib.util
import inspect
import sys
import traceback
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TEST_DIR = ROOT / "tests"


def load_module(path: Path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    test_files = sorted(TEST_DIR.glob("test_*.py"))
    if not test_files:
        print("No contract tests found.")
        return 1

    passed = 0
    failed = 0

    for test_file in test_files:
        module = load_module(test_file)
        tests = [
            (name, value)
            for name, value in vars(module).items()
            if name.startswith("test_") and callable(value)
        ]

        for name, test in tests:
            signature = inspect.signature(test)
            if signature.parameters:
                print(f"SKIP {test_file.name}::{name} (requires pytest fixture/arguments)")
                failed += 1
                continue

            try:
                test()
            except Exception:
                failed += 1
                print(f"FAIL {test_file.name}::{name}")
                traceback.print_exc()
            else:
                passed += 1
                print(f"PASS {test_file.name}::{name}")

    print(f"\nContract checks: {passed} passed, {failed} failed")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
