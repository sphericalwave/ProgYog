#!/usr/bin/env python3
"""Find identical images across the Poses/ asset catalog and remove
duplicates (TACFIT branding repeats across pose pages).

A hash that appears in >= THRESHOLD different imagesets is branding;
delete every occurrence. Re-indexes the remaining images so the
naming scheme stays contiguous: <series>-<famOrder>-<depth>-<idx>.
"""

from __future__ import annotations

import hashlib
import json
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

POSES = Path("/Users/darkknight/Documents/apps/fitness/ProgressiveYoga/ProgYog/Assets.xcassets/Poses")
THRESHOLD = 4  # appears in this many or more imagesets → branding


def asset_name(iset: Path) -> str:
    return iset.name.removesuffix(".imageset")


def parse_stem(name: str) -> tuple[str, int] | None:
    """`A-1-2-3` → ("A-1-2", 3); returns None if format unexpected."""
    m = re.match(r"^([A-E]-\d+-\d+)-(\d+)$", name)
    if not m:
        return None
    return (m.group(1), int(m.group(2)))


def main():
    imagesets = sorted(p for p in POSES.iterdir() if p.suffix == ".imageset")
    print(f"Scanning {len(imagesets)} imagesets...")

    hash_to_sets: dict[str, list[Path]] = defaultdict(list)
    for iset in imagesets:
        pngs = list(iset.glob("*.png"))
        if not pngs:
            continue
        png = pngs[0]
        h = hashlib.sha256(png.read_bytes()).hexdigest()
        hash_to_sets[h].append(iset)

    branding = [
        (h, paths) for h, paths in hash_to_sets.items() if len(paths) >= THRESHOLD
    ]
    branding.sort(key=lambda t: -len(t[1]))

    print(f"\nFound {len(branding)} duplicate-content groups with ≥ {THRESHOLD} copies:")
    to_delete: list[Path] = []
    for h, paths in branding:
        sample_png = next(paths[0].glob("*.png"))
        size = sample_png.stat().st_size
        print(f"  {h[:10]}…  ×{len(paths):3d}  {size:>7d}B  example: {paths[0].name}")
        to_delete.extend(paths)

    if not to_delete:
        print("Nothing to delete.")
        return

    if "--apply" not in sys.argv:
        print("\nRe-run with --apply to delete and re-index.")
        return

    # Delete the imagesets
    for path in to_delete:
        shutil.rmtree(path)
    print(f"\nDeleted {len(to_delete)} imagesets.")

    # Re-index per stem so idx stays contiguous (0, 1, 2, …).
    surviving: dict[str, list[Path]] = defaultdict(list)
    for p in sorted(POSES.iterdir()):
        if p.suffix != ".imageset":
            continue
        parsed = parse_stem(asset_name(p))
        if not parsed:
            continue
        stem, idx = parsed
        surviving[stem].append(p)

    renamed = 0
    for stem, paths in surviving.items():
        paths.sort(key=lambda p: int(parse_stem(asset_name(p))[1]))
        for new_idx, path in enumerate(paths):
            old_name = asset_name(path)
            new_name = f"{stem}-{new_idx}"
            if old_name == new_name:
                continue
            new_iset = path.with_name(f"{new_name}.imageset")
            path.rename(new_iset)
            # Rename PNG inside and rewrite Contents.json
            old_png = new_iset / f"{old_name}.png"
            new_png = new_iset / f"{new_name}.png"
            if old_png.exists():
                old_png.rename(new_png)
            contents = json.loads((new_iset / "Contents.json").read_text())
            for image in contents.get("images", []):
                if "filename" in image:
                    image["filename"] = f"{new_name}.png"
            (new_iset / "Contents.json").write_text(json.dumps(contents, indent=2))
            renamed += 1

    print(f"Re-indexed {renamed} imagesets to keep stems contiguous.")


if __name__ == "__main__":
    main()
