class_name TarotSystem
extends Node

const CARDS: Dictionary = {
    "the_fool": {
        "name": "The Fool",
        "desc": "A new beginning. Luck +15, but Max HP -5.",
        "effects": [
            {"type": "luck_flat", "value": 15.0},
            {"type": "max_hp_flat", "value": -5}
        ]
    },
    "the_magician": {
        "name": "The Magician",
        "desc": "Mastery of tools. All damage +10%.",
        "effects": [
            {"type": "attack_damage_flat", "value": 2}
        ]
    },
    "the_high_priestess": {
        "name": "The High Priestess",
        "desc": "Hidden wisdom. XP Gain +20%.",
        "effects": [
            {"type": "xp_gain_mult", "value": 1.2}
        ]
    },
    "the_empress": {
        "name": "The Empress",
        "desc": "Abundance. Harvest +20.",
        "effects": [
            {"type": "harvest_flat", "value": 20.0}
        ]
    },
    "the_emperor": {
        "name": "The Emperor",
        "desc": "Authority and structure. Armor +5.",
        "effects": [
            {"type": "armor_flat", "value": 5.0}
        ]
    },
    "the_hierophant": {
        "name": "The Hierophant",
        "desc": "Tradition. Crit Chance +10%.",
        "effects": [
            {"type": "crit_chance_flat", "value": 0.1}
        ]
    },
    "the_lovers": {
        "name": "The Lovers",
        "desc": "Harmony. Lifesteal +3%.",
        "effects": [
            {"type": "lifesteal_flat", "value": 3.0}
        ]
    },
    "the_chariot": {
        "name": "The Chariot",
        "desc": "Determination. Move Speed +15.",
        "effects": [
            {"type": "move_speed_flat", "value": 15.0}
        ]
    },
    "strength": {
        "name": "Strength",
        "desc": "Inner power. Melee Damage +5.",
        "effects": [
            {"type": "melee_damage_flat", "value": 5.0}
        ]
    },
    "the_hermit": {
        "name": "The Hermit",
        "desc": "Solitude. Range +40.",
        "effects": [
            {"type": "target_range_flat", "value": 40.0}
        ]
    },
    "wheel_of_fortune": {
        "name": "Wheel of Fortune",
        "desc": "Destiny. Random stat boost: Luck +30 or Gold +100.",
        "effects": [
            {"type": "luck_flat", "value": 30.0} # Simplified for now
        ]
    },
    "justice": {
        "name": "Justice",
        "desc": "Balance. Dodge Chance +8%.",
        "effects": [
            {"type": "dodge_chance_flat", "value": 8.0}
        ]
    },
    "the_hanged_man": {
        "name": "The Hanged Man",
        "desc": "Perspective. Dodge +15%, but Move Speed -10.",
        "effects": [
            {"type": "dodge_chance_flat", "value": 15.0},
            {"type": "move_speed_flat", "value": -10.0}
        ]
    },
    "death": {
        "name": "Death",
        "desc": "Transformation. Damage +25%, but Max HP -10.",
        "effects": [
            {"type": "attack_damage_flat", "value": 5},
            {"type": "max_hp_flat", "value": -10}
        ]
    },
    "temperance": {
        "name": "Temperance",
        "desc": "Moderation. HP Regen +2.",
        "effects": [
            {"type": "hp_regen_flat", "value": 2.0}
        ]
    },
    "the_devil": {
        "name": "The Devil",
        "desc": "Temptation. Damage +40%, but take 1 damage every 5 seconds.",
        "effects": [
            {"type": "attack_damage_flat", "value": 8}
        ]
    },
    "the_tower": {
        "name": "The Tower",
        "desc": "Upheaval. Explosion radius +30%.",
        "effects": [
            {"type": "explosion_radius_mult", "value": 1.3}
        ]
    },
    "the_star": {
        "name": "The Star",
        "desc": "Hope. Crit Multiplier +50%.",
        "effects": [
            {"type": "crit_multiplier_flat", "value": 0.5}
        ]
    },
    "the_moon": {
        "name": "The Moon",
        "desc": "Intuition. Dodge +10%.",
        "effects": [
            {"type": "dodge_chance_flat", "value": 10.0}
        ]
    },
    "the_sun": {
        "name": "The Sun",
        "desc": "Success. All stats +5%.",
        "effects": [
            {"type": "all_stats_mult", "value": 1.05}
        ]
    },
    "judgement": {
        "name": "Judgement",
        "desc": "Rebirth. Revive once with 50% HP.",
        "effects": [
            {"type": "revive_count_flat", "value": 1}
        ]
    },
    "the_world": {
        "name": "The World",
        "desc": "Completion. All enemies slow down by 10%.",
        "effects": [
            {"type": "enemy_speed_mult", "value": 0.9}
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
