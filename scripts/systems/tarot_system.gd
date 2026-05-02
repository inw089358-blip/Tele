class_name TarotSystem
extends Node

const CARD_IMAGE_DIR: String = "res://sprite/tarot/minor_arcana"
const CARD_CROP_REGION_LARGE: Array[int] = [998, 170, 820, 1230]
const CARD_CROP_REGION_WIDE: Array[int] = [1038, 100, 930, 1395]
const CARD_CROP_REGION_QUEEN_CUPS: Array[int] = [350, 40, 320, 480]

const CARDS: Dictionary = {
    "pageofcups": {
        "name": "Page of Cups",
        "desc": "最大生命 +4",
        "suit": "cups",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofcups.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "max_hp_flat", "value": 4}
        ]
    },
    "knightofcups": {
        "name": "Knight of Cups",
        "desc": "吸血 +2%",
        "suit": "cups",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofcups.png",
        "crop_region": CARD_CROP_REGION_WIDE,
        "effects": [
            {"type": "lifesteal_flat", "value": 0.02}
        ]
    },
    "queenofcups": {
        "name": "Queen of Cups",
        "desc": "生命回复 +1.5",
        "suit": "cups",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofcups.png",
        "crop_region": CARD_CROP_REGION_QUEEN_CUPS,
        "effects": [
            {"type": "hp_regen_flat", "value": 1.5}
        ]
    },
    "kingofcups": {
        "name": "King of Cups",
        "desc": "最大生命 +3，立即治疗 +8",
        "suit": "cups",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofcups.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "max_hp_flat", "value": 3},
            {"type": "heal_flat", "value": 8}
        ]
    },
    "pageofpentacles": {
        "name": "Page of Pentacles",
        "desc": "幸运 +8",
        "suit": "pentacles",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofpentacles.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "luck_flat", "value": 8.0}
        ]
    },
    "knightofpentacles": {
        "name": "Knight of Pentacles",
        "desc": "收获 +10",
        "suit": "pentacles",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofpentacles.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "harvest_flat", "value": 10.0}
        ]
    },
    "queenofpentacles": {
        "name": "Queen of Pentacles",
        "desc": "护甲 +2",
        "suit": "pentacles",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofpentacles.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "armor_flat", "value": 2.0}
        ]
    },
    "kingofpentacles": {
        "name": "King of Pentacles",
        "desc": "下一关怪物掉落 x2",
        "suit": "pentacles",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofpentacles.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "next_stage_drop_double", "value": 1}
        ]
    },
    "pageofsword": {
        "name": "Page of Swords",
        "desc": "攻击 +1",
        "suit": "swords",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofsword.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "attack_damage_flat", "value": 1}
        ]
    },
    "knightofsword": {
        "name": "Knight of Swords",
        "desc": "攻击速度 +8%",
        "suit": "swords",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofsword.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "attack_speed_mult", "value": 1.08}
        ]
    },
    "queenofsword": {
        "name": "Queen of Swords",
        "desc": "暴击率 +6%",
        "suit": "swords",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofsword.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "crit_chance_flat", "value": 0.06}
        ]
    },
    "kingofsword": {
        "name": "King of Swords",
        "desc": "伤害 +10%",
        "suit": "swords",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofsword.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "global_attack_percent_flat", "value": 10.0}
        ]
    },
    "pageofwands": {
        "name": "Page of Wands",
        "desc": "移动速度 +8%",
        "suit": "wands",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofwands.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "move_speed_mult", "value": 1.08}
        ]
    },
    "knightofwands": {
        "name": "Knight of Wands",
        "desc": "索敌范围 +35",
        "suit": "wands",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofwands.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "target_range_flat", "value": 35.0}
        ]
    },
    "queenofwands": {
        "name": "Queen of Wands",
        "desc": "攻击速度 +12%",
        "suit": "wands",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofwands.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "attack_speed_mult", "value": 1.12}
        ]
    },
    "kingofwands": {
        "name": "King of Wands",
        "desc": "攻击 +2，移动速度 +4%",
        "suit": "wands",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofwands.png",
        "crop_region": CARD_CROP_REGION_LARGE,
        "effects": [
            {"type": "attack_damage_flat", "value": 2},
            {"type": "move_speed_mult", "value": 1.04}
        ]
    }
}

static func get_random_choices(count: int = 3) -> Array[String]:
    var keys: Array = CARDS.keys()
    keys.shuffle()
    var result: Array[String] = []
    for i in range(min(count, keys.size())):
        result.append(keys[i])
    return result

static func get_card_name(card_id: String) -> String:
    if not CARDS.has(card_id):
        return card_id
    var card: Dictionary = CARDS[card_id]
    return LocaleService.t_data("tarot", card_id, "name", str(card.get("name", card_id)))

static func get_card_desc(card_id: String) -> String:
    if not CARDS.has(card_id):
        return ""
    var card: Dictionary = CARDS[card_id]
    return LocaleService.t_data("tarot", card_id, "desc", str(card.get("desc", "")))

static func apply_card_effect(card_id: String, player: Player) -> void:
    if not CARDS.has(card_id):
        return
    var card: Dictionary = CARDS[card_id]
    var effects: Array = card.get("effects", [])
    for effect in effects:
        var type: String = effect.get("type", "")
        var value: Variant = effect.get("value", 0)
        if type == "next_stage_drop_double":
            if GameManager != null and GameManager.has_method("queue_next_stage_drop_double"):
                GameManager.call("queue_next_stage_drop_double")
            continue
        player.apply_effect(type, value)
