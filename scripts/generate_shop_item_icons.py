from __future__ import annotations

import json
import math
import random
from pathlib import Path
from typing import Callable

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


BASE_SIZE = 64
SCALE = 8
EXPORT_SIZE = BASE_SIZE * SCALE
ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "data" / "balance" / "shop_catalog.json"
OUT_DIR = ROOT / "sprite" / "items"
PREVIEW_PATH = OUT_DIR / "_shop_item_preview.png"
MANIFEST_PATH = OUT_DIR / "shop_item_manifest.json"

OUTLINE = (10, 22, 40, 255)
NAVY = (26, 39, 68, 255)
NAVY_MID = (39, 58, 87, 255)
STEEL = (95, 112, 137, 255)
STEEL_LIGHT = (164, 183, 202, 255)
STEEL_DARK = (53, 68, 90, 255)
WOOD = (137, 94, 57, 255)
WOOD_LIGHT = (185, 135, 88, 255)
WOOD_DARK = (93, 58, 36, 255)
CLOTH = (193, 206, 220, 255)
CLOTH_DARK = (117, 133, 156, 255)
PARCHMENT = (207, 189, 153, 255)
PARCHMENT_DARK = (151, 129, 95, 255)
LEAF = (97, 176, 135, 255)
LEAF_DARK = (45, 111, 86, 255)
GOLD = (255, 188, 72, 255)
GOLD_DARK = (189, 120, 40, 255)
RED = (255, 86, 86, 255)
RED_DARK = (177, 44, 58, 255)
PURPLE = (173, 118, 255, 255)
PURPLE_DARK = (101, 66, 163, 255)
CYAN = (74, 231, 255, 255)
CYAN_SOFT = (74, 231, 255, 150)
GREEN = (111, 212, 120, 255)
GREEN_DARK = (64, 138, 80, 255)
BLACK = (0, 0, 0, 0)


PALETTES = {
    "holy": {"accent": CYAN, "accent_soft": CYAN_SOFT, "base": NAVY, "base2": CLOTH_DARK},
    "economy": {"accent": GOLD, "accent_soft": (255, 188, 72, 150), "base": GOLD_DARK, "base2": WOOD_DARK},
    "cursed": {"accent": PURPLE, "accent_soft": (173, 118, 255, 150), "base": PURPLE_DARK, "base2": RED_DARK},
    "nature": {"accent": GREEN, "accent_soft": (111, 212, 120, 150), "base": LEAF, "base2": LEAF_DARK},
    "martial": {"accent": RED, "accent_soft": (255, 86, 86, 150), "base": STEEL, "base2": STEEL_DARK},
    "cosmic": {"accent": CYAN, "accent_soft": (74, 231, 255, 180), "base": PURPLE, "base2": NAVY},
}


def rgba(rgb: tuple[int, int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return rgb[0], rgb[1], rgb[2], alpha


def new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (BASE_SIZE, BASE_SIZE), BLACK)
    return img, ImageDraw.Draw(img)


def outline_polygon(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon(points, fill=fill)
    draw.line(points + [points[0]], fill=OUTLINE, width=1)


def outline_rect(
    draw: ImageDraw.ImageDraw,
    bbox: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] = OUTLINE,
    radius: int = 0,
) -> None:
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=1)


def outline_ellipse(
    draw: ImageDraw.ImageDraw,
    bbox: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] = OUTLINE,
) -> None:
    draw.ellipse(bbox, fill=fill, outline=outline, width=1)


def add_glitch_sparks(draw: ImageDraw.ImageDraw, seed: int, rarity: str) -> None:
    rng = random.Random(seed)
    count = {"common": 5, "rare": 7, "epic": 10, "legendary": 14}[rarity]
    for i in range(count):
        side = rng.randint(0, 3)
        if side == 0:
            x = rng.randint(10, 54)
            y = rng.randint(8, 14)
        elif side == 1:
            x = rng.randint(44, 56)
            y = rng.randint(14, 50)
        elif side == 2:
            x = rng.randint(10, 54)
            y = rng.randint(48, 56)
        else:
            x = rng.randint(8, 18)
            y = rng.randint(14, 50)
        palette = [CYAN_SOFT, rgba(RED, 170), rgba(PURPLE, 160)]
        c = palette[i % len(palette)]
        draw.point((x, y), fill=c)
        if rng.random() < 0.25:
            draw.point((min(63, x + 1), y), fill=c)


def add_rarity_fx(draw: ImageDraw.ImageDraw, rarity: str, accent: tuple[int, int, int, int]) -> None:
    if rarity == "common":
        return
    if rarity in {"rare", "epic", "legendary"}:
        for x in range(16, 49, 8):
            draw.point((x, 10), fill=accent)
            draw.point((x, 54), fill=rgba(accent, 130))
    if rarity in {"epic", "legendary"}:
        draw.arc((12, 12, 52, 52), start=210, end=330, fill=rgba(accent, 120), width=1)
        draw.arc((16, 14, 48, 50), start=35, end=140, fill=rgba(PURPLE, 150), width=1)
    if rarity == "legendary":
        draw.arc((8, 8, 56, 56), start=20, end=160, fill=rgba(GOLD, 170), width=1)
        draw.arc((8, 8, 56, 56), start=200, end=340, fill=rgba(GOLD, 170), width=1)


def upscale(image: Image.Image) -> Image.Image:
    enlarged = image.resize((EXPORT_SIZE, EXPORT_SIZE), Image.Resampling.NEAREST)
    glow = enlarged.filter(ImageFilter.GaussianBlur(radius=1.6))
    glow = Image.blend(Image.new("RGBA", glow.size, BLACK), glow, 0.18)
    shadow = Image.new("RGBA", enlarged.size, BLACK)
    alpha = enlarged.getchannel("A")
    shadow_mask = alpha.point(lambda a: min(90, int(a * 0.55)))
    shadow.paste((6, 12, 22, 90), (10, 12), shadow_mask)
    base = Image.alpha_composite(shadow, glow)
    return Image.alpha_composite(base, enlarged)


def apply_pixel_bevel(image: Image.Image, accent: tuple[int, int, int, int], rarity: str) -> Image.Image:
    alpha = image.getchannel("A")
    shifted_tl = ImageChops.offset(alpha, 1, 1)
    shifted_br = ImageChops.offset(alpha, -1, -1)
    highlight_mask = ImageChops.subtract(alpha, shifted_tl)
    shadow_mask = ImageChops.subtract(alpha, shifted_br)
    right_mask = ImageChops.subtract(alpha, ImageChops.offset(alpha, -1, 0))

    overlay = Image.new("RGBA", image.size, BLACK)
    highlight_alpha = {"common": 42, "rare": 54, "epic": 62, "legendary": 72}[rarity]
    rim_alpha = {"common": 28, "rare": 38, "epic": 52, "legendary": 64}[rarity]
    shadow_alpha = {"common": 26, "rare": 30, "epic": 36, "legendary": 40}[rarity]
    overlay.paste((245, 250, 255, highlight_alpha), (0, 0), highlight_mask)
    overlay.paste((accent[0], accent[1], accent[2], rim_alpha), (0, 0), right_mask)
    overlay.paste((8, 14, 26, shadow_alpha), (0, 0), shadow_mask)
    return Image.alpha_composite(image, overlay)


