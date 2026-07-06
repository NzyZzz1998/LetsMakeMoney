from __future__ import annotations

import json
from pathlib import Path

from collections import deque

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
V2_ROOT = ROOT / "assets" / "pets" / "cat" / "orange_v2"
MANIFEST_PATH = V2_ROOT / "asset-manifest.json"
DEFAULT_CONCEPT = V2_ROOT / "_review" / "imagegen_concept_sheet_20260704.png"
CLICK_ACTION_CONCEPT = V2_ROOT / "_review" / "imagegen_click_actions_20260704.png"
IDLE_CLICK_SEQUENCE = V2_ROOT / "_review" / "imagegen_idle_click_sequence_20260704.png"
IDLE_SLIM_REFERENCE = V2_ROOT / "_review" / "user_idle_slim_reference_20260704.png"
IDLE_SINGLE_CLICK_FRAMES = V2_ROOT / "_review" / "user_idle_single_click_frames_20260704.png"
CONTACT_SHEET = V2_ROOT / "_review" / "imagegen_candidate_contact_sheet.png"

CANVAS_SIZE = (256, 256)
CONTACT_CELL_SIZE = (128, 128)


POSE_CROPS = {
    "idle": (40, 55, 505, 465),
    "working": (510, 80, 990, 475),
    "resting": (1015, 105, 1470, 455),
    "clicked_hold": (1015, 510, 1485, 940),
}


CLICK_ACTION_CROPS = {
    "idle_clicked_single": (55, 505, 505, 925),
    "working_clicked_single": (500, 45, 1035, 470),
    "resting_clicked_single": (1010, 60, 1510, 445),
    "idle_clicked_double": (35, 500, 510, 980),
    "working_clicked_double": (505, 500, 1040, 980),
    "resting_clicked_double": (1030, 505, 1520, 985),
}


ANIMATION_SPECS = {
    "idle": {"pose": "idle", "count": 4, "loop": True, "motion": "breathe"},
    "working": {"pose": "working", "count": 6, "loop": True, "motion": "type"},
    "resting": {"pose": "resting", "count": 4, "loop": True, "motion": "sleep"},
    "clicked_hold": {"pose": "clicked_hold", "count": 4, "loop": True, "motion": "hold"},
    "idle_clicked_single": {"pose": "idle_clicked_single", "count": 4, "loop": False, "motion": "sequence"},
    "idle_clicked_double": {"pose": "idle_clicked_double", "count": 5, "loop": False, "motion": "sequence"},
    "working_clicked_single": {"pose": "working_clicked_single", "base_pose": "working", "count": 3, "loop": False, "motion": "short_single_action"},
    "working_clicked_double": {"pose": "working_clicked_double", "base_pose": "working", "count": 4, "loop": False, "motion": "short_double_action"},
    "resting_clicked_single": {"pose": "resting_clicked_single", "base_pose": "resting", "count": 3, "loop": False, "motion": "short_single_action"},
    "resting_clicked_double": {"pose": "resting_clicked_double", "base_pose": "resting", "count": 4, "loop": False, "motion": "short_double_action"},
}


