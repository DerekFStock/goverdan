#!/usr/bin/env python3
"""Validate an authored content manifest without writing build artifacts."""

from __future__ import annotations

import argparse
from pathlib import Path

from content_tooling import ContentValidationError, compile_manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    try:
        result = compile_manifest(root, args.manifest)
    except ContentValidationError as error:
        print(f"Validation failed: {error}")
        return 1
    print(f"Validation succeeded for {result.report['manifest_id']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

