#!/usr/bin/env python3

from collections import deque
from pathlib import Path
import shutil
import subprocess
import sys

from PIL import Image, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE = PROJECT_ROOT / "Design" / "AppIconSource.png"
MASTER = PROJECT_ROOT / "Design" / "AppIconMaster.png"
APP_ICON_SET = (
    PROJECT_ROOT
    / "StudyBlock"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
)
ICONSET = PROJECT_ROOT / ".build" / "StudyBlock.iconset"
ICNS = PROJECT_ROOT / "StudyBlock" / "Resources" / "StudyBlock.icns"

ICON_FILES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}


def connected_background_mask(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    background = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def looks_like_background(x: int, y: int) -> bool:
        red, green, blue = pixels[x, y]
        return min(red, green, blue) > 244 and max(red, green, blue) - min(
            red, green, blue
        ) <= 10

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not background[index] and looks_like_background(x, y):
            background[index] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    alpha = Image.new("L", (width, height), 255)
    alpha.putdata([0 if value else 255 for value in background])
    return alpha.filter(ImageFilter.GaussianBlur(radius=0.55))


def create_master() -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    source.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    origin = ((1024 - source.width) // 2, (1024 - source.height) // 2)
    canvas.alpha_composite(source, origin)
    alpha = connected_background_mask(canvas)
    canvas.putalpha(alpha)
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(MASTER, optimize=True)
    return canvas


def render_sizes(master: Image.Image) -> None:
    APP_ICON_SET.mkdir(parents=True, exist_ok=True)
    ICONSET.mkdir(parents=True, exist_ok=True)
    for filename, pixels in ICON_FILES.items():
        rendered = master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        rendered.save(APP_ICON_SET / filename, optimize=True)
        rendered.save(ICONSET / filename, optimize=True)


def create_icns() -> None:
    ICNS.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["iconutil", "-c", "icns", str(ICONSET), "-o", str(ICNS)],
        check=True,
    )


def main() -> int:
    if not SOURCE.exists():
        print(f"Missing source artwork: {SOURCE}", file=sys.stderr)
        return 1
    shutil.rmtree(ICONSET, ignore_errors=True)
    master = create_master()
    render_sizes(master)
    create_icns()
    print(f"Created {MASTER}")
    print(f"Created {APP_ICON_SET}")
    print(f"Created {ICNS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