def main() -> None:
    concept_path = DEFAULT_CONCEPT
    if not concept_path.exists():
        raise SystemExit(f"Missing concept sheet: {concept_path}")
    if not CLICK_ACTION_CONCEPT.exists():
        raise SystemExit(f"Missing click action concept sheet: {CLICK_ACTION_CONCEPT}")
    if not IDLE_CLICK_SEQUENCE.exists():
        raise SystemExit(f"Missing idle click sequence sheet: {IDLE_CLICK_SEQUENCE}")
    if not IDLE_SINGLE_CLICK_FRAMES.exists():
        raise SystemExit(f"Missing idle single click sheet: {IDLE_SINGLE_CLICK_FRAMES}")
    if not MANIFEST_PATH.exists():
        raise SystemExit(f"Missing v2 manifest: {MANIFEST_PATH}")

    concept = Image.open(concept_path).convert("RGBA")
    click_concept = Image.open(CLICK_ACTION_CONCEPT).convert("RGBA")
    idle_sequence = Image.open(IDLE_CLICK_SEQUENCE).convert("RGBA")
    idle_single_click_frames = Image.open(IDLE_SINGLE_CLICK_FRAMES).convert("RGBA")
    poses = {name: _prepare_pose(concept.crop(box)) for name, box in POSE_CROPS.items()}
    if IDLE_SLIM_REFERENCE.exists():
        poses["idle"] = _prepare_pose(Image.open(IDLE_SLIM_REFERENCE).convert("RGBA"))
    poses.update({name: _prepare_pose(click_concept.crop(box)) for name, box in CLICK_ACTION_CROPS.items()})
    clean_single_prepare = _prepare_replacement_pose(idle_single_click_frames, 0)
    clean_single_wave = _prepare_replacement_pose(idle_single_click_frames, 1)
    clean_double_fourth = _prepare_history_double_fourth_frame(idle_sequence)
    poses["idle_clicked_single"] = _build_idle_single_sequence(
        poses["idle"],
        clean_single_prepare,
        clean_single_wave,
    )
    poses["idle_clicked_double"] = _build_idle_double_sequence(poses["idle"], idle_sequence, clean_double_fourth)

    for animation, spec in ANIMATION_SPECS.items():
        target_dir = V2_ROOT / animation
        target_dir.mkdir(parents=True, exist_ok=True)
        for old_file in target_dir.glob("*.png"):
            old_file.unlink()

        for index in range(spec["count"]):
            pose = poses[spec["pose"]]
            if spec["motion"] == "sequence":
                frame = pose[index].copy()
            else:
                base_pose = poses.get(spec.get("base_pose", spec["pose"]))
                frame = _apply_motion(pose, spec["motion"], index, spec["count"], base_pose)
            output = target_dir / f"cat_orange_v2_{animation}_{index:02d}.png"
            frame.save(output)
            print(output.relative_to(ROOT))

    _write_contact_sheet()
    _update_manifest()


def _prepare_grid_sequence(image: Image.Image, row: int, columns: int, rows: int, selected_columns: list[int]) -> list[Image.Image]:
    cell_width = image.width / columns
    cell_height = image.height / rows
    frames = []
    for column in selected_columns:
        left = round(column * cell_width)
        top = round(row * cell_height)
        right = round((column + 1) * cell_width)
        bottom = round((row + 1) * cell_height)
        frames.append(_prepare_pose(_remove_edge_fragments(image.crop((left, top, right, bottom)))))
    return frames


def _grid_pose(image: Image.Image, row: int, column: int) -> Image.Image:
    return _prepare_grid_sequence(image, row=row, columns=7, rows=2, selected_columns=[column])[0]


def _prepare_replacement_pose(image: Image.Image, column: int) -> Image.Image:
    cell_width = image.width / 2
    crop = image.crop((round(column * cell_width), 0, round((column + 1) * cell_width), image.height))
    return _prepare_chroma_pose(crop)


def _prepare_history_double_fourth_frame(source: Image.Image) -> Image.Image:
    columns = 7
    rows = 2
    cell_width = source.width / columns
    cell_height = source.height / rows
    left = round(4 * cell_width)
    top = round(1 * cell_height)
    right = round(5 * cell_width + 50)
    bottom = round(2 * cell_height)
    crop = source.crop((left, top, min(source.width, right), bottom))
    frame = _prepare_pose(_remove_edge_fragments(crop))
    frame = _clear_edge_strips(frame, left=54, right=18)
    return _remove_right_side_fragments(frame)


def _remove_right_side_fragments(image: Image.Image) -> Image.Image:
    result = image.copy()
    pixels = result.load()
    visited: set[tuple[int, int]] = set()
    for y in range(CANVAS_SIZE[1]):
        for x in range(CANVAS_SIZE[0]):
            if (x, y) in visited or pixels[x, y][3] == 0:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited.add((x, y))
            points = []
            min_x = max_x = x
            while queue:
                px, py = queue.popleft()
                points.append((px, py))
                min_x = min(min_x, px)
                max_x = max(max_x, px)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if nx < 0 or ny < 0 or nx >= CANVAS_SIZE[0] or ny >= CANVAS_SIZE[1]:
                        continue
                    if (nx, ny) in visited or pixels[nx, ny][3] == 0:
                        continue
                    visited.add((nx, ny))
                    queue.append((nx, ny))
            if min_x > 212 and len(points) < 2200:
                for px, py in points:
                    r, g, b, _a = pixels[px, py]
                    pixels[px, py] = (r, g, b, 0)
    return result


