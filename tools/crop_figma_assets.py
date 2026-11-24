from __future__ import annotations

import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "DesignAssets"
ASSETS = ROOT / "JYH" / "Assets.xcassets"
SCALE = 4
BORROW_TAB_CANVAS = (128, 124)
BORROW_TAB_ASSETS = {
    "figma-tab-borrow",
    "figma-tab-borrow-selected",
}


ASSET_SPECS = [
    ("figma-logo", "figma-login@4x.png", (31, 103, 42, 42), "flood"),
    ("figma-login-phone-icon", "figma-login@4x.png", (61, 350, 17, 24), "flood"),
    ("figma-login-code-icon", "figma-login@4x.png", (59, 409, 22, 25), "flood"),
    ("figma-login-checkbox", "figma-login@4x.png", (43, 473, 21, 21), "flood"),
    ("figma-login-shield", "figma-login@4x.png", (114, 768, 23, 17), "flood"),
    ("figma-home-header-profile", "figma-home@4x.png", (341, 62, 34, 32), "bright"),
    ("figma-home-step-1", "figma-home@4x.png", (65, 475, 36, 36), "flood"),
    ("figma-home-step-2", "figma-home@4x.png", (177, 475, 36, 36), "flood"),
    ("figma-home-step-3", "figma-home@4x.png", (289, 475, 36, 36), "flood"),
    ("figma-home-support", "figma-home@4x.png", (42, 594, 32, 32), "flood"),
    ("figma-home-benefit-art", "figma-home@4x.png", (269, 655, 102, 88), "keep"),
    ("figma-home-guide-icon-1", "figma-home@4x.png", (122, 816, 32, 33), "flood"),
    ("figma-home-guide-icon-2", "figma-home@4x.png", (291, 816, 32, 33), "flood"),
    ("figma-home-guide-icon-3", "figma-home@4x.png", (122, 879, 34, 33), "flood"),
    ("figma-home-guide-icon-4", "figma-home@4x.png", (292, 875, 32, 36), "flood"),
    ("figma-tab-borrow-selected", "figma-home@4x.png", (48, 1022, 32, 31), "flood"),
    ("figma-tab-borrow", "figma-repayment@4x.png", (43, 814, 36, 31), "flood"),
    ("figma-tab-repay", "figma-home@4x.png", (178, 1022, 33, 31), "flood"),
    ("figma-tab-repay-selected", "figma-repayment@4x.png", (176, 814, 34, 31), "flood"),
    ("figma-tab-profile", "figma-home@4x.png", (309, 1022, 34, 31), "flood"),
    ("figma-tab-profile-selected", "figma-profile@4x.png", (309, 758, 34, 31), "flood"),
    ("figma-profile-avatar", "figma-profile@4x.png", (32, 83, 62, 62), "keep"),
    ("figma-profile-settings", "figma-profile@4x.png", (326, 65, 52, 44), "flood"),
    ("figma-profile-action-1", "figma-profile@4x.png", (42, 320, 46, 46), "flood"),
    ("figma-profile-action-2", "figma-profile@4x.png", (129, 320, 46, 46), "flood"),
    ("figma-profile-action-3", "figma-profile@4x.png", (216, 320, 46, 46), "flood"),
    ("figma-profile-action-4", "figma-profile@4x.png", (303, 320, 46, 46), "flood"),
    ("figma-repayment-support", "figma-repayment@4x.png", (42, 517, 32, 32), "flood"),
    ("figma-back", "figma-verification@4x.png", (17, 62, 20, 18), "flood"),
    ("figma-notice", "figma-verification@4x.png", (16, 107, 25, 15), "flood"),
    ("figma-id-front-upload", "figma-verification@4x.png", (33, 264, 151, 129), "keep"),
    ("figma-id-back-upload", "figma-verification@4x.png", (206, 264, 151, 129), "keep"),
    ("figma-bank-card-art", "figma-bank-card@4x.png", (95, 266, 200, 114), "keep"),
    ("figma-qr-alipay", "figma-bank-card@4x.png", (32, 763, 157, 137), "keep"),
    ("figma-qr-wechat", "figma-bank-card@4x.png", (201, 763, 157, 137), "keep"),
]


def flood_transparent(image: Image.Image, tolerance: int = 10) -> Image.Image:
    rgba = image.convert("RGBA")
    array = np.asarray(rgba).copy()
    height, width = array.shape[:2]
    seeds = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    reference = np.median(np.array([rgba.getpixel(seed)[:3] for seed in seeds]), axis=0)
    visited = np.zeros((height, width), dtype=bool)
    queue = deque(seeds)
    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= width or y < 0 or y >= height or visited[y, x]:
            continue
        visited[y, x] = True
        pixel = array[y, x, :3]
        if np.max(np.abs(pixel.astype(np.int16) - reference.astype(np.int16))) > tolerance:
            continue
        array[y, x, 3] = 0
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    return Image.fromarray(array, "RGBA")


def keep_bright_pixels(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    array = np.asarray(rgba).copy()
    minimum = array[:, :, :3].min(axis=2).astype(np.float32)
    alpha = np.clip((minimum - 115) / 110, 0, 1)
    array[:, :, 3] = (alpha * array[:, :, 3]).astype(np.uint8)
    return Image.fromarray(array, "RGBA")


def normalize_icon_canvas(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Icon crop contains no visible pixels")
    content = image.crop(bbox)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    position = (
        (size[0] - content.width) // 2,
        (size[1] - content.height) // 2,
    )
    canvas.alpha_composite(content, position)
    return canvas


def add_asset(name: str, source_name: str, box: tuple[int, int, int, int], mode: str) -> None:
    source = Image.open(SOURCE / source_name).convert("RGBA")
    x, y, width, height = box
    crop = source.crop((x * SCALE, y * SCALE, (x + width) * SCALE, (y + height) * SCALE))
    if mode == "flood":
        crop = flood_transparent(crop)
    elif mode == "bright":
        crop = keep_bright_pixels(crop)
    if name in BORROW_TAB_ASSETS:
        crop = normalize_icon_canvas(crop, BORROW_TAB_CANVAS)

    image_set = ASSETS / f"{name}.imageset"
    image_set.mkdir(parents=True, exist_ok=True)
    crop.save(image_set / f"{name}.png", optimize=True)
    contents = {
        "images": [
            {
                "filename": f"{name}.png",
                "idiom": "universal",
                "scale": "1x",
            }
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (image_set / "Contents.json").write_text(
        json.dumps(contents, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    for spec in ASSET_SPECS:
        add_asset(*spec)
    print(f"Exported {len(ASSET_SPECS)} Figma assets to {ASSETS}")


if __name__ == "__main__":
    main()
