from __future__ import annotations

import json
import math
import random
from pathlib import Path
from typing import Callable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


BASE_SIZE = 64
SCALE = 8
EXPORT_SIZE = BASE_SIZE * SCALE
ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "sprite" / "items"
PREVIEW_PATH = OUT_DIR / "_survival_preview.png"
MANIFEST_PATH = OUT_DIR / "survival_icon_manifest.json"

OUTLINE = (10, 22, 40, 255)
CYAN = (61, 231, 255, 255)
CYAN_SOFT = (61, 231, 255, 150)
RED = (255, 82, 82, 255)
RED_SOFT = (255, 82, 82, 150)
GOLD = (255, 185, 70, 255)
PURPLE = (158, 109, 255, 255)
NAVY = (26, 39, 68, 255)
STEEL = (87, 102, 124, 255)
STEEL_LIGHT = (151, 170, 193, 255)
STEEL_DARK = (44, 58, 80, 255)
WOOD = (133, 90, 54, 255)
WOOD_DARK = (94, 58, 34, 255)
WOOD_LIGHT = (180, 129, 83, 255)
CLOTH = (177, 191, 206, 255)
CLOTH_DARK = (99, 113, 134, 255)
LEAF = (78, 171, 129, 255)
LEAF_DARK = (43, 111, 87, 255)
BLOOD = (173, 36, 52, 255)
PARCHMENT = (207, 189, 153, 255)
PARCHMENT_DARK = (143, 124, 93, 255)