def _prepare_chroma_pose(crop: Image.Image) -> Image.Image:
    crop = _green_to_alpha(crop)
    crop = _remove_edge_fragments(crop)
    crop = _remove_soft_bottom_shadow(crop)
    bbox = crop.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))

    content = crop.crop(bbox)
    scale = min(218 / content.width, 218 / content.height)
    new_size = (max(1, round(content.width * scale)), max(1, round(content.height * scale)))
    content = content.resize(new_size, Image.Resampling.LANCZOS)

    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - content.width) // 2
    y = 18 + (218 - content.height) // 2
    result.alpha_composite(content, (x, y))
    return result


def _build_idle_single_sequence(
    neutral: Image.Image,
    clean_prepare_pose: Image.Image,
    clean_wave_pose: Image.Image,
) -> list[Image.Image]:
    clean_prepare = _align_to_reference(
        clean_prepare_pose,
        neutral,
        height_ratio=1.02,
        min_width_ratio=0.98,
        bottom_offset=0,
    )
    clean_wave = _align_to_reference(
        clean_wave_pose,
        neutral,
        height_ratio=1.02,
        min_width_ratio=0.98,
        bottom_offset=0,
    )
    return [
        neutral.copy(),
        clean_prepare,
        clean_wave,
        neutral.copy(),
    ]


def _build_idle_double_sequence(neutral: Image.Image, source: Image.Image, clean_fourth_pose: Image.Image) -> list[Image.Image]:
    crouch = _align_to_reference(
        _grid_pose(source, row=1, column=1),
        neutral,
        height_ratio=0.94,
        min_width_ratio=1.02,
        bottom_offset=0,
    )
    left_jump_source = ImageOps.mirror(_grid_pose(source, row=1, column=2))
    left_jump = _align_to_reference(
        left_jump_source,
        neutral,
        height_ratio=1.1,
        min_width_ratio=0.96,
        center_offset=-14,
        bottom_offset=0,
    )
    left_jump = _restore_missing_jump_tail(left_jump, neutral)
    fourth_frame = _align_to_reference(
        clean_fourth_pose,
        neutral,
        height_ratio=0.96,
        min_width_ratio=0.98,
        bottom_offset=0,
    )
    return [
        neutral.copy(),
        crouch,
        left_jump,
        fourth_frame,
        neutral.copy(),
    ]


def _restore_missing_jump_tail(frame: Image.Image, reference: Image.Image) -> Image.Image:
    frame_bbox = frame.getchannel("A").getbbox()
    reference_bbox = reference.getchannel("A").getbbox()
    if frame_bbox is None or reference_bbox is None:
        return frame.copy()

    result = frame.copy()
    frame_center_x = (frame_bbox[0] + frame_bbox[2]) / 2
    reference_center_x = (reference_bbox[0] + reference_bbox[2]) / 2
    dx = round(frame_center_x - reference_center_x - 10)
    dy = round(frame_bbox[3] - reference_bbox[3] - 2)

    tail_mask = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(tail_mask)
    draw.rectangle((176, 66, CANVAS_SIZE[0], 218), fill=255)
    shifted_reference = _offset_image(reference, dx, dy)
    tail_alpha = ImageChops.multiply(shifted_reference.getchannel("A"), tail_mask)
    tail_layer = shifted_reference.copy()
    tail_layer.putalpha(tail_alpha)

    result_pixels = result.load()
    tail_pixels = tail_layer.load()
    for y in range(CANVAS_SIZE[1]):
        for x in range(176, CANVAS_SIZE[0]):
            tr, tg, tb, ta = tail_pixels[x, y]
            if ta == 0:
                continue
            rr, rg, rb, ra = result_pixels[x, y]
            if ra < 24 or x > 218:
                result_pixels[x, y] = (tr, tg, tb, ta)
    return result


def _make_clean_landing_frame(neutral: Image.Image) -> Image.Image:
    frame = _transform_about_bottom(neutral, 1.08, 0.88, 0)
    draw = ImageDraw.Draw(frame)
    motion_color = (104, 55, 28, 210)
    draw.arc((66, 74, 104, 106), 12, 168, fill=motion_color, width=4)
    draw.arc((152, 74, 190, 106), 12, 168, fill=motion_color, width=4)
    return frame


