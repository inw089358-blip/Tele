class_name TarotSystem
extends Node

const CARD_IMAGE_DIR: String = "res://sprite/tarot/minor_arcana"

const CARDS: Dictionary = {
    "pageofcups": {
        "name": "Page of Cups",
        "desc": "Max HP +4",
        "suit": "cups",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofcups.png",
        "effects": [
            {"type": "max_hp_flat", "value": 4}
        ]
    },
    "knightofcups": {
        "name": "Knight of Cups",
        "desc": "Lifesteal +2",
        "suit": "cups",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofcups.png",
        "effects": [
            {"type": "lifesteal_flat", "value": 2.0}
        ]
    },
    "queenofcups": {
        "name": "Queen of Cups",
        "desc": "HP Regen +1.5",
        "suit": "cups",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofcups.png",
        "effects": [
            {"type": "hp_regen_flat", "value": 1.5}
        ]
    },
    "kingofcups": {
        "name": "King of Cups",
        "desc": "Max HP +3. Heal +8",
        "suit": "cups",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofcups.png",
        "effects": [
            {"type": "max_hp_flat", "value": 3},
            {"type": "heal_flat", "value": 8}
        ]
    },
    "pageofpentacles": {
        "name": "Page of Pentacles",
        "desc": "Luck +8",
        "suit": "pentacles",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofpentacles.png",
        "effects": [
            {"type": "luck_flat", "value": 8.0}
        ]
    },
    "knightofpentacles": {
        "name": "Knight of Pentacles",
        "desc": "Harvest +10",
        "suit": "pentacles",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofpentacles.png",
        "effects": [
            {"type": "harvest_flat", "value": 10.0}
        ]
    },
    "queenofpentacles": {
        "name": "Queen of Pentacles",
        "desc": "Armor +2",
        "suit": "pentacles",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofpentacles.png",
        "effects": [
            {"type": "armor_flat", "value": 2.0}
        ]
    },
    "kingofpentacles": {
        "name": "King of Pentacles",
        "desc": "XP Gain x1.12",
        "suit": "pentacles",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofpentacles.png",
        "effects": [
            {"type": "xp_gain_mult", "value": 1.12}
        ]
    },
    "pageofsword": {
        "name": "Page of Swords",
        "desc": "Attack +1",
        "suit": "swords",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofsword.png",
        "effects": [
            {"type": "attack_damage_flat", "value": 1}
        ]
    },
    "knightofsword": {
        "name": "Knight of Swords",
        "desc": "Attack Speed x1.08",
        "suit": "swords",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofsword.png",
        "effects": [
            {"type": "attack_speed_mult", "value": 1.08}
        ]
    },
    "queenofsword": {
        "name": "Queen of Swords",
        "desc": "Crit Chance +6%",
        "suit": "swords",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofsword.png",
        "effects": [
            {"type": "crit_chance_flat", "value": 0.06}
        ]
    },
    "kingofsword": {
        "name": "King of Swords",
        "desc": "Global Attack +10%",
        "suit": "swords",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofsword.png",
        "effects": [
            {"type": "global_attack_percent_flat", "value": 0.10}
        ]
    },
    "pageofwands": {
        "name": "Page of Wands",
        "desc": "Move Speed +8",
        "suit": "wands",
        "rank": "page",
        "image_path": CARD_IMAGE_DIR + "/pageofwands.png",
        "effects": [
            {"type": "move_speed_flat", "value": 8.0}
        ]
    },
    "knightofwands": {
        "name": "Knight of Wands",
        "desc": "Range +35",
        "suit": "wands",
        "rank": "knight",
        "image_path": CARD_IMAGE_DIR + "/knightofwands.png",
        "effects": [
            {"type": "target_range_flat", "value": 35.0}
        ]
    },
    "queenofwands": {
        "name": "Queen of Wands",
        "desc": "Attack Speed x1.12",
        "suit": "wands",
        "rank": "queen",
        "image_path": CARD_IMAGE_DIR + "/queenofwands.png",
        "effects": [
            {"type": "attack_speed_mult", "value": 1.12}
        ]
    },
    "kingofwands": {
        "name": "King of Wands",
        "desc": "Attack +2. Move Speed +4",
        "suit": "wands",
        "rank": "king",
        "image_path": CARD_IMAGE_DIR + "/kingofwands.png",
        "effects": [
            {"type": "attack_damage_flat", "value": 2},
            {"type": "move_speed_flat", "value": 4.0}
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

static func apply_card_effect(card_id: String, player: Player) -> void:
    if not CARDS.has(card_id):
        return
    var card: Dictionary = CARDS[card_id]
    var effects: Array = card.get("effects", [])
    for effect in effects:
        var type: String = effect.get("type", "")
        var value: Variant = effect.get("value", 0)
        player.apply_effect(type, value)
