#!/usr/bin/env python3
"""Extract pose images from TACFIT Progressive Yoga manuals and
build asset-catalog imagesets for the iOS app.

Each pose page contains a strip like:
    PROGRESSIVE YOGA EXERCISE MANUAL <POSE NAME>
    T A C F I T B O D Y W E I G H T A N D D U M B B E L L 4 5
    <FAMILY NAME> <DEPTH><VARIANT>
    R X 4 P R O G R E S S I V E Y O G A
    DURATION: …
    P R O G R E S S I V E Y O G A <SERIES>

That gives us series + family + depth without depending on fuzzy
matching against the JSON catalog.

Output: ProgYog/Assets.xcassets/Poses/<series>-<famOrder>-<depth>-<idx>.imageset/
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path
from collections import defaultdict
from io import BytesIO

import fitz  # PyMuPDF

ROOT = Path("/Users/darkknight/Documents/apps/fitness/ProgressiveYoga")
MANUAL_DIR = ROOT / "manuals"
SKILL_JSON = ROOT / "ProgYog/Data/Json/ProgYogData.json"
FAM_JSON   = ROOT / "ProgYog/Data/Json/SkillFam.json"
ASSETS_OUT = ROOT / "ProgYog/Assets.xcassets/Poses"

MIN_AREA = 350 * 350


def normalize(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", s.lower()).strip()


def load_families_by_series() -> dict[str, list[dict]]:
    """{series: [{name, order, upper, normalized}, …]}"""
    out: dict[str, list[dict]] = defaultdict(list)
    raw = json.loads(FAM_JSON.read_text())
    for f in raw:
        out[f["series"]].append({
            "name": f["name"],
            "order": int(f["order"]),
            "upper": f["name"].upper(),
            "normalized": normalize(f["name"]),
        })
    # Sort each list by length desc so the longest family name wins (e.g.
    # "STANDING FORWARD FOLD" beats "FORWARD FOLD").
    for series in out:
        out[series].sort(key=lambda f: -len(f["upper"]))
    return out


def parse_page_metadata(
    text: str,
    default_series: str,
    families_by_series: dict[str, list[dict]],
) -> tuple[str, int, int] | None:
    """Returns (series, family_order, depth) or None."""
    # Trust the filename's series. Pages often print multiple workout
    # letters in their footer, which made a text-based series sniff unreliable.
    series = default_series

    # Compact the text so "SIDE BEND" and "SIDEBEND" both match the JSON's
    # canonical "SIDEBEND". Inter-character spacing in the PDF varies.
    compact = re.sub(r"\s+", "", text).upper()

    for fam in families_by_series.get(series, []):
        needle = fam["upper"].replace(" ", "")
        start = 0
        while True:
            idx = compact.find(needle, start)
            if idx < 0:
                break
            rest = compact[idx + len(needle):]
            m = re.match(r"(\d+)[AB]?", rest)
            if m:
                return (series, fam["order"], int(m.group(1)))
            start = idx + 1
    return None


def page_pose_title(text: str) -> str | None:
    flat = re.sub(r"\s+", " ", text)
    m = re.search(
        r"PROGRESSIVE YOGA EXERCISE MANUAL\s+(.+?)\s+(?:T A C F I T|R X|P R O G R E S S I V E|DURATION)",
        flat,
    )
    return m.group(1).strip() if m else None


def extract_large_images(doc: fitz.Document, page: fitz.Page) -> list[bytes]:
    """Returns PNG bytes for each large embedded image on the page,
    sorted by area descending (largest first)."""
    images = []
    for info in page.get_images(full=True):
        xref = info[0]
        try:
            ext_img = doc.extract_image(xref)
        except Exception:
            continue
        w = ext_img.get("width") or 0
        h = ext_img.get("height") or 0
        if w * h < MIN_AREA:
            continue
        raw = ext_img["image"]
        ext = ext_img.get("ext", "png")
        if ext.lower() == "png":
            png_bytes = raw
        else:
            # Convert via Pixmap
            try:
                pix = fitz.Pixmap(raw)
                if pix.colorspace and pix.colorspace.n > 3:
                    pix = fitz.Pixmap(fitz.csRGB, pix)
                png_bytes = pix.tobytes("png")
            except Exception:
                continue
        images.append((w * h, png_bytes))
    images.sort(key=lambda t: -t[0])
    return [b for _, b in images]


def write_imageset(stem: str, idx: int, png_bytes: bytes):
    name = f"{stem}-{idx}"
    iset = ASSETS_OUT / f"{name}.imageset"
    iset.mkdir(parents=True, exist_ok=True)
    (iset / f"{name}.png").write_bytes(png_bytes)
    contents = {
        "images": [
            {
                "filename": f"{name}.png",
                "idiom": "universal",
                "scale": "1x",
            },
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (iset / "Contents.json").write_text(json.dumps(contents, indent=2))


def write_namespace_root():
    ASSETS_OUT.mkdir(parents=True, exist_ok=True)
    root = {
        "info": {"author": "xcode", "version": 1},
        "properties": {"provides-namespace": True},
    }
    (ASSETS_OUT / "Contents.json").write_text(json.dumps(root, indent=2))


def main():
    # Clean previous run
    if ASSETS_OUT.exists():
        shutil.rmtree(ASSETS_OUT)
    write_namespace_root()

    families_by_series = load_families_by_series()

    per_stem_count: dict[str, int] = defaultdict(int)
    unmatched: list[str] = []
    matched = 0

    for pdf_path in sorted(MANUAL_DIR.glob("Progressive_Yoga_*_Manual.pdf")):
        default_series = pdf_path.name.split("_")[2]
        doc = fitz.open(pdf_path)
        for i, page in enumerate(doc, start=1):
            if i < 9:
                continue
            text = page.get_text("text") or ""
            meta = parse_page_metadata(text, default_series, families_by_series)
            title = page_pose_title(text) or f"<p.{i}>"
            if not meta:
                unmatched.append(f"{pdf_path.name} p.{i} title={title!r}")
                continue
            series, order, depth = meta

            stem = f"{series}-{order}-{depth}"
            imgs = extract_large_images(doc, page)
            if not imgs:
                unmatched.append(f"{pdf_path.name} p.{i} no large images stem={stem}")
                continue
            for png in imgs:
                idx = per_stem_count[stem]
                per_stem_count[stem] = idx + 1
                write_imageset(stem, idx, png)
                matched += 1
        doc.close()

    print(f"Wrote {matched} images across {len(per_stem_count)} skills.")
    print(f"Output: {ASSETS_OUT}")
    if unmatched:
        print(f"\n{len(unmatched)} unmatched pages:")
        for u in unmatched:
            print("  -", u)
    else:
        print("All pages mapped to a skill.")


if __name__ == "__main__":
    main()
