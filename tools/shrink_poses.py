#!/usr/bin/env python3
"""Resize and re-encode every pose image so the bundle fits on disk.

Each ~12MB extracted PNG becomes a ~150KB JPEG capped at 1024px on
its longest side. Updates every imageset's Contents.json to reference
the new filename.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

POSES = Path("/Users/darkknight/Documents/apps/fitness/ProgressiveYoga/ProgYog/Assets.xcassets/Poses")
MAX_SIDE = 1024
QUALITY = 78  # 0-100; 78 is plenty for these reference photos


def main():
    isets = sorted(p for p in POSES.iterdir() if p.suffix == ".imageset")
    print(f"Processing {len(isets)} imagesets...")
    total_before = 0
    total_after = 0
    for iset in isets:
        for png in list(iset.glob("*.png")):
            jpg = png.with_suffix(".jpg")
            total_before += png.stat().st_size
            subprocess.run(
                [
                    "sips",
                    "-s", "format", "jpeg",
                    "-s", "formatOptions", str(QUALITY),
                    "-Z", str(MAX_SIDE),
                    str(png),
                    "--out", str(jpg),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            png.unlink()
            total_after += jpg.stat().st_size

        contents_path = iset / "Contents.json"
        contents = json.loads(contents_path.read_text())
        new_name = iset.name.removesuffix(".imageset") + ".jpg"
        for image in contents.get("images", []):
            if "filename" in image:
                image["filename"] = new_name
        contents_path.write_text(json.dumps(contents, indent=2))

    mb_before = total_before / 1024 / 1024
    mb_after = total_after / 1024 / 1024
    print(f"Before: {mb_before:.1f} MB")
    print(f"After:  {mb_after:.1f} MB")
    print(f"Reduction: {(1 - mb_after / mb_before) * 100:.1f}%")


if __name__ == "__main__":
    main()
