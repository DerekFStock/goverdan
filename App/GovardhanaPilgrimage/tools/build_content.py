#!/usr/bin/env python3
"""Validate content and write deterministic Task 001 intermediate artifacts."""

from __future__ import annotations

import argparse
from pathlib import Path

from content_tooling import ContentValidationError, compile_manifest, write_intermediate, write_report
from sqlite_builder import DATABASE_FILENAME, build_sqlite


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    try:
        result = compile_manifest(root, args.manifest)
        intermediate_path = write_intermediate(root, result)
        database_path = root / "build" / DATABASE_FILENAME
        sqlite_report = build_sqlite(database_path, result)
        report = {**result.report, "sqlite": sqlite_report}
        report_path = write_report(root, report)
    except ContentValidationError as error:
        print(f"Build failed: {error}")
        return 1
    print(f"Build succeeded for {result.report['manifest_id']}")
    for path in (intermediate_path, database_path, report_path):
        print(path.relative_to(root))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