def apply_inner_texture(image: Image.Image, accent: tuple[int, int, int, int], seed: int, rarity: str) -> Image.Image:
    rng = random.Random(seed)
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    textured = image.copy()
    draw = ImageDraw.Draw(textured)
    count = {"common": 4, "rare": 6, "epic": 8, "legendary": 10}[rarity]
    for i in range(count):
        x = rng.randint(left + 2, max(left + 2, right - 3))
        y = rng.randint(top + 2, max(top + 2, bottom - 3))
        if alpha.getpixel((x, y)) < 64:
            continue
        color = STEEL_LIGHT if i % 2 == 0 else rgba(accent, 185)
        draw.point((x, y), fill=color)
        if rng.random() < 0.35 and x + 1 < right:
            draw.point((x + 1, y), fill=rgba(color, 140))
    return textured


def save_icon(image: Image.Image, item_id: str) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"{item_id}.png"
    upscale(image).save(path)
    return path


def style(spec: dict) -> dict:
    palette = PALETTES[spec["palette"]]
    return {
        "accent": palette["accent"],
        "accent_soft": palette["accent_soft"],
        "base": palette["base"],
        "base2": palette["base2"],
        "rarity": spec["rarity"],
    }


def t_book(draw: ImageDraw.ImageDraw, s: dict) -> None:
    pages = [(22, 14), (44, 11), (50, 16), (50, 44), (29, 48), (22, 43)]
    cover = [(17, 17), (39, 13), (47, 17), (47, 46), (26, 50), (17, 44)]
    outline_polygon(draw, pages, PARCHMENT)
    outline_polygon(draw, cover, s["base"])
    outline_rect(draw, (28, 22, 38, 39), fill=s["base2"], outline=STEEL_LIGHT)
    draw.line([(33, 24), (33, 37)], fill=s["accent"], width=1)
    draw.line([(30, 30), (36, 30)], fill=s["accent"], width=1)
    outline_rect(draw, (17, 24, 22, 38), fill=RED_DARK, radius=1)


def t_dagger(draw: ImageDraw.ImageDraw, s: dict) -> None:
    blade = [(31, 9), (41, 27), (34, 32), (25, 29), (23, 20)]
    guard = [(23, 28), (41, 28), (39, 33), (25, 33)]
    grip = [(28, 33), (36, 33), (39, 49), (25, 49)]
    pommel = [(27, 49), (37, 49), (35, 55), (29, 55)]
    outline_polygon(draw, blade, STEEL_LIGHT)
    outline_polygon(draw, guard, GOLD_DARK if s["palette_name"] == "economy" else s["base2"])
    outline_polygon(draw, grip, WOOD_DARK)
    outline_polygon(draw, pommel, s["accent"])
    draw.line([(31, 13), (33, 28)], fill=s["accent"], width=1)


def t_lantern(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (24, 18, 40, 42), fill=STEEL_DARK, radius=3)
    outline_rect(draw, (27, 21, 37, 35), fill=rgba(s["accent"], 200), outline=STEEL_LIGHT, radius=2)
    draw.line([(25, 30), (39, 30)], fill=STEEL_LIGHT, width=1)
    draw.line([(32, 10), (27, 18)], fill=OUTLINE, width=1)
    draw.line([(32, 10), (37, 18)], fill=OUTLINE, width=1)
    draw.line([(30, 42), (28, 52)], fill=OUTLINE, width=1)
    draw.line([(34, 42), (36, 52)], fill=OUTLINE, width=1)


def t_herb(draw: ImageDraw.ImageDraw, s: dict) -> None:
    stems = [(31, 18), (29, 47), (35, 47), (36, 18)]
    outline_polygon(draw, stems, WOOD_LIGHT)
    for poly in [
        [(19, 21), (26, 18), (31, 23), (25, 28), (18, 26)],
        [(26, 11), (33, 7), (39, 12), (34, 20), (27, 18)],
        [(35, 21), (43, 19), (48, 25), (42, 31), (35, 29)],
        [(22, 30), (30, 28), (34, 35), (28, 40), (21, 37)],
    ]:
        outline_polygon(draw, poly, LEAF)
    outline_rect(draw, (26, 37, 38, 43), fill=RED_DARK, radius=1)
    draw.line([(27, 40), (37, 40)], fill=s["accent"], width=1)


def t_mirror(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (18, 12, 48, 42), fill=STEEL)
    outline_ellipse(draw, (22, 16, 44, 38), fill=(101, 147, 183, 255), outline=STEEL_LIGHT)
    outline_rect(draw, (30, 42, 35, 56), fill=WOOD_DARK)
    draw.line([(24, 18), (40, 34)], fill=s["accent"], width=1)
    draw.line([(31, 18), (28, 25)], fill=s["accent"], width=1)
    draw.line([(36, 25), (42, 22)], fill=s["accent_soft"], width=1)


def t_bullet(draw: ImageDraw.ImageDraw, s: dict) -> None:
    casing = [(24, 20), (38, 20), (41, 43), (21, 43)]
    tip = [(24, 20), (32, 9), (38, 20)]
    outline_polygon(draw, casing, GOLD_DARK)
    outline_polygon(draw, tip, STEEL_LIGHT)
    draw.line([(24, 26), (38, 26)], fill=OUTLINE, width=1)
    draw.line([(29, 31), (35, 31)], fill=s["accent"], width=1)


def t_whetstone(draw: ImageDraw.ImageDraw, s: dict) -> None:
    stone = [(18, 29), (27, 18), (46, 21), (49, 31), (39, 42), (21, 39)]
    outline_polygon(draw, stone, STEEL)
    outline_rect(draw, (25, 22, 41, 28), fill=STEEL_LIGHT, radius=2)
    draw.line([(23, 35), (40, 26)], fill=s["accent"], width=1)


def t_coin(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (16, 16, 48, 48), fill=GOLD)
    outline_ellipse(draw, (21, 21, 43, 43), fill=rgba(GOLD, 220), outline=GOLD_DARK)
    draw.line([(32, 22), (32, 42)], fill=s["accent"], width=1)
    draw.line([(24, 32), (40, 32)], fill=s["accent_soft"], width=1)


