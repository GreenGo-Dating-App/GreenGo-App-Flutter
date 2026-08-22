# -*- coding: utf-8 -*-
"""Regenerate the web/PWA icon set from the shipped store icon.

Single source of truth: assets/icon/app_icon_1024.png, which is byte-for-byte
the artwork in ios/Runner/.../Icon-App-1024x1024@1x.png -- i.e. exactly what
the App Store and Play listings show. Deriving the web icons from it keeps the
home-screen icon identical to the store icon.

"any" icons are straight resizes of that tile.

"maskable" icons are the same tile flattened onto the brand background rather
than the bare mark on black. Android applies its own circle/squircle mask, so
the tile's rounded corners get cropped by the OS and what survives is the tile
interior -- which is what makes the installed icon match the store icon. The
GG mark spans ~63% of the tile, comfortably inside the 80%-diameter safe
circle, and the script asserts that before writing anything.

Usage:
    python tools/gen_web_icons.py
Then re-run tools/version_web_icons.py so the cache-busting hashes match.
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SIBLING = os.path.join(os.path.dirname(REPO), "GreenGo-App-Flutter")

MASTER = os.path.join(SIBLING, "assets", "icon", "app_icon_1024.png")
STORE_REFERENCE = os.path.join(
    SIBLING, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset",
    "Icon-App-1024x1024@1x.png",
)

BRAND_BG = (10, 10, 10, 255)  # #0A0A0A, matches manifest background_color
ANY_SIZES = [120, 152, 180, 192, 512]
MASKABLE_SIZES = [192, 512]
SAFE_RADIUS = 0.40  # maskable guaranteed-visible circle, as a fraction of size
# The mark fills the tile right up to the safe-circle boundary (measured at
# 0.400), so the tile is inset slightly on maskable icons rather than run
# full-bleed. Android's mask then crops brand background instead of artwork.
MASK_TILE_SCALE = 0.88


def mark_extent(tile):
    """Half-diagonal of the gold mark, as a fraction of the tile size."""
    # The mark is everything appreciably brighter than the near-black tile.
    grey = tile.convert("L").point(lambda v: 255 if v > 90 else 0)
    box = grey.getbbox()
    if box is None:
        raise SystemExit("could not locate the mark inside %s" % MASTER)
    left, top, right, bottom = box
    half_w = (right - left) / 2.0
    half_h = (bottom - top) / 2.0
    return ((half_w ** 2 + half_h ** 2) ** 0.5) / tile.width


def main():
    if not os.path.exists(MASTER):
        raise SystemExit("missing master icon: %s" % MASTER)
    tile = Image.open(MASTER).convert("RGBA")

    if os.path.exists(STORE_REFERENCE):
        store = Image.open(STORE_REFERENCE).convert("RGBA")
        same = list(tile.resize((256, 256)).getdata()) == list(
            store.resize((256, 256)).getdata())
        print("store icon match: %s" % ("yes" if same else "NO -- diverged"))

    extent = mark_extent(tile) * MASK_TILE_SCALE
    print("mark half-diagonal on maskable: %.3f of canvas (safe limit %.2f)"
          % (extent, SAFE_RADIUS))
    if extent > SAFE_RADIUS:
        raise SystemExit(
            "mark would be clipped by Android's maskable crop; shrink it first")

    # Flattened, slightly inset tile: no transparent corners for the OS mask to
    # punch through, and the artwork stays inside the guaranteed-visible circle.
    flat = Image.new("RGBA", tile.size, BRAND_BG)
    inner = int(round(tile.width * MASK_TILE_SCALE))
    offset = (tile.width - inner) // 2
    scaled = tile.resize((inner, inner), Image.LANCZOS)
    flat.paste(scaled, (offset, offset), scaled)

    for repo in (REPO, SIBLING):
        icons = os.path.join(repo, "web", "icons")
        if not os.path.isdir(icons):
            print("%s: no web/icons, skipped" % repo)
            continue
        print("\n== %s ==" % os.path.basename(repo))

        for size in ANY_SIZES:
            out = os.path.join(icons, "Icon-%d.png" % size)
            tile.resize((size, size), Image.LANCZOS).save(out, "PNG", optimize=True)
            print("  Icon-%d.png" % size)

        for size in MASKABLE_SIZES:
            out = os.path.join(icons, "Icon-maskable-%d.png" % size)
            flat.resize((size, size), Image.LANCZOS).save(out, "PNG", optimize=True)
            print("  Icon-maskable-%d.png (store tile, flattened)" % size)

        fav = os.path.join(repo, "web", "favicon.png")
        tile.resize((32, 32), Image.LANCZOS).save(fav, "PNG", optimize=True)
        print("  favicon.png (32x32)")

    print("\nOK - web icons regenerated from the store icon")
    return 0


if __name__ == "__main__":
    sys.exit(main())