def _restore_tail_from_reference(frame: Image.Image, reference: Image.Image) -> Image.Image:
    result = frame.copy()
    tail_mask = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(tail_mask)
    draw.rectangle((222, 82, CANVAS_SIZE[0], 204), fill=255)
    tail_alpha = ImageChops.multiply(reference.getchannel("A"), tail_mask)
    tail_layer = reference.copy()
    tail_layer.putalpha(tail_alpha)
    result.alpha_composite(tail_layer)
    return result


def _make_clean_single_wave_frame(neutral: Image.Image, raised_paw: Image.Image) -> Image.Image:
    wave = _clear_edge_strips(
        _align_to_reference(
            raised_paw,
            neutral,
            height_ratio=1.0,
            min_width_ratio=0.98,
            bottom_offset=0,
        ),
        left=46,
    )
    wave = _remove_sparkles(wave)
    _draw_single_wave_marks(wave)
    return wave


def _replace_lower_body(upper: Image.Image, lower: Image.Image, split_y: int) -> Image.Image:
    upper_mask = Image.new("L", CANVAS_SIZE, 0)
    upper_draw = ImageDraw.Draw(upper_mask)
    upper_draw.rectangle((0, 0, CANVAS_SIZE[0], split_y), fill=255)
    upper_alpha = ImageChops.multiply(upper.getchannel("A"), upper_mask)
    upper_layer = upper.copy()
    upper_layer.putalpha(upper_alpha)

    lower_mask = Image.new("L", CANVAS_SIZE, 0)
    lower_draw = ImageDraw.Draw(lower_mask)
    lower_draw.rectangle((0, split_y - 8, CANVAS_SIZE[0], CANVAS_SIZE[1]), fill=255)
    lower_alpha = ImageChops.multiply(lower.getchannel("A"), lower_mask)
    lower_layer = lower.copy()
    lower_layer.putalpha(lower_alpha)

    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    result.alpha_composite(lower_layer)
    result.alpha_composite(upper_layer)
    return result


def _remove_sparkles(image: Image.Image) -> Image.Image:
    result = image.copy()
    pixels = result.load()
    for y in range(CANVAS_SIZE[1]):
        for x in range(CANVAS_SIZE[0]):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            is_yellow_spark = r > 210 and 130 <= g <= 230 and b < 95
            if is_yellow_spark and (x < 84 or x > 196 or y < 88):
                pixels[x, y] = (r, g, b, 0)
    return result


def _draw_single_wave_marks(frame: Image.Image) -> None:
    draw = ImageDraw.Draw(frame)
    mark_color = (104, 55, 28, 230)
    accent_color = (255, 159, 31, 220)
    marks = [
        ((58, 74), (42, 64)),
        ((54, 94), (36, 92)),
        ((62, 112), (46, 120)),
    ]
    for start, end in marks:
        draw.line((*start, *end), fill=mark_color, width=3)
        mid_x = (start[0] + end[0]) // 2
        mid_y = (start[1] + end[1]) // 2
        draw.ellipse((mid_x - 2, mid_y - 2, mid_x + 2, mid_y + 2), fill=accent_color)


def _repair_single_wave_frame(neutral: Image.Image, broken_wave: Image.Image) -> Image.Image:
    wave = _align_to_reference(
        broken_wave,
        neutral,
        height_ratio=1.0,
        min_width_ratio=0.98,
        bottom_offset=0,
    )
    wave_mask = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(wave_mask)
    draw.rectangle((0, 0, CANVAS_SIZE[0], 158), fill=255)
    draw.rectangle((0, 0, 118, 184), fill=255)
    wave_alpha = ImageChops.multiply(wave.getchannel("A"), wave_mask)
    wave_overlay = wave.copy()
    wave_overlay.putalpha(wave_alpha)

    neutral_mask = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(neutral_mask)
    draw.rectangle((0, 146, CANVAS_SIZE[0], CANVAS_SIZE[1]), fill=255)
    neutral_alpha = ImageChops.multiply(neutral.getchannel("A"), neutral_mask)
    neutral_lower = neutral.copy()
    neutral_lower.putalpha(neutral_alpha)

    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    result.alpha_composite(neutral_lower)
    result.alpha_composite(wave_overlay)
    return result