def t_rabbit_foot(draw: ImageDraw.ImageDraw, s: dict) -> None:
    foot = [(24, 18), (35, 12), (43, 20), (42, 32), (33, 44), (23, 40), (19, 28)]
    outline_polygon(draw, foot, CLOTH)
    for bbox in [(20, 20, 25, 25), (17, 23, 22, 28), (18, 28, 23, 33), (21, 32, 26, 37)]:
        outline_ellipse(draw, bbox, CLOTH_DARK)
    draw.line([(29, 16), (32, 36)], fill=s["accent"], width=1)


def t_feather(draw: ImageDraw.ImageDraw, s: dict) -> None:
    feather = [(27, 12), (38, 16), (44, 28), (38, 43), (28, 50), (22, 39), (23, 23)]
    outline_polygon(draw, feather, CLOTH)
    draw.line([(27, 14), (31, 46)], fill=s["accent"], width=1)
    draw.line([(30, 21), (39, 24)], fill=CLOTH_DARK, width=1)
    draw.line([(29, 29), (38, 34)], fill=CLOTH_DARK, width=1)


def t_scroll(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (20, 18, 44, 42), fill=PARCHMENT, outline=OUTLINE, radius=3)
    outline_rect(draw, (17, 20, 23, 40), fill=WOOD_DARK, radius=1)
    outline_rect(draw, (41, 20, 47, 40), fill=WOOD_DARK, radius=1)
    draw.line([(26, 24), (38, 24)], fill=s["accent"], width=1)
    draw.line([(26, 29), (37, 29)], fill=STEEL_DARK, width=1)
    draw.line([(26, 34), (39, 34)], fill=STEEL_DARK, width=1)


def t_lens(draw: ImageDraw.ImageDraw, s: dict) -> None:
    shard = [(20, 30), (29, 14), (43, 19), (47, 32), (35, 48), (22, 43)]
    outline_polygon(draw, shard, STEEL_LIGHT)
    draw.line([(24, 36), (39, 22)], fill=s["accent"], width=1)
    draw.line([(25, 27), (37, 30)], fill=s["accent_soft"], width=1)