def rgba(color: tuple[int, int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return color[0], color[1], color[2], alpha


def new_icon() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (BASE_SIZE, BASE_SIZE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def mirror_points(points: list[tuple[int, int]], center_x: int = 32) -> list[tuple[int, int]]:
    return [(center_x + (center_x - x), y) for x, y in points]


def draw_outline_polygon(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon(points, fill=fill)
    closed = points + [points[0]]
    draw.line(closed, fill=OUTLINE, width=1)


def draw_outline_ellipse(
    draw: ImageDraw.ImageDraw,
    bbox: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] = OUTLINE,
    width: int = 1,
) -> None:
    draw.ellipse(bbox, fill=fill, outline=outline, width=width)


def draw_outline_rect(
    draw: ImageDraw.ImageDraw,
    bbox: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] = OUTLINE,
    width: int = 1,
    radius: int = 0,
) -> None:
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)


def draw_glow_pixels(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: tuple[int, int, int, int]) -> None:
    for x, y in points:
        draw.point((x, y), fill=color)


def add_signal_trim(draw: ImageDraw.ImageDraw, bbox: tuple[int, int, int, int], color: tuple[int, int, int, int] = CYAN) -> None:
    left, top, right, bottom = bbox
    for x in range(left + 1, right, 3):
        draw.point((x, top + 1), fill=color)
    for y in range(top + 1, bottom, 3):
        draw.point((right - 1, y), fill=color)


def add_glitch_sparks(draw: ImageDraw.ImageDraw, seed: int, count: int = 10) -> None:
    rng = random.Random(seed)
    for i in range(count):
        x = rng.randint(10, 54)
        y = rng.randint(8, 54)
        color = CYAN_SOFT if i % 3 else RED_SOFT
        draw.point((x, y), fill=color)
        if rng.random() < 0.35:
            draw.point((min(63, x + 1), y), fill=color)


def upscale_pixel_art(image: Image.Image) -> Image.Image:
    enlarged = image.resize((EXPORT_SIZE, EXPORT_SIZE), Image.Resampling.NEAREST)
    glow = enlarged.filter(ImageFilter.GaussianBlur(radius=2))
    glow_mask = Image.new("RGBA", glow.size, (0, 0, 0, 0))
    glow_mask.alpha_composite(glow)
    return Image.alpha_composite(glow_mask, enlarged)


def save_icon(image: Image.Image, item_id: str) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    export = upscale_pixel_art(image)
    path = OUT_DIR / f"{item_id}.png"
    export.save(path)
    return path


def draw_bible(draw: ImageDraw.ImageDraw) -> None:
    cover = [(17, 17), (39, 12), (48, 17), (48, 45), (26, 50), (17, 45)]
    pages = [(22, 16), (42, 12), (50, 16), (50, 44), (30, 48), (22, 44)]
    draw_outline_polygon(draw, pages, PARCHMENT)
    draw_outline_polygon(draw, cover, NAVY)
    draw.line([(23, 17), (23, 44)], fill=STEEL_LIGHT, width=1)
    draw.line([(29, 15), (37, 13)], fill=STEEL_LIGHT, width=1)
    draw_outline_rect(draw, (29, 22, 37, 39), fill=STEEL_DARK, outline=STEEL_LIGHT)
    draw.line([(33, 24), (33, 37)], fill=CYAN, width=1)
    draw.line([(30, 30), (36, 30)], fill=CYAN, width=1)
    draw_outline_rect(draw, (17, 24, 23, 38), fill=BLOOD, outline=OUTLINE)
    add_signal_trim(draw, (17, 17, 48, 45))


def draw_herb(draw: ImageDraw.ImageDraw) -> None:
    stems = [(31, 18), (28, 46), (35, 47), (36, 18)]
    draw_outline_polygon(draw, stems, WOOD_LIGHT)
    leaves_left = [(19, 20), (26, 18), (30, 23), (25, 28), (18, 27)]
    leaves_mid = [(25, 10), (33, 7), (38, 13), (33, 20), (26, 18)]
    leaves_right = [(34, 20), (42, 18), (47, 24), (42, 30), (35, 29)]
    leaves_low = [(22, 28), (30, 27), (32, 34), (26, 39), (20, 35)]
    for leaf in [leaves_left, leaves_mid, leaves_right, leaves_low]:
        draw_outline_polygon(draw, leaf, LEAF)
    draw.line([(24, 21), (29, 24)], fill=LEAF_DARK, width=1)
    draw.line([(29, 10), (32, 18)], fill=LEAF_DARK, width=1)
    draw.line([(38, 21), (37, 28)], fill=LEAF_DARK, width=1)
    draw.line([(24, 31), (30, 33)], fill=LEAF_DARK, width=1)
    draw_outline_rect(draw, (26, 37, 38, 43), fill=BLOOD, outline=OUTLINE, radius=1)
    draw.line([(27, 40), (37, 40)], fill=CYAN, width=1)


def draw_mirror(draw: ImageDraw.ImageDraw) -> None:
    draw_outline_rect(draw, (29, 38, 36, 52), fill=WOOD_LIGHT, outline=OUTLINE, radius=2)
    draw_outline_ellipse(draw, (18, 12, 48, 42), fill=STEEL)
    draw_outline_ellipse(draw, (22, 16, 44, 38), fill=(88, 145, 179, 255), outline=STEEL_LIGHT)
    draw.line([(24, 18), (39, 33)], fill=CYAN, width=1)
    draw.line([(31, 18), (28, 25)], fill=CYAN_SOFT, width=1)
    draw.line([(34, 26), (41, 22)], fill=CYAN_SOFT, width=1)
    draw_outline_rect(draw, (30, 42, 35, 57), fill=WOOD_DARK, outline=OUTLINE)
    draw_glow_pixels(draw, [(20, 20), (43, 26), (36, 19), (25, 35)], CYAN_SOFT)


def draw_bandage(draw: ImageDraw.ImageDraw) -> None:
    body = [(17, 37), (26, 22), (44, 17), (50, 24), (42, 41), (23, 47)]
    draw_outline_polygon(draw, body, CLOTH)
    for offset in [0, 6, 12]:
        draw.line([(19 + offset, 40 - offset // 2), (31 + offset, 21 - offset // 2)], fill=CLOTH_DARK, width=1)
    draw_outline_rect(draw, (31, 24, 43, 36), fill=rgba(BLOOD, 220), outline=OUTLINE, radius=2)
    draw.point((35, 28), fill=RED)
    draw.point((39, 31), fill=RED_SOFT)
    draw_glow_pixels(draw, [(24, 25), (46, 24), (27, 44)], CYAN_SOFT)


def draw_shield(draw: ImageDraw.ImageDraw) -> None:
    draw_outline_ellipse(draw, (16, 12, 48, 47), fill=WOOD)
    draw_outline_ellipse(draw, (19, 15, 45, 44), fill=WOOD_LIGHT, outline=WOOD_DARK)
    draw.line([(32, 16), (32, 43)], fill=WOOD_DARK, width=1)
    draw.line([(21, 20), (43, 38)], fill=WOOD_DARK, width=1)
    draw.line([(43, 20), (21, 38)], fill=WOOD_DARK, width=1)
    draw_outline_ellipse(draw, (27, 23, 37, 33), fill=STEEL)
    draw.point((32, 28), fill=CYAN)
    add_signal_trim(draw, (18, 14, 46, 43), CYAN_SOFT)


def draw_beads(draw: ImageDraw.ImageDraw) -> None:
    centers = [(24, 19), (31, 16), (39, 18), (44, 24), (45, 33), (40, 39), (32, 42), (24, 40), (19, 33), (18, 25)]
    for x, y in centers:
        draw_outline_ellipse(draw, (x - 3, y - 3, x + 3, y + 3), fill=STEEL)
    draw.line([(31, 42), (31, 48)], fill=BLOOD, width=1)
    draw.line([(34, 42), (34, 48)], fill=CYAN, width=1)
    draw.line([(31, 48), (29, 54)], fill=BLOOD, width=1)
    draw.line([(34, 48), (36, 54)], fill=CYAN, width=1)
    draw_glow_pixels(draw, [(39, 17), (44, 24), (24, 40)], CYAN_SOFT)


def draw_boots(draw: ImageDraw.ImageDraw) -> None:
    back = [(18, 17), (32, 17), (37, 24), (36, 37), (44, 37), (47, 45), (33, 45), (30, 49), (19, 49), (18, 41)]
    front = [(27, 13), (40, 13), (46, 20), (45, 34), (52, 34), (55, 43), (41, 43), (38, 47), (28, 47), (27, 37)]
    draw_outline_polygon(draw, back, STEEL_DARK)
    draw_outline_polygon(draw, front, STEEL)
    for x in [31, 35, 39]:
        draw.line([(x, 20), (x + 2, 20)], fill=STEEL_LIGHT, width=1)
    draw.line([(37, 17), (41, 17)], fill=CYAN, width=1)
    draw.line([(41, 24), (47, 24)], fill=CYAN_SOFT, width=1)
    draw.line([(31, 39), (43, 39)], fill=OUTLINE, width=1)


def draw_robe(draw: ImageDraw.ImageDraw) -> None:
    robe = [(21, 12), (31, 15), (34, 15), (43, 12), (48, 24), (44, 50), (34, 45), (30, 51), (20, 47), (16, 24)]
    draw_outline_polygon(draw, robe, CLOTH_DARK)
    inner = [(25, 16), (31, 20), (34, 20), (39, 16), (42, 24), (39, 45), (33, 42), (31, 46), (24, 44), (21, 24)]
    draw_outline_polygon(draw, inner, CLOTH)
    draw.line([(31, 21), (28, 32)], fill=BLOOD, width=1)
    draw.line([(34, 21), (37, 32)], fill=BLOOD, width=1)
    draw_outline_ellipse(draw, (27, 28, 37, 38), fill=STEEL)
    draw.line([(32, 30), (32, 36)], fill=CYAN, width=1)
    draw.line([(29, 33), (35, 33)], fill=CYAN, width=1)
    add_signal_trim(draw, (20, 14, 44, 46))


def draw_chalice_mercy(draw: ImageDraw.ImageDraw) -> None:
    cup = [(24, 18), (40, 18), (44, 24), (37, 31), (27, 31), (20, 24)]
    stem = [(29, 31), (35, 31), (36, 40), (28, 40)]
    base = [(25, 40), (39, 40), (43, 45), (21, 45)]
    for poly, fill in [(cup, GOLD), (stem, STEEL), (base, STEEL_DARK)]:
        draw_outline_polygon(draw, poly, fill)
    draw_outline_ellipse(draw, (27, 20, 37, 28), fill=rgba(CYAN, 190), outline=CYAN)
    draw_outline_ellipse(draw, (28, 9, 36, 17), fill=rgba(BLOOD, 220), outline=OUTLINE)
    draw.point((32, 13), fill=CYAN)
    draw.line([(25, 45), (21, 52)], fill=CYAN_SOFT, width=1)
    draw.line([(39, 45), (43, 52)], fill=RED_SOFT, width=1)
    draw_glow_pixels(draw, [(23, 25), (40, 24), (32, 20)], CYAN_SOFT)


def draw_stake(draw: ImageDraw.ImageDraw) -> None:
    wood = [(28, 10), (37, 10), (42, 20), (36, 51), (29, 51), (23, 20)]
    draw_outline_polygon(draw, wood, WOOD)
    draw.line([(31, 13), (34, 48)], fill=WOOD_LIGHT, width=1)
    for y in [22, 30, 38]:
        draw_outline_rect(draw, (23, y, 42, y + 4), fill=STEEL_DARK, outline=OUTLINE)
        draw.point((27, y + 2), fill=RED_SOFT)
        draw.point((37, y + 1), fill=CYAN_SOFT)
    draw.line([(28, 10), (33, 4)], fill=OUTLINE, width=1)
    draw.line([(37, 10), (31, 4)], fill=OUTLINE, width=1)


def draw_temperance(draw: ImageDraw.ImageDraw) -> None:
    bowl = [(20, 16), (44, 16), (48, 25), (41, 35), (23, 35), (16, 25)]
    stem = [(28, 35), (36, 35), (38, 45), (26, 45)]
    base = [(22, 45), (42, 45), (46, 51), (18, 51)]
    draw_outline_polygon(draw, bowl, GOLD)
    draw_outline_polygon(draw, stem, STEEL)
    draw_outline_polygon(draw, base, NAVY)
    liquid = [(24, 19), (40, 19), (42, 24), (39, 29), (25, 29), (22, 24)]
    draw_outline_polygon(draw, liquid, rgba(CYAN, 210))
    draw.line([(25, 23), (39, 23)], fill=CYAN, width=1)
    draw.line([(24, 47), (40, 47)], fill=PURPLE, width=1)
    draw_glow_pixels(draw, [(20, 24), (43, 24), (32, 19), (28, 42), (36, 42)], CYAN_SOFT)


def draw_moon_veil(draw: ImageDraw.ImageDraw) -> None:
    draw_outline_ellipse(draw, (15, 11, 42, 38), fill=STEEL_LIGHT)
    draw_outline_ellipse(draw, (23, 14, 45, 36), fill=(0, 0, 0, 0), outline=(0, 0, 0, 0))
    draw.ellipse((23, 14, 45, 36), fill=(0, 0, 0, 0))
    veil = [(30, 24), (45, 17), (49, 25), (43, 42), (48, 53), (36, 50), (24, 56), (20, 42), (25, 30)]
    draw_outline_polygon(draw, veil, rgba(PURPLE, 220))
    draw.line([(28, 32), (42, 26)], fill=CYAN, width=1)
    draw.line([(27, 43), (40, 38)], fill=CYAN_SOFT, width=1)
    draw_glow_pixels(draw, [(22, 18), (39, 15), (46, 26), (34, 52)], CYAN_SOFT)


def draw_tree(draw: ImageDraw.ImageDraw) -> None:
    orb = [(16, 42), (48, 42), (44, 52), (20, 52)]
    draw_outline_polygon(draw, orb, STEEL_DARK)
    draw_outline_rect(draw, (18, 44, 46, 53), fill=STEEL_DARK, outline=STEEL_LIGHT, radius=4)
    trunk = [(29, 24), (35, 24), (36, 43), (28, 43)]
    draw_outline_polygon(draw, trunk, WOOD)
    left = [(21, 23), (29, 15), (33, 22), (28, 30), (20, 29)]
    top = [(28, 12), (37, 7), (44, 14), (38, 24), (30, 21)]
    right = [(36, 20), (46, 18), (51, 28), (43, 35), (34, 31)]
    for poly in [left, top, right]:
        draw_outline_polygon(draw, poly, LEAF)
    draw.line([(30, 43), (24, 49)], fill=WOOD_DARK, width=1)
    draw.line([(34, 43), (40, 49)], fill=WOOD_DARK, width=1)
    draw.line([(23, 24), (29, 24)], fill=CYAN_SOFT, width=1)
    draw.line([(37, 15), (40, 21)], fill=CYAN_SOFT, width=1)
    draw_glow_pixels(draw, [(25, 16), (39, 11), (46, 24), (31, 48)], CYAN_SOFT)


def draw_world_omni(draw: ImageDraw.ImageDraw) -> None:
    draw_outline_ellipse(draw, (15, 12, 49, 46), fill=STEEL_DARK)
    draw_outline_ellipse(draw, (19, 16, 45, 42), fill=NAVY, outline=STEEL_LIGHT)
    draw.line([(22, 29), (42, 29)], fill=CYAN, width=1)
    draw.line([(32, 17), (32, 41)], fill=CYAN, width=1)
    draw.arc((21, 18, 43, 40), start=35, end=145, fill=CYAN_SOFT, width=1)
    draw.arc((22, 19, 42, 39), start=215, end=325, fill=CYAN_SOFT, width=1)
    ring = [(11, 26), (16, 22), (48, 22), (53, 26), (53, 32), (48, 36), (16, 36), (11, 32)]
    draw_outline_polygon(draw, ring, rgba(GOLD, 210))
    crest = [(26, 30), (38, 30), (41, 37), (32, 45), (23, 37)]
    draw_outline_polygon(draw, crest, rgba(PURPLE, 220))
    draw.line([(32, 32), (32, 41)], fill=GOLD, width=1)
    draw.line([(27, 36), (37, 36)], fill=GOLD, width=1)
    for x, y in [(17, 24), (47, 24), (17, 34), (47, 34), (32, 14), (32, 44)]:
        draw.point((x, y), fill=RED if (x + y) % 2 else CYAN)


DRAWERS: dict[str, Callable[[ImageDraw.ImageDraw], None]] = {
    "item_bible_old": draw_bible,
    "item_herb_dry": draw_herb,
    "item_mirror_crude": draw_mirror,
    "item_bandage_bloody": draw_bandage,
    "item_shield_wood": draw_shield,
    "item_beads_meditation": draw_beads,
    "item_boots_iron": draw_boots,
    "item_pope_robe": draw_robe,
    "item_priestess_mercy": draw_chalice_mercy,
    "item_stake_tough": draw_stake,
    "item_temperance_sacrament": draw_temperance,
    "item_moon_veil": draw_moon_veil,
    "item_world_tree_sapling": draw_tree,
    "item_world_omni": draw_world_omni,
}


ITEMS: list[dict[str, str]] = [
    {
        "item_id": "item_bible_old",
        "name": "破旧的圣经",
        "rarity": "common",
        "prompt": "single old book relic, armor cue, pixel-art item icon, centered, transparent background, dark navy cover, cyan signal glow, restrained red accent, readable silhouette",
    },
    {
        "item_id": "item_herb_dry",
        "name": "干燥草药",
        "rarity": "common",
        "prompt": "single dried herb bundle, healing and sustain cue, pixel-art item icon, centered, transparent background, retro occult palette, readable silhouette",
    },
    {
        "item_id": "item_mirror_crude",
        "name": "粗制护心镜",
        "rarity": "common",
        "prompt": "single crude heart-guard mirror, armor and dodge cue, pixel-art item icon, centered, transparent background, steel and cyan reflection",
    },
    {
        "item_id": "item_bandage_bloody",
        "name": "带血绷带",
        "rarity": "common",
        "prompt": "single bloody bandage, lifesteal sustain cue, pixel-art item icon, centered, transparent background, cloth with warning red stains",
    },
    {
        "item_id": "item_shield_wood",
        "name": "木制圆盾",
        "rarity": "common",
        "prompt": "single wooden round shield, dodge and defense cue, pixel-art item icon, centered, transparent background, wood grain and cyan trim",
    },
    {
        "item_id": "item_beads_meditation",
        "name": "冥想念珠",
        "rarity": "common",
        "prompt": "single meditation bead loop, healing regeneration cue, pixel-art item icon, centered, transparent background, prayer bead silhouette",
    },
    {
        "item_id": "item_boots_iron",
        "name": "沉重铁靴",
        "rarity": "common",
        "prompt": "single heavy iron boots, armor cue, pixel-art item icon, centered, transparent background, dark steel plating, readable silhouette",
    },
    {
        "item_id": "item_pope_robe",
        "name": "教皇法袍",
        "rarity": "rare",
        "prompt": "single ceremonial robe relic, armor plus vitality cue, pixel-art item icon, centered, transparent background, layered cloth and cyan emblem",
    },
    {
        "item_id": "item_priestess_mercy",
        "name": "女祭司慈悲",
        "rarity": "rare",
        "prompt": "single mercy chalice relic, lifesteal and regeneration cue, pixel-art item icon, centered, transparent background, holy vessel with cyan and red highlights",
    },
    {
        "item_id": "item_stake_tough",
        "name": "坚韧木桩",
        "rarity": "rare",
        "prompt": "single reinforced wooden stake, max health cue, pixel-art item icon, centered, transparent background, bound bands and readable silhouette",
    },
    {
        "item_id": "item_temperance_sacrament",
        "name": "节制圣餐",
        "rarity": "epic",
        "prompt": "single ornate sacrament chalice, strong regeneration cue, pixel-art item icon, centered, transparent background, premium metal and cyan liquid glow",
    },
    {
        "item_id": "item_moon_veil",
        "name": "月之纱幔",
        "rarity": "epic",
        "prompt": "single moon veil relic, dodge and vitality cue, pixel-art item icon, centered, transparent background, crescent motif with cyan and purple cloth",
    },
    {
        "item_id": "item_world_tree_sapling",
        "name": "世界树幼苗",
        "rarity": "epic",
        "prompt": "single world tree sapling relic, massive vitality cue, pixel-art item icon, centered, transparent background, sacred young tree with cyan life sparks",
    },
    {
        "item_id": "item_world_omni",
        "name": "世界·全知全能",
        "rarity": "legendary",
        "prompt": "single omniscient world orb relic, ultimate survival cue, pixel-art item icon, centered, transparent background, layered gold ring, cyan world core, powerful silhouette",
    },
]


def build_icon(item: dict[str, str]) -> Image.Image:
    image, draw = new_icon()
    drawer = DRAWERS[item["item_id"]]
    drawer(draw)
    add_glitch_sparks(draw, sum(ord(ch) for ch in item["item_id"]), count=12)
    return image


def build_preview(paths: list[Path], manifest: list[dict[str, str]]) -> None:
    cell = 280
    label_h = 52
    columns = 4
    rows = math.ceil(len(paths) / columns)
    preview = Image.new("RGBA", (columns * cell, rows * (cell + label_h)), (10, 16, 25, 255))
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default()

    for idx, (path, item) in enumerate(zip(paths, manifest)):
        icon = Image.open(path).convert("RGBA")
        x = (idx % columns) * cell
        y = (idx // columns) * (cell + label_h)
        draw.rounded_rectangle((x + 12, y + 12, x + cell - 12, y + cell - 12), radius=12, fill=(33, 53, 72, 255))
        preview.alpha_composite(icon.resize((224, 224), Image.Resampling.NEAREST), (x + 28, y + 24))
        draw.text((x + 16, y + cell + 8), item["item_id"], fill=(224, 230, 237, 255), font=font)
        draw.text((x + 16, y + cell + 26), f"{item['name']} / {item['rarity']}", fill=(125, 200, 220, 255), font=font)

    preview.save(PREVIEW_PATH)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    manifest_rows: list[dict[str, str]] = []
    for item in ITEMS:
        image = build_icon(item)
        path = save_icon(image, item["item_id"])
        paths.append(path)
        manifest_rows.append(
            {
                "item_id": item["item_id"],
                "name": item["name"],
                "rarity": item["rarity"],
                "size": f"{EXPORT_SIZE}x{EXPORT_SIZE}",
                "prompt": item["prompt"],
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
            }
        )

    MANIFEST_PATH.write_text(json.dumps(manifest_rows, ensure_ascii=False, indent=2), encoding="utf-8")
    build_preview(paths, manifest_rows)
    print(f"generated {len(paths)} survival icons into {OUT_DIR}")


if __name__ == "__main__":
    main()
