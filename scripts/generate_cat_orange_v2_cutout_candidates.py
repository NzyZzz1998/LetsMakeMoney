from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
V1_ROOT = ROOT / "assets" / "pets" / "cat_orange_v1" / "frames"
V2_ROOT = ROOT / "assets" / "pets" / "cat" / "orange_v2"
MANIFEST_PATH = V2_ROOT / "asset-manifest.json"

CANVAS_SIZE = (256, 256)


ANIMATION_SPECS = {
    "idle": {"source": "idle", "count": 4, "overlay": "idle"},
    "working": {"source": "working", "count": 6, "overlay": "working"},
    "resting": {"source": "resting", "count": 4, "overlay": "resting"},
    "clicked_hold": {"source": "clicked_hold", "count": 4, "overlay": "hold"},
    "idle_clicked_single": {"source": "idle_clicked_single", "count": 3, "overlay": "idle_single"},
    "idle_clicked_double": {"source": "idle_clicked_double", "count": 4, "overlay": "idle_double"},
    "working_clicked_single": {"source": "working_clicked_single", "count": 3, "overlay": "working_single"},
    "working_clicked_double": {"source": "working_clicked_double", "count": 4, "overlay": "working_double"},
    "resting_clicked_single": {"source": "resting_clicked_single", "count": 3, "overlay": "resting_single"},
    "resting_clicked_double": {"source": "resting_clicked_double", "count": 4, "overlay": "resting_double"},
}


def main() -> None:
    if not V1_ROOT.exists():
        raise SystemExit(f"Missing v1 source root: {V1_ROOT}")
    if not MANIFEST_PATH.exists():
        raise SystemExit(f"Missing v2 manifest: {MANIFEST_PATH}")

    for animation, spec in ANIMATION_SPECS.items():
        source_frames = _load_source_frames(spec["source"])
        target_dir = V2_ROOT / animation
        target_dir.mkdir(parents=True, exist_ok=True)
        for old_file in target_dir.glob("*.png"):
            old_file.unlink()

        for index in range(spec["count"]):
            frame = source_frames[index % len(source_frames)].copy()
            frame = _normalize(frame)
            frame = _apply_micro_motion(frame, index, spec["count"], spec["overlay"])
            frame = _apply_overlay(frame, spec["overlay"], index, spec["count"])
            output = target_dir / f"cat_orange_v2_{animation}_{index:02d}.png"
            frame.save(output)
            print(output.relative_to(ROOT))

    _update_manifest()


def _load_source_frames(source_name: str) -> list[Image.Image]:
    source_dir = V1_ROOT / source_name
    paths = sorted(source_dir.glob("*.png"))
    if not paths:
        raise SystemExit(f"Missing source frames for {source_name}: {source_dir}")
    return [Image.open(path).convert("RGBA") for path in paths]