def _clear_edge_strips(image: Image.Image, left: int = 0, right: int = 0) -> Image.Image:
    result = image.copy()
    draw = ImageDraw.Draw(result)
    if left > 0:
        draw.rectangle((0, 0, left - 1, CANVAS_SIZE[1]), fill=(0, 0, 0, 0))
    if right > 0:
        draw.rectangle((CANVAS_SIZE[0] - right, 0, CANVAS_SIZE[0], CANVAS_SIZE[1]), fill=(0, 0, 0, 0))
    return result


def _align_to_reference(
    source: Image.Image,
    reference: Image.Image,
    height_ratio: float = 1.0,
    min_width_ratio: float = 0.0,
    center_offset: int = 0,
    bottom_offset: int = 0,
) -> Image.Image:
    source_bbox = source.getchannel("A").getbbox()
    reference_bbox = reference.getchannel("A").getbbox()
    if source_bbox is None or reference_bbox is None:
        return source.copy()

    content = source.crop(source_bbox)
    reference_height = reference_bbox[3] - reference_bbox[1]
    reference_width = reference_bbox[2] - reference_bbox[0]
    target_height = max(1, round(reference_height * height_ratio))
    scale = target_height / max(1, content.height)
    new_size = (max(1, round(content.width * scale)), max(1, round(content.height * scale)))
    if min_width_ratio > 0.0:
        new_size = (max(new_size[0], round(reference_width * min_width_ratio)), new_size[1])
    if new_size[0] > CANVAS_SIZE[0] - 10:
        width_scale = (CANVAS_SIZE[0] - 10) / new_size[0]
        new_size = (max(1, round(new_size[0] * width_scale)), max(1, round(new_size[1] * width_scale)))
    if new_size[1] > CANVAS_SIZE[1] - 10:
        height_scale = (CANVAS_SIZE[1] - 10) / new_size[1]
        new_size = (max(1, round(new_size[0] * height_scale)), max(1, round(new_size[1] * height_scale)))

    content = content.resize(new_size, Image.Resampling.LANCZOS)
    reference_center_x = (reference_bbox[0] + reference_bbox[2]) / 2 + center_offset
    reference_bottom = reference_bbox[3]
    x = round(reference_center_x - content.width / 2)
    y = round(reference_bottom + bottom_offset - content.height)
    x = max(0, min(CANVAS_SIZE[0] - content.width, x))
    y = max(0, min(CANVAS_SIZE[1] - content.height, y))

    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    result.alpha_composite(content, (x, y))
    return result


def _prepare_pose(crop: Image.Image) -> Image.Image:
    crop = _white_to_alpha(crop)
    crop = _remove_soft_bottom_shadow(crop)
    bbox = crop.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))

    content = crop.crop(bbox)
    scale = min(218 / content.width, 218 / content.height)
    new_size = (max(1, round(content.width * scale)), max(1, round(content.height * scale)))
    content = content.resize(new_size, Image.Resampling.LANCZOS)

    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - content.width) // 2
    y = 18 + (218 - content.height) // 2
    result.alpha_composite(content, (x, y))
    return result


def _green_to_alpha(image: Image.Image) -> Image.Image:
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            is_green_key = g > 150 and g > r * 1.35 and g > b * 1.35
            if is_green_key:
                pixels[x, y] = (r, g, b, 0)
    return image