def t_bandage(draw: ImageDraw.ImageDraw, s: dict) -> None:
    body = [(17, 37), (26, 22), (44, 17), (50, 24), (42, 41), (23, 47)]
    outline_polygon(draw, body, CLOTH)
    for offset in [0, 6, 12]:
        draw.line([(19 + offset, 40 - offset // 2), (31 + offset, 21 - offset // 2)], fill=CLOTH_DARK, width=1)
    outline_rect(draw, (31, 24, 43, 36), fill=rgba(RED, 220), radius=2)


def t_shield(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (16, 12, 48, 47), fill=WOOD)
    outline_ellipse(draw, (19, 15, 45, 44), fill=WOOD_LIGHT, outline=WOOD_DARK)
    draw.line([(32, 16), (32, 43)], fill=WOOD_DARK, width=1)
    draw.line([(21, 20), (43, 38)], fill=WOOD_DARK, width=1)
    draw.line([(43, 20), (21, 38)], fill=WOOD_DARK, width=1)
    outline_ellipse(draw, (27, 23, 37, 33), fill=STEEL)
    draw.point((32, 28), fill=s["accent"])


def t_beads(draw: ImageDraw.ImageDraw, s: dict) -> None:
    centers = [(24, 19), (31, 16), (39, 18), (44, 24), (45, 33), (40, 39), (32, 42), (24, 40), (19, 33), (18, 25)]
    for x, y in centers:
        outline_ellipse(draw, (x - 3, y - 3, x + 3, y + 3), fill=STEEL)
    draw.line([(31, 42), (31, 48)], fill=RED_DARK, width=1)
    draw.line([(34, 42), (34, 48)], fill=s["accent"], width=1)
    draw.line([(31, 48), (29, 54)], fill=RED_DARK, width=1)
    draw.line([(34, 48), (36, 54)], fill=s["accent"], width=1)


def t_potion(draw: ImageDraw.ImageDraw, s: dict) -> None:
    neck = [(28, 11), (36, 11), (37, 20), (27, 20)]
    body = [(22, 20), (42, 20), (47, 34), (40, 49), (24, 49), (17, 34)]
    outline_polygon(draw, neck, WOOD_DARK)
    outline_polygon(draw, body, STEEL_LIGHT)
    liquid = [(24, 32), (40, 32), (37, 45), (27, 45)]
    outline_polygon(draw, liquid, rgba(s["accent"], 200))
    draw.line([(26, 27), (39, 27)], fill=s["accent_soft"], width=1)


def t_bottle(draw: ImageDraw.ImageDraw, s: dict) -> None:
    neck = [(29, 12), (35, 12), (36, 19), (28, 19)]
    body = [(23, 19), (41, 19), (46, 31), (42, 46), (23, 46), (18, 31)]
    outline_polygon(draw, neck, WOOD_DARK)
    outline_polygon(draw, body, rgba(STEEL_LIGHT, 210))
    label = (25, 28, 39, 36)
    outline_rect(draw, label, fill=PARCHMENT, radius=2)
    draw.line([(28, 32), (36, 32)], fill=s["accent"], width=1)


def t_candle(draw: ImageDraw.ImageDraw, s: dict) -> None:
    wax = [(26, 17), (38, 17), (40, 43), (24, 43)]
    flame = [(32, 9), (37, 16), (32, 23), (27, 16)]
    outline_polygon(draw, wax, PARCHMENT)
    outline_polygon(draw, flame, GOLD)
    outline_rect(draw, (25, 43, 39, 48), fill=STEEL_DARK, radius=1)
    draw.line([(31, 18), (31, 40)], fill=RED_DARK, width=1)
    draw.line([(33, 18), (33, 40)], fill=s["accent"], width=1)


def t_boots(draw: ImageDraw.ImageDraw, s: dict) -> None:
    back = [(18, 17), (32, 17), (37, 24), (36, 37), (44, 37), (47, 45), (33, 45), (30, 49), (19, 49), (18, 41)]
    front = [(27, 13), (40, 13), (46, 20), (45, 34), (52, 34), (55, 43), (41, 43), (38, 47), (28, 47), (27, 37)]
    outline_polygon(draw, back, STEEL_DARK)
    outline_polygon(draw, front, STEEL)
    draw.line([(31, 20), (37, 20)], fill=STEEL_LIGHT, width=1)
    draw.line([(40, 24), (47, 24)], fill=s["accent"], width=1)


def t_robe(draw: ImageDraw.ImageDraw, s: dict) -> None:
    robe = [(21, 12), (31, 15), (34, 15), (43, 12), (48, 24), (44, 50), (34, 45), (30, 51), (20, 47), (16, 24)]
    inner = [(25, 16), (31, 20), (34, 20), (39, 16), (42, 24), (39, 45), (33, 42), (31, 46), (24, 44), (21, 24)]
    outline_polygon(draw, robe, CLOTH_DARK)
    outline_polygon(draw, inner, CLOTH)
    outline_ellipse(draw, (27, 28, 37, 38), fill=STEEL)
    draw.line([(32, 30), (32, 36)], fill=s["accent"], width=1)
    draw.line([(29, 33), (35, 33)], fill=s["accent"], width=1)
    draw.line([(31, 21), (28, 32)], fill=RED_DARK, width=1)
    draw.line([(34, 21), (37, 32)], fill=RED_DARK, width=1)


def t_cards(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (18, 21, 35, 44), fill=PARCHMENT, radius=2)
    outline_rect(draw, (28, 17, 45, 40), fill=rgba(PARCHMENT, 220), radius=2)
    draw.line([(31, 23), (42, 33)], fill=s["accent"], width=1)
    draw.line([(38, 22), (35, 35)], fill=RED_DARK, width=1)


def t_wheel(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (16, 16, 48, 48), fill=WOOD_DARK)
    outline_ellipse(draw, (21, 21, 43, 43), fill=STEEL_DARK, outline=STEEL_LIGHT)
    outline_ellipse(draw, (27, 27, 37, 37), fill=s["accent"])
    for line in [((32, 18), (32, 46)), ((18, 32), (46, 32)), ((22, 22), (42, 42)), ((42, 22), (22, 42))]:
        draw.line(line, fill=STEEL_LIGHT, width=1)


def t_chalice(draw: ImageDraw.ImageDraw, s: dict) -> None:
    cup = [(24, 18), (40, 18), (44, 24), (37, 31), (27, 31), (20, 24)]
    stem = [(29, 31), (35, 31), (36, 41), (28, 41)]
    base = [(25, 41), (39, 41), (43, 47), (21, 47)]
    outline_polygon(draw, cup, GOLD)
    outline_polygon(draw, stem, STEEL)
    outline_polygon(draw, base, s["base2"])
    outline_ellipse(draw, (27, 20, 37, 28), fill=rgba(s["accent"], 205), outline=s["accent"])
    if s["palette_name"] in {"holy", "cursed"}:
        outline_ellipse(draw, (28, 9, 36, 17), fill=RED if s["palette_name"] == "holy" else PURPLE)


def t_bank(draw: ImageDraw.ImageDraw, s: dict) -> None:
    body = [(20, 22), (44, 22), (48, 31), (44, 43), (20, 43), (16, 31)]
    outline_polygon(draw, body, PARCHMENT)
    outline_rect(draw, (24, 26, 40, 39), fill=PARCHMENT_DARK, radius=4)
    outline_rect(draw, (27, 30, 37, 35), fill=s["accent"], radius=2)
    draw.line([(28, 32), (36, 32)], fill=OUTLINE, width=1)


def t_scale(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (29, 16, 35, 47), fill=STEEL)
    draw.line([(20, 20), (44, 20)], fill=STEEL_LIGHT, width=1)
    draw.line([(24, 20), (21, 31)], fill=OUTLINE, width=1)
    draw.line([(40, 20), (43, 31)], fill=OUTLINE, width=1)
    outline_polygon(draw, [(16, 31), (26, 31), (24, 39), (18, 39)], fill=GOLD_DARK)
    outline_polygon(draw, [(38, 31), (48, 31), (46, 39), (40, 39)], fill=GOLD_DARK)
    outline_polygon(draw, [(25, 47), (39, 47), (43, 52), (21, 52)], fill=s["base2"])


def t_arrow(draw: ImageDraw.ImageDraw, s: dict) -> None:
    tip = [(32, 10), (39, 19), (35, 23), (28, 23), (24, 19)]
    shaft = [(30, 23), (34, 23), (34, 47), (30, 47)]
    tail = [(30, 42), (22, 48), (30, 48), (34, 54), (34, 48), (42, 48)]
    outline_polygon(draw, tip, STEEL_LIGHT)
    outline_polygon(draw, shaft, WOOD_DARK)
    outline_polygon(draw, tail, s["accent"])
    draw.line([(32, 14), (32, 46)], fill=RED_DARK if s["palette_name"] != "holy" else s["accent"], width=1)


def t_eye(draw: ImageDraw.ImageDraw, s: dict) -> None:
    eye = [(16, 32), (23, 22), (32, 18), (41, 22), (48, 32), (41, 42), (32, 46), (23, 42)]
    outline_polygon(draw, eye, CLOTH)
    outline_ellipse(draw, (24, 23, 40, 39), fill=s["base"])
    outline_ellipse(draw, (29, 28, 35, 34), fill=s["accent"])
    draw.line([(20, 32), (44, 32)], fill=RED_DARK, width=1)


def t_dust(draw: ImageDraw.ImageDraw, s: dict) -> None:
    points = [(32, 10), (35, 24), (49, 24), (38, 33), (42, 47), (32, 39), (22, 47), (26, 33), (15, 24), (29, 24)]
    outline_polygon(draw, points, s["accent"])
    outline_ellipse(draw, (27, 27, 37, 37), fill=rgba(CYAN, 180), outline=STEEL_LIGHT)
    for pt in [(14, 18), (48, 17), (18, 47), (46, 45)]:
        outline_ellipse(draw, (pt[0], pt[1], pt[0] + 4, pt[1] + 4), fill=s["accent_soft"])


def t_stake(draw: ImageDraw.ImageDraw, s: dict) -> None:
    wood = [(28, 10), (37, 10), (42, 20), (36, 51), (29, 51), (23, 20)]
    outline_polygon(draw, wood, WOOD)
    for y in [22, 30, 38]:
        outline_rect(draw, (23, y, 42, y + 4), fill=STEEL_DARK, radius=1)
    draw.line([(31, 13), (34, 48)], fill=RED_DARK, width=1)
    draw.point((26, 32), fill=s["accent"])
    draw.point((39, 29), fill=s["accent"])


def t_telescope(draw: ImageDraw.ImageDraw, s: dict) -> None:
    tube = [(18, 20), (44, 14), (50, 24), (24, 30)]
    outline_polygon(draw, tube, STEEL_DARK)
    outline_rect(draw, (18, 19, 24, 31), fill=STEEL_LIGHT, radius=1)
    outline_rect(draw, (44, 13, 50, 26), fill=STEEL_LIGHT, radius=1)
    outline_rect(draw, (28, 17, 36, 27), fill=s["accent"], radius=1)
    draw.line([(32, 30), (26, 46)], fill=WOOD_DARK, width=1)
    draw.line([(36, 29), (40, 44)], fill=WOOD_DARK, width=1)


def t_watch(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (18, 16, 46, 44), fill=STEEL)
    outline_ellipse(draw, (22, 20, 42, 40), fill=NAVY, outline=STEEL_LIGHT)
    outline_rect(draw, (28, 10, 36, 17), fill=GOLD_DARK, radius=1)
    draw.line([(32, 30), (32, 23)], fill=s["accent"], width=1)
    draw.line([(32, 30), (38, 34)], fill=s["accent"], width=1)
    draw.line([(32, 30), (27, 35)], fill=RED_DARK, width=1)


def t_crown(draw: ImageDraw.ImageDraw, s: dict) -> None:
    crown = [(18, 40), (21, 22), (28, 28), (32, 16), (36, 28), (43, 22), (46, 40)]
    outline_polygon(draw, crown, GOLD)
    outline_rect(draw, (18, 40, 46, 47), fill=GOLD_DARK, radius=1)
    for x, c in [(24, RED), (32, s["accent"]), (40, RED)]:
        outline_ellipse(draw, (x - 2, 30, x + 2, 34), fill=c)


def t_scythe(draw: ImageDraw.ImageDraw, s: dict) -> None:
    shaft = [(30, 12), (34, 12), (36, 48), (28, 48)]
    blade = [(34, 10), (46, 13), (53, 24), (48, 31), (38, 24), (33, 16)]
    outline_polygon(draw, shaft, WOOD_DARK)
    outline_polygon(draw, blade, STEEL_LIGHT)
    draw.line([(34, 14), (47, 23)], fill=s["accent"], width=1)
    outline_rect(draw, (29, 48, 35, 54), fill=s["accent"], radius=1)


def t_chain(draw: ImageDraw.ImageDraw, s: dict) -> None:
    for bbox in [(20, 26, 32, 38), (30, 20, 42, 32), (38, 26, 50, 38)]:
        outline_ellipse(draw, bbox, fill=STEEL_DARK)
        outline_ellipse(draw, (bbox[0] + 3, bbox[1] + 3, bbox[2] - 3, bbox[3] - 3), fill=BLACK, outline=STEEL_LIGHT)
    draw.line([(18, 44), (46, 14)], fill=s["accent"], width=1)


def t_contract(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (20, 16, 44, 46), fill=PARCHMENT, radius=2)
    draw.line([(22, 22), (40, 22)], fill=RED_DARK, width=1)
    draw.line([(24, 27), (38, 27)], fill=STEEL_DARK, width=1)
    draw.line([(24, 32), (39, 32)], fill=STEEL_DARK, width=1)
    outline_rect(draw, (27, 37, 37, 43), fill=RED_DARK, radius=2)
    draw.line([(32, 16), (32, 46)], fill=s["accent_soft"], width=1)


def t_crucible(draw: ImageDraw.ImageDraw, s: dict) -> None:
    bowl = [(18, 22), (46, 22), (50, 34), (42, 45), (22, 45), (14, 34)]
    outline_polygon(draw, bowl, STEEL_DARK)
    outline_polygon(draw, [(22, 30), (42, 30), (38, 41), (26, 41)], rgba(GOLD, 200))
    draw.line([(25, 24), (31, 18)], fill=RED_DARK, width=1)
    draw.line([(39, 24), (33, 18)], fill=s["accent"], width=1)
    draw.line([(24, 45), (21, 53)], fill=WOOD_DARK, width=1)
    draw.line([(40, 45), (43, 53)], fill=WOOD_DARK, width=1)


def t_veil(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (15, 11, 42, 38), fill=STEEL_LIGHT)
    draw.ellipse((23, 14, 45, 36), fill=BLACK)
    veil = [(30, 24), (45, 17), (49, 25), (43, 42), (48, 53), (36, 50), (24, 56), (20, 42), (25, 30)]
    outline_polygon(draw, veil, rgba(PURPLE, 220))
    draw.line([(28, 32), (42, 26)], fill=s["accent"], width=1)
    draw.line([(27, 43), (40, 38)], fill=s["accent_soft"], width=1)


def t_guillotine(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (20, 15, 44, 48), fill=WOOD_DARK, radius=1)
    outline_rect(draw, (24, 19, 40, 42), fill=STEEL_DARK, radius=1)
    blade = [(24, 22), (40, 22), (24, 38)]
    outline_polygon(draw, blade, STEEL_LIGHT)
    outline_rect(draw, (16, 48, 48, 53), fill=s["base2"], radius=1)
    draw.line([(40, 22), (34, 36)], fill=RED_DARK, width=1)


def t_tree(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_rect(draw, (18, 44, 46, 53), fill=STEEL_DARK, outline=STEEL_LIGHT, radius=4)
    outline_polygon(draw, [(29, 24), (35, 24), (36, 44), (28, 44)], WOOD)
    for poly in [
        [(21, 23), (29, 15), (33, 22), (28, 30), (20, 29)],
        [(28, 12), (37, 7), (44, 14), (38, 24), (30, 21)],
        [(36, 20), (46, 18), (51, 28), (43, 35), (34, 31)],
    ]:
        outline_polygon(draw, poly, LEAF)
    draw.line([(30, 44), (24, 49)], fill=WOOD_DARK, width=1)
    draw.line([(34, 44), (40, 49)], fill=WOOD_DARK, width=1)


def t_glutton(draw: ImageDraw.ImageDraw, s: dict) -> None:
    sack = [(20, 18), (44, 18), (48, 31), (42, 48), (22, 48), (16, 31)]
    outline_polygon(draw, sack, RED_DARK)
    mouth = [(24, 30), (40, 30), (36, 38), (28, 38)]
    outline_polygon(draw, mouth, NAVY)
    for x in [26, 30, 34, 38]:
        draw.line([(x, 30), (x + 2, 38)], fill=STEEL_LIGHT, width=1)
    draw.line([(24, 23), (40, 23)], fill=GOLD, width=1)
    draw.line([(27, 26), (37, 26)], fill=s["accent"], width=1)


def t_throne(draw: ImageDraw.ImageDraw, s: dict) -> None:
    back = [(21, 14), (43, 14), (46, 30), (18, 30)]
    seat = [(19, 30), (45, 30), (42, 39), (22, 39)]
    legs = [(22, 39), (27, 39), (25, 51), (20, 51)], [(37, 39), (42, 39), (44, 51), (39, 51)]
    outline_polygon(draw, back, GOLD_DARK)
    outline_polygon(draw, seat, GOLD)
    for leg in legs:
        outline_polygon(draw, list(leg), WOOD_DARK)
    for x in [24, 32, 40]:
        outline_ellipse(draw, (x - 2, 18, x + 2, 22), fill=s["accent"])
    draw.line([(32, 14), (32, 39)], fill=RED_DARK, width=1)


def t_orb(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (16, 14, 48, 46), fill=s["base2"])
    outline_ellipse(draw, (20, 18, 44, 42), fill=rgba(s["accent"], 160), outline=STEEL_LIGHT)
    draw.arc((20, 18, 44, 42), start=25, end=150, fill=CYAN, width=1)
    draw.arc((21, 19, 43, 41), start=200, end=320, fill=CYAN, width=1)
    outline_rect(draw, (24, 46, 40, 51), fill=STEEL_DARK, radius=1)
    outline_polygon(draw, [(23, 51), (41, 51), (45, 56), (19, 56)], s["base2"])


def t_pocket(draw: ImageDraw.ImageDraw, s: dict) -> None:
    pouch = [(22, 16), (42, 16), (46, 27), (42, 48), (22, 48), (18, 27)]
    outline_polygon(draw, pouch, s["base"])
    draw.line([(24, 24), (40, 24)], fill=GOLD, width=1)
    outline_rect(draw, (25, 29, 39, 41), fill=rgba(s["accent"], 200), radius=3)
    draw.line([(29, 35), (35, 35)], fill=OUTLINE, width=1)


def t_star(draw: ImageDraw.ImageDraw, s: dict) -> None:
    star = [(32, 10), (36, 24), (50, 24), (39, 33), (43, 47), (32, 39), (21, 47), (25, 33), (14, 24), (28, 24)]
    outline_polygon(draw, star, GOLD)
    outline_ellipse(draw, (27, 27, 37, 37), fill=rgba(s["accent"], 200), outline=STEEL_LIGHT)
    draw.line([(21, 47), (43, 24)], fill=s["accent"], width=1)


def t_omni(draw: ImageDraw.ImageDraw, s: dict) -> None:
    outline_ellipse(draw, (15, 12, 49, 46), fill=STEEL_DARK)
    outline_ellipse(draw, (19, 16, 45, 42), fill=NAVY, outline=STEEL_LIGHT)
    draw.line([(22, 29), (42, 29)], fill=CYAN, width=1)
    draw.line([(32, 17), (32, 41)], fill=CYAN, width=1)
    draw.arc((21, 18, 43, 40), start=35, end=145, fill=CYAN_SOFT, width=1)
    draw.arc((22, 19, 42, 39), start=215, end=325, fill=CYAN_SOFT, width=1)
    ring = [(11, 26), (16, 22), (48, 22), (53, 26), (53, 32), (48, 36), (16, 36), (11, 32)]
    outline_polygon(draw, ring, rgba(GOLD, 210))
    crest = [(26, 30), (38, 30), (41, 37), (32, 45), (23, 37)]
    outline_polygon(draw, crest, rgba(PURPLE, 220))
    draw.line([(32, 32), (32, 41)], fill=GOLD, width=1)
    draw.line([(27, 36), (37, 36)], fill=GOLD, width=1)


TEMPLATES: dict[str, Callable[[ImageDraw.ImageDraw, dict], None]] = {
    "book": t_book,
    "dagger": t_dagger,
    "lantern": t_lantern,
    "herb": t_herb,
    "mirror": t_mirror,
    "bullet": t_bullet,
    "whetstone": t_whetstone,
    "coin": t_coin,
    "rabbit_foot": t_rabbit_foot,
    "feather": t_feather,
    "scroll": t_scroll,
    "lens": t_lens,
    "bandage": t_bandage,
    "shield": t_shield,
    "beads": t_beads,
    "potion": t_potion,
    "bottle": t_bottle,
    "candle": t_candle,
    "boots": t_boots,
    "robe": t_robe,
    "cards": t_cards,
    "wheel": t_wheel,
    "chalice": t_chalice,
    "bank": t_bank,
    "scale": t_scale,
    "arrow": t_arrow,
    "eye": t_eye,
    "dust": t_dust,
    "stake": t_stake,
    "telescope": t_telescope,
    "watch": t_watch,
    "crown": t_crown,
    "scythe": t_scythe,
    "chain": t_chain,
    "contract": t_contract,
    "crucible": t_crucible,
    "veil": t_veil,
    "guillotine": t_guillotine,
    "tree": t_tree,
    "glutton": t_glutton,
    "throne": t_throne,
    "orb": t_orb,
    "pocket": t_pocket,
    "star": t_star,
    "omni": t_omni,
}


SPEC = {
    "item_bible_old": {"template": "book", "palette": "holy", "prompt": "old holy book, armor cue"},
    "item_dagger_rusty": {"template": "dagger", "palette": "martial", "prompt": "rusty dagger, attack speed with health cost"},
    "item_lantern_apprentice": {"template": "lantern", "palette": "holy", "prompt": "apprentice lantern, pickup cue"},
    "item_herb_dry": {"template": "herb", "palette": "nature", "prompt": "dried herb bundle, healing cue"},
    "item_mirror_crude": {"template": "mirror", "palette": "holy", "prompt": "crude mirror, armor and dodge cue"},
    "item_bullet_lead": {"template": "bullet", "palette": "martial", "prompt": "lead bullet, ranged damage cue"},
    "item_whetstone_heavy": {"template": "whetstone", "palette": "martial", "prompt": "heavy whetstone, melee damage cue"},
    "item_coin_broken": {"template": "coin", "palette": "economy", "prompt": "broken ancient coin, harvest cue"},
    "item_rabbit_foot": {"template": "rabbit_foot", "palette": "holy", "prompt": "lucky rabbit foot, luck cue"},
    "item_feather_light": {"template": "feather", "palette": "holy", "prompt": "light feather, move speed cue"},
    "item_tarot_fragment": {"template": "scroll", "palette": "cosmic", "prompt": "tarot fragment page, experience cue"},
    "item_lens_shard": {"template": "lens", "palette": "holy", "prompt": "lens shard, range cue"},
    "item_bandage_bloody": {"template": "bandage", "palette": "martial", "prompt": "bloody bandage, lifesteal cue"},
    "item_alchemist_coin": {"template": "coin", "palette": "economy", "prompt": "alchemist coin, harvest cue"},
    "item_shield_wood": {"template": "shield", "palette": "holy", "prompt": "wooden shield, dodge cue"},
    "item_beads_meditation": {"template": "beads", "palette": "holy", "prompt": "meditation beads, regeneration cue"},
    "item_potion_strange": {"template": "potion", "palette": "cursed", "prompt": "strange potion, risky power cue"},
    "item_bottle_empty": {"template": "bottle", "palette": "martial", "prompt": "empty bottle, scrappy agility cue"},
    "item_candle_ritual": {"template": "candle", "palette": "cursed", "prompt": "ritual candle, crit cue"},
    "item_boots_iron": {"template": "boots", "palette": "martial", "prompt": "iron boots, armor cue"},
    "item_pope_robe": {"template": "robe", "palette": "holy", "prompt": "pope robe, armor and vitality cue"},
    "item_magician_poker": {"template": "cards", "palette": "cosmic", "prompt": "magician poker cards, crit cue"},
    "item_chariot_wheel": {"template": "wheel", "palette": "martial", "prompt": "chariot wheel, speed cue"},
    "item_priestess_mercy": {"template": "chalice", "palette": "holy", "prompt": "priestess mercy chalice, sustain cue"},
    "item_hermit_candle": {"template": "candle", "palette": "holy", "prompt": "hermit candle, output cue"},
    "item_piggy_bank": {"template": "bank", "palette": "economy", "prompt": "piggy bank, interest cue"},
    "item_merchant_scale": {"template": "scale", "palette": "economy", "prompt": "merchant scale, trade and harvest cue"},
    "item_revenge_arrow": {"template": "arrow", "palette": "martial", "prompt": "revenge arrow, ranged damage cue"},
    "item_cursed_eye": {"template": "eye", "palette": "cursed", "prompt": "cursed eye, unstable power cue"},
    "item_star_dust": {"template": "dust", "palette": "cosmic", "prompt": "stardust, exp and luck cue"},
    "item_stake_tough": {"template": "stake", "palette": "martial", "prompt": "reinforced stake, max hp cue"},
    "item_razor_sharp": {"template": "dagger", "palette": "martial", "prompt": "sharp razor, melee offense cue"},
    "item_telescope": {"template": "telescope", "palette": "holy", "prompt": "telescope, range cue"},
    "item_watch_magnetic": {"template": "watch", "palette": "holy", "prompt": "magnetic watch, pickup cue"},
    "item_crown_thorn": {"template": "crown", "palette": "cursed", "prompt": "thorn crown, risky damage cue"},
    "item_death_scythe": {"template": "scythe", "palette": "cursed", "prompt": "death scythe, crit cue"},
    "item_wheel_fortune": {"template": "wheel", "palette": "economy", "prompt": "wheel of fortune, luck cue"},
    "item_inquisitor_chain": {"template": "chain", "palette": "cursed", "prompt": "inquisitor chain, punishment cue"},
    "item_temperance_sacrament": {"template": "chalice", "palette": "holy", "prompt": "temperance sacrament, major regeneration cue"},
    "item_demon_contract": {"template": "contract", "palette": "cursed", "prompt": "demon contract, high-risk reward cue"},
    "item_alchemist_crucible": {"template": "crucible", "palette": "economy", "prompt": "alchemist crucible, gold and damage cue"},
    "item_moon_veil": {"template": "veil", "palette": "cosmic", "prompt": "moon veil, dodge and vitality cue"},
    "item_justice_guillotine": {"template": "guillotine", "palette": "martial", "prompt": "justice guillotine, execution cue"},
    "item_world_tree_sapling": {"template": "tree", "palette": "nature", "prompt": "world tree sapling, massive vitality cue"},
    "item_glutton_greed": {"template": "glutton", "palette": "economy", "prompt": "glutton greed, harvest cue"},
    "item_emperor_throne": {"template": "throne", "palette": "economy", "prompt": "emperor throne, supreme offense cue"},
    "item_astronomy_orb": {"template": "orb", "palette": "cosmic", "prompt": "astronomy orb, all-knowledge cue"},
    "item_fool_pocket": {"template": "pocket", "palette": "holy", "prompt": "fool pocket, versatile stash cue"},
    "item_star_source": {"template": "star", "palette": "cosmic", "prompt": "star source, exp and luck cue"},
    "item_world_omni": {"template": "omni", "palette": "cosmic", "prompt": "omniscient world orb, ultimate survival cue"},
}


ITEM_ROWS = [
    {"item_id": "item_bible_old", "name": "破旧的圣经", "rarity": "common", "description": "+3 护甲, -4% 移速"},
    {"item_id": "item_dagger_rusty", "name": "生锈的匕首", "rarity": "common", "description": "+5% 攻速, -3 最大生命"},
    {"item_id": "item_lantern_apprentice", "name": "学徒提灯", "rarity": "common", "description": "+20 拾取范围, -2 幸运"},
    {"item_id": "item_herb_dry", "name": "干燥草药", "rarity": "common", "description": "+1 生命回复, -3% 伤害"},
    {"item_id": "item_mirror_crude", "name": "粗制护心镜", "rarity": "common", "description": "+2 护甲, -1% 闪避"},
    {"item_id": "item_bullet_lead", "name": "铅制子弹", "rarity": "common", "description": "+3 远程伤害, -2% 攻速"},
    {"item_id": "item_whetstone_heavy", "name": "沉重磨刀石", "rarity": "common", "description": "+3 近战伤害, -2% 攻速"},
    {"item_id": "item_coin_broken", "name": "破碎古币", "rarity": "common", "description": "+8 收获, -2% 闪避"},
    {"item_id": "item_rabbit_foot", "name": "幸运兔脚", "rarity": "common", "description": "+10 幸运, -3 最大生命"},
    {"item_id": "item_feather_light", "name": "轻快羽毛", "rarity": "common", "description": "+5% 移速, -1 护甲"},
    {"item_id": "item_tarot_fragment", "name": "塔罗残页", "rarity": "common", "description": "+5% 经验获取, -2 幸运"},
    {"item_id": "item_lens_shard", "name": "透镜碎片", "rarity": "common", "description": "+10% 攻击范围, -3% 攻速"},
    {"item_id": "item_bandage_bloody", "name": "带血绷带", "rarity": "common", "description": "+1% 吸血, -2 护甲"},
    {"item_id": "item_alchemist_coin", "name": "炼金金币", "rarity": "common", "description": "+12 收获, -3% 移速"},
    {"item_id": "item_shield_wood", "name": "木制圆盾", "rarity": "common", "description": "+5% 闪避, -3% 伤害"},
    {"item_id": "item_beads_meditation", "name": "冥想念珠", "rarity": "common", "description": "+2 生命回复, -5% 攻速"},
    {"item_id": "item_potion_strange", "name": "怪味药水", "rarity": "common", "description": "+10% 伤害, -5 最大生命"},
    {"item_id": "item_bottle_empty", "name": "空酒瓶", "rarity": "common", "description": "+5% 攻速, +5% 移速, -3 护甲"},
    {"item_id": "item_candle_ritual", "name": "仪式蜡烛", "rarity": "common", "description": "+5% 暴击率, -2 护甲"},
    {"item_id": "item_boots_iron", "name": "沉重铁靴", "rarity": "common", "description": "+5 护甲, -8% 移速"},
    {"item_id": "item_pope_robe", "name": "教皇法袍", "rarity": "rare", "description": "+5 护甲, +10 最大生命, -5% 移速"},
    {"item_id": "item_magician_poker", "name": "魔术师扑克", "rarity": "rare", "description": "+10% 暴击率, +10% 暴击伤害, -5 最大生命"},
    {"item_id": "item_chariot_wheel", "name": "战车轮毂", "rarity": "rare", "description": "+15% 移速, +15 拾取范围, -2 护甲"},
    {"item_id": "item_priestess_mercy", "name": "女祭司慈悲", "rarity": "rare", "description": "+3% 吸血, +2 生命回复, -5% 伤害"},
    {"item_id": "item_hermit_candle", "name": "隐者蜡烛", "rarity": "rare", "description": "+20% 伤害, -10% 攻速"},
    {"item_id": "item_piggy_bank", "name": "储蓄罐", "rarity": "rare", "description": "+20 每波利息(以收获体现), -5% 伤害"},
    {"item_id": "item_merchant_scale", "name": "商人的天平", "rarity": "rare", "description": "+25 收获, -10% 伤害"},
    {"item_id": "item_revenge_arrow", "name": "复仇之箭", "rarity": "rare", "description": "+5 远程伤害, -5% 闪避"},
    {"item_id": "item_cursed_eye", "name": "诅咒之眼", "rarity": "rare", "description": "+15% 伤害, +10% 攻速, -20 幸运"},
    {"item_id": "item_star_dust", "name": "星辰之尘", "rarity": "rare", "description": "+20% 经验获取, +10 幸运, -5% 伤害"},
    {"item_id": "item_stake_tough", "name": "坚韧木桩", "rarity": "rare", "description": "+20 最大生命, -5% 移速"},
    {"item_id": "item_razor_sharp", "name": "锋利剃刀", "rarity": "rare", "description": "+8 近战伤害, +8% 攻速, -5 护甲"},
    {"item_id": "item_telescope", "name": "望远镜", "rarity": "rare", "description": "+25% 攻击范围, +5 远程伤害, -5% 闪避"},
    {"item_id": "item_watch_magnetic", "name": "磁力怀表", "rarity": "rare", "description": "+100 拾取范围, -8% 伤害"},
    {"item_id": "item_crown_thorn", "name": "荆棘王冠", "rarity": "rare", "description": "+15% 伤害, -15 最大生命"},
    {"item_id": "item_death_scythe", "name": "死神权能", "rarity": "epic", "description": "+15% 暴击率, -10 生命回复"},
    {"item_id": "item_wheel_fortune", "name": "命运之轮", "rarity": "epic", "description": "+30 幸运, -10 护甲"},
    {"item_id": "item_inquisitor_chain", "name": "审判官锁链", "rarity": "epic", "description": "+20% 伤害, -10% 攻速"},
    {"item_id": "item_temperance_sacrament", "name": "节制圣餐", "rarity": "epic", "description": "+5 生命回复, -35% 移速"},
    {"item_id": "item_demon_contract", "name": "恶魔契约", "rarity": "epic", "description": "+50% 伤害, +20 收获"},
    {"item_id": "item_alchemist_crucible", "name": "炼金坩埚", "rarity": "epic", "description": "+15% 金币收益, +5 伤害, -10 护甲"},
    {"item_id": "item_moon_veil", "name": "月之纱幔", "rarity": "epic", "description": "+20% 闪避, -10 最大生命"},
    {"item_id": "item_justice_guillotine", "name": "正义断头台", "rarity": "epic", "description": "+25% 伤害, -5 护甲"},
    {"item_id": "item_world_tree_sapling", "name": "世界树幼苗", "rarity": "epic", "description": "+100 最大生命, -30% 伤害"},
    {"item_id": "item_glutton_greed", "name": "暴食者贪婪", "rarity": "epic", "description": "+20 收获, -10% 闪避"},
    {"item_id": "item_emperor_throne", "name": "皇帝至尊宝座", "rarity": "legendary", "description": "+40% 伤害, +40% 攻速, -25% 移速"},
    {"item_id": "item_astronomy_orb", "name": "全知星象仪", "rarity": "legendary", "description": "+25 幸运, +25 收获, +25% 经验"},
    {"item_id": "item_fool_pocket", "name": "愚者万能口袋", "rarity": "legendary", "description": "+20% 攻速, +20% 金币收益"},
    {"item_id": "item_star_source", "name": "星辰之源", "rarity": "legendary", "description": "+15% 经验, +15 幸运"},
    {"item_id": "item_world_omni", "name": "世界·全知全能", "rarity": "legendary", "description": "+20 生命, +10 护甲, +10% 闪避, +10% 暴击, +10 幸运, +10 收获"},
]


def build_icon(item: dict, spec: dict) -> Image.Image:
    img, draw = new_canvas()
    st = style(spec)
    st["palette_name"] = spec["palette"]
    TEMPLATES[spec["template"]](draw, st)
    img = apply_inner_texture(img, st["accent"], sum(ord(ch) for ch in item["item_id"]) + 17, spec["rarity"])
    img = apply_pixel_bevel(img, st["accent"], spec["rarity"])
    draw = ImageDraw.Draw(img)
    add_rarity_fx(draw, spec["rarity"], st["accent"])
    add_glitch_sparks(draw, sum(ord(ch) for ch in item["item_id"]), spec["rarity"])
    return img


def build_preview(rows: list[dict]) -> None:
    cell = 220
    label_h = 32
    cols = 5
    rows_n = math.ceil(len(rows) / cols)
    img = Image.new("RGBA", (cols * cell, rows_n * (cell + label_h)), (10, 16, 25, 255))
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()
    for idx, row in enumerate(rows):
        x = (idx % cols) * cell
        y = (idx // cols) * (cell + label_h)
        draw.rounded_rectangle((x + 12, y + 12, x + cell - 12, y + cell - 12), radius=12, fill=(38, 58, 81, 255))
        icon = Image.open(ROOT / row["path"]).convert("RGBA").resize((176, 176), Image.Resampling.NEAREST)
        img.alpha_composite(icon, (x + 22, y + 20))
        draw.text((x + 14, y + cell + 8), row["item_id"], fill=(228, 236, 245, 255), font=font)
    img.save(PREVIEW_PATH)


def load_items() -> list[dict]:
    return ITEM_ROWS


def main() -> None:
    items = load_items()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest: list[dict] = []
    for item in items:
        item_id = item["item_id"]
        spec = SPEC[item_id].copy()
        spec["rarity"] = item["rarity"]
        image = build_icon(item, spec)
        path = save_icon(image, item_id)
        manifest.append(
            {
                "item_id": item_id,
                "name": item["name"],
                "rarity": item["rarity"],
                "description": item["description"],
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                "size": f"{EXPORT_SIZE}x{EXPORT_SIZE}",
                "style": "pixel-art + subtle glitch + transparent background",
                "prompt": spec["prompt"],
            }
        )
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    build_preview(manifest)
    print(f"generated {len(manifest)} icons")


if __name__ == "__main__":
    main()