def _normalize(frame: Image.Image) -> Image.Image:
    if frame.size != CANVAS_SIZE:
        frame = frame.resize(CANVAS_SIZE, Image.Resampling.LANCZOS)

    alpha = frame.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))

    # Keep the existing 256px canvas contract, but center frames that arrive with
    # accidental transparent offset. This keeps generated v2 candidates stable.
    left, top, right, bottom = bbox
    width = right - left
    height = bottom - top
    current_center = ((left + right) // 2, (top + bottom) // 2)
    target_center = (128, 134)
    dx = target_center[0] - current_center[0]
    dy = target_center[1] - current_center[1]

    if abs(dx) <= 2 and abs(dy) <= 2:
        return frame

    normalized = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    crop = frame.crop(bbox)
    paste_x = max(0, min(CANVAS_SIZE[0] - width, left + dx))
    paste_y = max(0, min(CANVAS_SIZE[1] - height, top + dy))
    normalized.alpha_composite(crop, (paste_x, paste_y))
    return normalized


def _apply_micro_motion(frame: Image.Image, index: int, count: int, overlay: str) -> Image.Image:
    offsets = {
        "idle": [(0, 0), (0, -1), (0, 0), (0, 1)],
        "working": [(0, 0), (1, 0), (0, -1), (-1, 0), (0, 1), (1, -1)],
        "resting": [(0, 1), (0, 0), (0, 1), (0, 0)],
        "hold": [(0, 2), (0, 3), (0, 2), (0, 3)],
    }
    key = "idle"
    if "working" in overlay:
        key = "working"
    elif "resting" in overlay:
        key = "resting"
    elif "hold" in overlay:
        key = "hold"

    dx, dy = offsets[key][index % len(offsets[key])]
    moved = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    moved.alpha_composite(frame, (dx, dy))

    if "double" in overlay:
        return ImageEnhance.Brightness(moved).enhance(1.03 if index % 2 == 0 else 1.0)
    return moved


def _apply_overlay(frame: Image.Image, overlay: str, index: int, count: int) -> Image.Image:
    result = frame.copy()
    draw = ImageDraw.Draw(result, "RGBA")

    if "working" in overlay:
        _draw_laptop(draw, index)
        _draw_coins(draw, index, emphatic="double" in overlay)
    if "resting" in overlay:
        _draw_rest_symbols(draw, index, emphatic="double" in overlay)
    if overlay == "hold":
        _draw_hold_squish(draw, index)
    if overlay.endswith("single"):
        _draw_click_spark(draw, index, double=False)
    if overlay.endswith("double"):
        _draw_click_spark(draw, index, double=True)
    if overlay == "idle":
        _draw_soft_shadow(draw)

    return result


def _draw_laptop(draw: ImageDraw.ImageDraw, index: int) -> None:
    screen_y = 164 + (index % 2)
    draw.rounded_rectangle((72, screen_y, 184, screen_y + 45), radius=8, fill=(76, 93, 116, 232), outline=(45, 53, 66, 230), width=3)
    draw.rounded_rectangle((83, screen_y + 8, 173, screen_y + 34), radius=5, fill=(156, 214, 219, 235))
    draw.rectangle((91, screen_y + 38, 165, screen_y + 42), fill=(45, 53, 66, 220))
    keyboard_y = screen_y + 45
    draw.rounded_rectangle((54, keyboard_y, 202, keyboard_y + 23), radius=7, fill=(43, 48, 58, 235), outline=(30, 35, 44, 230), width=2)
    for i in range(7):
        key_x = 70 + i * 17
        shade = 210 if (i + index) % 2 == 0 else 170
        draw.rounded_rectangle((key_x, keyboard_y + 8, key_x + 10, keyboard_y + 13), radius=2, fill=(shade, shade, shade, 190))


def _draw_coins(draw: ImageDraw.ImageDraw, index: int, emphatic: bool) -> None:
    positions = [(194, 146), (210, 162), (199, 181)]
    if emphatic:
        positions.append((221, 145 + (index % 2) * 4))
    for pos_index, (x, y) in enumerate(positions):
        y += -2 if (index + pos_index) % 2 == 0 else 2
        draw.ellipse((x, y, x + 16, y + 16), fill=(255, 200, 71, 238), outline=(196, 126, 26, 235), width=2)
        draw.arc((x + 4, y + 4, x + 12, y + 13), start=60, end=300, fill=(166, 103, 17, 190), width=1)


def _draw_rest_symbols(draw: ImageDraw.ImageDraw, index: int, emphatic: bool) -> None:
    x = 188 + (index % 2) * 2
    y = 54 - (index % 2) * 2
    draw.text((x, y), "Z", fill=(91, 105, 132, 220))
    draw.text((x + 15, y - 11), "z", fill=(91, 105, 132, 185))
    if emphatic:
        draw.text((x + 28, y - 21), "z", fill=(91, 105, 132, 150))
    draw.arc((53, 181, 203, 225), start=8, end=172, fill=(247, 178, 92, 120), width=3)


def _draw_hold_squish(draw: ImageDraw.ImageDraw, index: int) -> None:
    y = 214 + (index % 2)
    draw.rounded_rectangle((79, y, 177, y + 13), radius=7, fill=(255, 183, 92, 130))
    draw.arc((81, 196, 175, 226), start=12, end=168, fill=(104, 47, 19, 150), width=3)


def _draw_click_spark(draw: ImageDraw.ImageDraw, index: int, double: bool) -> None:
    alpha = 230 if index % 2 == 0 else 150
    stars = [(59, 75), (199, 86)]
    if double:
        stars.extend([(47, 111), (213, 119)])
    for x, y in stars:
        _draw_star(draw, x + (index % 2), y - (index % 2), 7 if double else 5, alpha)


def _draw_star(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, alpha: int) -> None:
    fill = (255, 213, 82, alpha)
    outline = (191, 116, 21, min(alpha + 10, 255))
    points = [
        (x, y - size),
        (x + 2, y - 2),
        (x + size, y),
        (x + 2, y + 2),
        (x, y + size),
        (x - 2, y + 2),
        (x - size, y),
        (x - 2, y - 2),
    ]
    draw.polygon(points, fill=fill, outline=outline)


def _draw_soft_shadow(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse((77, 218, 179, 232), fill=(94, 51, 21, 32))


def _update_manifest() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    for animation, spec in ANIMATION_SPECS.items():
        manifest["animations"][animation]["status"] = "generated_cutout_candidate"
        manifest["animations"][animation]["actual_frames"] = spec["count"]
        manifest["animations"][animation]["generator"] = "scripts/generate_cat_orange_v2_cutout_candidates.py"

    batch_id = "20260704-cutout-v1-derived"
    batches = manifest.setdefault("batches", [])
    batches = [batch for batch in batches if batch.get("id") != batch_id]
    batches.append(
        {
            "id": batch_id,
            "tool": "Pillow deterministic cutout fallback",
            "source": "assets/pets/cat_orange_v1/frames",
            "status": "generated",
            "notes": "Derived v2 candidate frames from v1 orange cat, adding working props, rest symbols, click sparks, and minimum frame counts.",
        }
    )
    manifest["batches"] = batches
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