def _white_to_alpha(image: Image.Image) -> Image.Image:
    """Remove only the connected white background, preserving white fur."""
    pixels = image.load()
    width, height = image.size
    visited = set()
    queue: deque[tuple[int, int]] = deque()

    def is_background(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a > 0 and r > 205 and g > 205 and b > 205 and max(r, g, b) - min(r, g, b) < 26

    for x in range(width):
        if is_background(x, 0):
            queue.append((x, 0))
        if is_background(x, height - 1):
            queue.append((x, height - 1))
    for y in range(height):
        if is_background(0, y):
            queue.append((0, y))
        if is_background(width - 1, y):
            queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or not is_background(x, y):
            continue
        visited.add((x, y))
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        if x > 0:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    return image


def _remove_soft_bottom_shadow(image: Image.Image) -> Image.Image:
    pixels = image.load()
    start_y = int(image.height * 0.62)
    for y in range(start_y, image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            is_shadow = (
                165 <= r <= 245
                and 130 <= g <= 225
                and 95 <= b <= 210
                and r >= g >= b
                and (r - g) <= 70
                and (g - b) <= 70
            )
            if is_shadow:
                pixels[x, y] = (r, g, b, 0)
    return image


def _remove_edge_fragments(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image

    # Keep the central sprite and nearby marks, but drop thin fragments inherited
    # from neighboring grid cells.
    center_x = image.width / 2
    center_y = image.height / 2
    max_distance = max(image.width, image.height) * 0.42
    pixels = image.load()
    visited: set[tuple[int, int]] = set()
    components: list[dict] = []

    for y in range(image.height):
        for x in range(image.width):
            if (x, y) in visited or pixels[x, y][3] == 0:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited.add((x, y))
            count = 0
            min_x = max_x = x
            min_y = max_y = y
            points = []
            while queue:
                px, py = queue.popleft()
                points.append((px, py))
                count += 1
                min_x = min(min_x, px)
                max_x = max(max_x, px)
                min_y = min(min_y, py)
                max_y = max(max_y, py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if nx < 0 or ny < 0 or nx >= image.width or ny >= image.height:
                        continue
                    if (nx, ny) in visited or pixels[nx, ny][3] == 0:
                        continue
                    visited.add((nx, ny))
                    queue.append((nx, ny))
            components.append(
                {
                    "count": count,
                    "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                    "points": points,
                }
            )

    if not components:
        return image
    largest = max(component["count"] for component in components)
    for component in components:
        min_x, min_y, max_x, max_y = component["bbox"]
        component_center_x = (min_x + max_x) / 2
        component_center_y = (min_y + max_y) / 2
        distance = ((component_center_x - center_x) ** 2 + (component_center_y - center_y) ** 2) ** 0.5
        touches_edge = min_x <= 2 or min_y <= 2 or max_x >= image.width - 2 or max_y >= image.height - 2
        if touches_edge and component["count"] < largest * 0.2:
            keep = False
        else:
            keep = component["count"] > largest * 0.015 or (distance < max_distance and not touches_edge)
        if keep:
            continue
        for px, py in component["points"]:
            r, g, b, _a = pixels[px, py]
            pixels[px, py] = (r, g, b, 0)
    return image


def _apply_motion(base: Image.Image, motion: str, index: int, count: int, neutral: Image.Image | None = None) -> Image.Image:
    neutral = neutral or base
    if motion == "single_action":
        return _single_action_frame(neutral, base, index)
    if motion == "double_action":
        return _double_action_frame(neutral, base, index)
    if motion == "short_single_action":
        return _short_single_action_frame(neutral, base, index)
    if motion == "short_double_action":
        return _short_double_action_frame(neutral, base, index)

    offsets = {
        "breathe": [(0, 0), (0, -1), (0, 0), (0, 1)],
        "type": [(0, 0), (1, 0), (0, -1), (-1, 0), (0, 1), (1, -1)],
        "sleep": [(0, 1), (0, 0), (0, 1), (0, 0)],
        "hold": [(0, 0), (0, 1), (0, 0), (0, 1)],
        "pop": [(0, 0), (0, -8), (0, 2)],
        "spark": [(0, 0), (0, -10), (0, 3), (0, -5)],
    }
    scales = {
        "pop": [1.0, 1.12, 0.98],
        "spark": [1.0, 1.15, 0.96, 1.08],
    }
    dx, dy = offsets[motion][index % len(offsets[motion])]
    frame = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    variant = base
    if motion in scales:
        variant = _scale_about_bottom(base, scales[motion][index % len(scales[motion])])
    if motion in {"pop", "spark"} and index % 2 == 1:
        variant = ImageEnhance.Brightness(variant).enhance(1.07)
    frame.alpha_composite(variant, (dx, dy))
    if motion == "pop":
        _draw_single_click_marks(frame, index)
    if motion == "spark":
        _draw_double_click_sparks(frame, index)
    return frame


def _single_action_frame(neutral: Image.Image, action: Image.Image, index: int) -> Image.Image:
    sequence = [
        ("neutral", neutral, 1.0, 1.0, 0, 0, 0),
        ("anticipation", neutral, 1.05, 0.93, 0, 9, -2),
        ("action_start", action, 1.04, 0.98, 0, -2, -1),
        ("action_peak", action, 1.14, 1.08, 0, -12, 2),
        ("recover", neutral, 1.0, 1.0, 0, 0, 0),
    ]
    phase, source, sx, sy, dx, dy, angle = sequence[min(index, len(sequence) - 1)]
    frame = _offset_image(_transform_about_bottom(source, sx, sy, angle), dx, dy)
    if phase.startswith("action"):
        _draw_single_click_marks(frame, index)
    return frame


def _short_single_action_frame(neutral: Image.Image, action: Image.Image, index: int) -> Image.Image:
    if index == 0:
        return neutral.copy()
    if index == 1:
        frame = _scale_about_bottom(action, 1.03)
        _draw_single_click_marks(frame, index)
        return frame
    return neutral.copy()


def _double_action_frame(neutral: Image.Image, action: Image.Image, index: int) -> Image.Image:
    sequence = [
        ("neutral", neutral, 1.0, 1.0, 0, 0, 0),
        ("anticipation", neutral, 1.08, 0.9, 0, 12, 0),
        ("takeoff", action, 1.06, 0.98, 0, -2, -3),
        ("first_peak", action, 1.22, 1.13, 0, -17, 3),
        ("landing", action, 1.08, 0.94, 0, 3, -2),
        ("second_peak", action, 1.17, 1.07, 0, -10, 2),
        ("recover", neutral, 1.0, 1.0, 0, 0, 0),
    ]
    phase, source, sx, sy, dx, dy, angle = sequence[min(index, len(sequence) - 1)]
    frame = _offset_image(_transform_about_bottom(source, sx, sy, angle), dx, dy)
    if phase not in {"neutral", "anticipation", "recover"}:
        _draw_double_click_sparks(frame, index)
    return frame


def _short_double_action_frame(neutral: Image.Image, action: Image.Image, index: int) -> Image.Image:
    if index == 0:
        return neutral.copy()
    if index == 3:
        return neutral.copy()
    scale = 1.08 if index == 1 else 1.02
    frame = _scale_about_bottom(action, scale)
    _draw_double_click_sparks(frame, index)
    return frame


def _offset_image(image: Image.Image, dx: int, dy: int) -> Image.Image:
    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    result.alpha_composite(image, (dx, dy))
    return result


def _scale_about_bottom(image: Image.Image, scale: float) -> Image.Image:
    return _transform_about_bottom(image, scale, scale, 0)


def _transform_about_bottom(image: Image.Image, scale_x: float, scale_y: float, angle_degrees: float) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image.copy()

    content = image.crop(bbox)
    new_size = (max(1, round(content.width * scale_x)), max(1, round(content.height * scale_y)))
    content = content.resize(new_size, Image.Resampling.LANCZOS)
    if angle_degrees:
        content = content.rotate(angle_degrees, resample=Image.Resampling.BICUBIC, expand=True)

    old_center_x = (bbox[0] + bbox[2]) // 2
    old_bottom = bbox[3]
    x = round(old_center_x - content.width / 2)
    y = round(old_bottom - content.height)
    x = max(0, min(CANVAS_SIZE[0] - content.width, x))
    y = max(0, min(CANVAS_SIZE[1] - content.height, y))

    result = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    result.alpha_composite(content, (x, y))
    return result


def _draw_single_click_marks(frame: Image.Image, index: int) -> None:
    if index == 0:
        return
    draw = ImageDraw.Draw(frame)
    mark_color = (104, 55, 28, 230)
    accent_color = (255, 159, 31, 220)
    mark_sets = [
        [],
        [((34, 92), (18, 86)), ((38, 110), (22, 112)), ((218, 92), (236, 86)), ((214, 110), (232, 112))],
        [((40, 98), (26, 96)), ((216, 98), (230, 96))],
    ]
    for start, end in mark_sets[index % len(mark_sets)]:
        draw.line((*start, *end), fill=mark_color, width=3)
        mid_x = (start[0] + end[0]) // 2
        mid_y = (start[1] + end[1]) // 2
        draw.ellipse((mid_x - 2, mid_y - 2, mid_x + 2, mid_y + 2), fill=accent_color)


def _draw_double_click_sparks(frame: Image.Image, index: int) -> None:
    draw = ImageDraw.Draw(frame)
    sparkle_color = (255, 211, 54, 245)
    outline_color = (255, 122, 0, 230)
    spark_sets = [
        [(36, 70, 9), (214, 68, 8), (228, 128, 6)],
        [(28, 88, 8), (220, 82, 11), (198, 42, 7), (232, 112, 6)],
        [(44, 62, 8), (208, 96, 8), (226, 56, 6), (34, 124, 5)],
        [(34, 78, 7), (218, 68, 9), (204, 126, 7), (230, 96, 5)],
    ]
    for x, y, radius in spark_sets[index % len(spark_sets)]:
        draw.line((x, y - radius, x, y + radius), fill=outline_color, width=3)
        draw.line((x - radius, y, x + radius, y), fill=outline_color, width=3)
        draw.line((x, y - radius + 2, x, y + radius - 2), fill=sparkle_color, width=2)
        draw.line((x - radius + 2, y, x + radius - 2, y), fill=sparkle_color, width=2)


def _write_contact_sheet() -> None:
    rows = []
    max_columns = max(spec["count"] for spec in ANIMATION_SPECS.values())
    label_height = 24
    width = max_columns * CONTACT_CELL_SIZE[0]
    height = sum(label_height + CONTACT_CELL_SIZE[1] for _ in ANIMATION_SPECS)
    sheet = Image.new("RGBA", (width, height), (245, 248, 252, 255))
    draw = ImageDraw.Draw(sheet)

    y = 0
    for animation, spec in ANIMATION_SPECS.items():
        draw.text((6, y + 4), animation, fill=(32, 42, 54, 255))
        y += label_height
        for index in range(spec["count"]):
            frame_path = V2_ROOT / animation / f"cat_orange_v2_{animation}_{index:02d}.png"
            frame = Image.open(frame_path).convert("RGBA")
            frame.thumbnail((116, 116), Image.Resampling.LANCZOS)
            cell_x = index * CONTACT_CELL_SIZE[0]
            draw.rectangle(
                (cell_x, y, cell_x + CONTACT_CELL_SIZE[0] - 1, y + CONTACT_CELL_SIZE[1] - 1),
                outline=(204, 214, 226, 255),
                width=1,
            )
            sheet.alpha_composite(frame, (cell_x + (CONTACT_CELL_SIZE[0] - frame.width) // 2, y + 6))
        rows.append(animation)
        y += CONTACT_CELL_SIZE[1]

    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(CONTACT_SHEET, quality=95)


def _update_manifest() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    for animation, spec in ANIMATION_SPECS.items():
        manifest["animations"][animation]["status"] = "generated_imagegen_concept_candidate"
        manifest["animations"][animation]["actual_frames"] = spec["count"]
        manifest["animations"][animation]["generator"] = "scripts/generate_cat_orange_v2_from_concept_sheet.py"

    batch_id = "20260704-imagegen-concept-derived"
    batches = [batch for batch in manifest.setdefault("batches", []) if batch.get("id") != batch_id]
    batches.append(
        {
            "id": batch_id,
            "tool": "Image generation concept sheet + crop normalization",
            "source": "assets/pets/cat/orange_v2/_review/imagegen_concept_sheet_20260704.png",
            "status": "generated",
            "notes": "Derived the v2 candidate from a base six-pose concept sheet plus dedicated click-action sheets. Idle now uses the user-approved slim neutral reference. Idle single-click uses the user-provided two-frame replacement sheet for frames 2 and 3. Idle double-click is now a five-frame sequence: neutral -> crouch -> mirrored left-jump -> high-resolution historical r1c4 crouch frame -> neutral. Working/resting click extensions use the shorter action-pose feedback from the click-action concept sheet. Background removal uses edge-connected flood fill/chroma-key removal to preserve white fur and remove connected white, pale-gray, or green-screen background pixels.",
        }
    )
    manifest["batches"] = batches
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
