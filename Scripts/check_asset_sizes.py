#!/usr/bin/env python3
"""Fail if any bundled asset image is unreasonably large.

Guards against the "shipping full-resolution images" landmine: picked/bundled
photos should be downscaled + compressed (see SwMediaKit's reencodedForStorage)
before they land in the asset catalog. Stdlib-only (byte-size budget) so CI
needs no extra dependencies.

Usage: python3 Scripts/check_asset_sizes.py
Exit 0 if all clear, 1 (with a report) if any file exceeds the budget.
"""

import sys
from pathlib import Path

# Largest bundled pose JPEG is ~178 KB today; 400 KB leaves headroom while
# still catching multi-MB full-res regressions.
MAX_BYTES = 400 * 1024
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg"}
# AppIcon legitimately ships a 1024px master; exclude it from the budget.
EXCLUDE_DIRS = {"AppIcon.appiconset"}

ASSETS = Path(__file__).resolve().parent.parent / "Groundwerk" / "Assets.xcassets"


def main() -> int:
    if not ASSETS.is_dir():
        print(f"error: asset catalog not found at {ASSETS}", file=sys.stderr)
        return 1

    offenders = []
    for path in ASSETS.rglob("*"):
        if path.suffix.lower() not in IMAGE_SUFFIXES:
            continue
        if any(part in EXCLUDE_DIRS for part in path.parts):
            continue
        size = path.stat().st_size
        if size > MAX_BYTES:
            offenders.append((size, path))

    if offenders:
        print(f"Asset size check FAILED — {len(offenders)} file(s) over "
              f"{MAX_BYTES // 1024} KB:")
        for size, path in sorted(offenders, reverse=True):
            rel = path.relative_to(ASSETS.parent.parent)
            print(f"  {size // 1024:>5} KB  {rel}")
        print("\nDownscale/recompress these before committing.")
        return 1

    print(f"Asset size check passed (budget {MAX_BYTES // 1024} KB, "
          f"excluding {', '.join(sorted(EXCLUDE_DIRS))}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
