# TeleTarot 可用道具与数值方案（v1.0）

> 项目：TeleTarot-New  
> 日期：2026-04-22  
> 定位：参考同类机制结构，但不复刻内容；直接适配当前代码可识别字段。

---

## 1. 当前可用数值口径（与代码一致）

### 1.1 战斗结算核心

- 护甲减伤：`final_damage = ceil(raw_damage * 100 / (100 + armor * 8))`，最低伤害为 1。
- 闪避：`randf() < dodge_chance` 时本次伤害为 0。
- 暴击：`randf() < crit_chance`，伤害乘 `crit_multiplier`。
- 吸血：`heal = floor(dealt_damage * lifesteal)`。

### 1.2 角色属性硬限制（已在 `player.gd` 中 clamp）

- `armor: -10 ~ 30`
- `dodge_chance: 0.0 ~ 0.6`
- `attack_speed_mult: 0.3 ~ 2.5`
- `crit_chance: 0.0 ~ 0.75`
- `crit_multiplier: 1.5 ~ 3.0`
- `lifesteal: 0.0 ~ 0.25`
- `luck: -20 ~ 100`
- `xp_gain_mult: 1.0 ~ 1.8`

---

## 2. 字段兼容表（避免配错）

### 2.1 `reward_catalog.json` 支持的 `effects[].type`

- `attack_damage_flat`
- `target_range_flat`
- `move_speed_flat`
- `max_hp_flat`
- `heal_flat`
- `stamina_recover_mult`
- `armor_flat`
- `dodge_chance_flat`
- `attack_speed_mult`
- `auto_attack_interval_mult`
- `crit_chance_flat`
- `crit_multiplier_flat`
- `lifesteal_flat`
- `luck_flat`
- `xp_gain_mult`
- `gold_gain_mult`（在 `UpgradeSystem.apply_reward` 特判）

### 2.2 `shop_catalog.json` 的 `item_pool[].effects` 支持键

- `bonus_attack_damage`
- `bonus_target_range`
- `player_move_speed`
- `armor`
- `dodge_chance`
- `attack_speed_mult`
- `crit_chance`
- `crit_multiplier`
- `lifesteal`
- `gold_gain_multiplier`

注意：`shop_catalog` 与 `reward_catalog` 键名不通用，不能混写。

---

## 3. 版本目标（v1.0）

- 早期（stage_001~005）：保证能成型，偏 `common/uncommon`。
- 中期（stage_006~010）：开始引入代价型 `rare`。
- 后期（stage_011~015）：`rare` 主导，少量 `epic` 作为 Build 锁定件。

---

## 4. 奖励池建议（可直接抄到 `reward_catalog`）

### 4.1 建议补全稀有度权重到 15 关

```json
{
  "stage_006": { "common": 0.40, "uncommon": 0.44, "rare": 0.14, "epic": 0.02 },
  "stage_007": { "common": 0.36, "uncommon": 0.45, "rare": 0.16, "epic": 0.03 },
  "stage_008": { "common": 0.33, "uncommon": 0.45, "rare": 0.18, "epic": 0.04 },
  "stage_009": { "common": 0.30, "uncommon": 0.45, "rare": 0.20, "epic": 0.05 },
  "stage_010": { "common": 0.28, "uncommon": 0.44, "rare": 0.22, "epic": 0.06 },
  "stage_011": { "common": 0.26, "uncommon": 0.42, "rare": 0.24, "epic": 0.08 },
  "stage_012": { "common": 0.24, "uncommon": 0.40, "rare": 0.26, "epic": 0.10 },
  "stage_013": { "common": 0.22, "uncommon": 0.38, "rare": 0.28, "epic": 0.12 },
  "stage_014": { "common": 0.20, "uncommon": 0.36, "rare": 0.30, "epic": 0.14 },
  "stage_015": { "common": 0.18, "uncommon": 0.34, "rare": 0.32, "epic": 0.16 }
}
```

### 4.2 新增奖励条目（12 条，非复刻命名）

```json
[
  {
    "id": "atk_flat_2",
    "name": "锋刃校准",
    "desc": "基础攻击伤害 +2",
    "category": "weapon_behavior",
    "rarity": "rare",
    "tags": ["output"],
    "effects": [{ "type": "attack_damage_flat", "value": 2 }],
    "max_stacks": 3,
    "require": { "min_level": 4 }
  },
  {
    "id": "range_up_60",
    "name": "观测延展",
    "desc": "索敌范围 +60",
    "category": "basic_growth",
    "rarity": "uncommon",
    "tags": ["utility"],
    "effects": [{ "type": "target_range_flat", "value": 60 }],
    "max_stacks": 3
  },
  {
    "id": "move_up_10",
    "name": "战术步频",
    "desc": "移动速度 +10",
    "category": "basic_growth",
    "rarity": "uncommon",
    "tags": ["survival", "utility"],
    "effects": [{ "type": "move_speed_flat", "value": 10 }],
    "max_stacks": 4
  },
  {
    "id": "hp_up_4",
    "name": "强化躯壳",
    "desc": "最大生命 +4，并治疗 3",
    "category": "survival_counter",
    "rarity": "uncommon",
    "tags": ["survival"],
    "effects": [
      { "type": "max_hp_flat", "value": 4 },
      { "type": "heal_flat", "value": 3 }
    ],
    "max_stacks": 4
  },
  {
    "id": "armor_up_3",
    "name": "复层护板",
    "desc": "护甲 +3",
    "category": "survival_counter",
    "rarity": "rare",
    "tags": ["survival"],
    "effects": [{ "type": "armor_flat", "value": 3 }],
    "max_stacks": 3,
    "require": { "min_level": 4 }
  },
  {
    "id": "dodge_up_7",
    "name": "瞬断规避",
    "desc": "闪避率 +7%",
    "category": "survival_counter",
    "rarity": "rare",
    "tags": ["survival", "utility"],
    "effects": [{ "type": "dodge_chance_flat", "value": 0.07 }],
    "max_stacks": 3,
    "require": { "min_level": 5 }
  },
  {
    "id": "atk_rate_12",
    "name": "快拆连发",
    "desc": "自动攻击间隔 -8%",
    "category": "weapon_behavior",
    "rarity": "rare",
    "tags": ["output"],
    "effects": [{ "type": "auto_attack_interval_mult", "value": 0.92 }],
    "max_stacks": 3,
    "require": { "min_level": 4 }
  },
  {
    "id": "crit_chance_6",
    "name": "要害捕捉",
    "desc": "暴击率 +6%",
    "category": "weapon_behavior",
    "rarity": "uncommon",
    "tags": ["output"],
    "effects": [{ "type": "crit_chance_flat", "value": 0.06 }],
    "max_stacks": 4
  },
  {
    "id": "crit_multi_22",
    "name": "破点增幅",
    "desc": "暴击倍率 +0.22",
    "category": "weapon_behavior",
    "rarity": "rare",
    "tags": ["output"],
    "effects": [{ "type": "crit_multiplier_flat", "value": 0.22 }],
    "max_stacks": 3,
    "require": { "min_level": 5 }
  },
  {
    "id": "lifesteal_2",
    "name": "回收循环",
    "desc": "吸血 +2%",
    "category": "build_core",
    "rarity": "rare",
    "tags": ["survival", "output"],
    "effects": [{ "type": "lifesteal_flat", "value": 0.02 }],
    "max_stacks": 4,
    "require": { "min_level": 3 }
  },
  {
    "id": "xp_gain_12",
    "name": "学习曲线",
    "desc": "经验收益 +12%",
    "category": "economy_ops",
    "rarity": "uncommon",
    "tags": ["economy", "utility"],
    "effects": [{ "type": "xp_gain_mult", "value": 1.12 }],
    "max_stacks": 4
  },
  {
    "id": "luck_up_10",
    "name": "偏差修正",
    "desc": "幸运 +10",
    "category": "economy_ops",
    "rarity": "uncommon",
    "tags": ["economy", "utility"],
    "effects": [{ "type": "luck_flat", "value": 10 }],
    "max_stacks": 4
  }
]
```

---

## 5. 商店道具池建议（可直接抄到 `shop_catalog.item_pool`）

```json
[
  {
    "item_id": "item_edge_module",
    "name": "Edge Module",
    "description": "Attack damage +2",
    "rarity": "uncommon",
    "base_price": 36,
    "price_wave_scale": 1.05,
    "weight": 0.85,
    "effects": { "bonus_attack_damage": 2 }
  },
  {
    "item_id": "item_scope_array",
    "name": "Scope Array",
    "description": "Target range +35",
    "rarity": "common",
    "base_price": 28,
    "price_wave_scale": 1.04,
    "weight": 0.92,
    "effects": { "bonus_target_range": 35 }
  },
  {
    "item_id": "item_stride_piston",
    "name": "Stride Piston",
    "description": "Move speed +10",
    "rarity": "common",
    "base_price": 30,
    "price_wave_scale": 1.04,
    "weight": 0.9,
    "effects": { "player_move_speed": 10 }
  },
  {
    "item_id": "item_guard_fiber",
    "name": "Guard Fiber",
    "description": "Armor +2",
    "rarity": "uncommon",
    "base_price": 38,
    "price_wave_scale": 1.05,
    "weight": 0.82,
    "effects": { "armor": 2.0 }
  },
  {
    "item_id": "item_phase_boot",
    "name": "Phase Boot",
    "description": "Dodge chance +4%",
    "rarity": "uncommon",
    "base_price": 40,
    "price_wave_scale": 1.05,
    "weight": 0.75,
    "effects": { "dodge_chance": 0.04 }
  },
  {
    "item_id": "item_trigger_relay",
    "name": "Trigger Relay",
    "description": "Attack speed +10%",
    "rarity": "uncommon",
    "base_price": 42,
    "price_wave_scale": 1.05,
    "weight": 0.78,
    "effects": { "attack_speed_mult": 1.10 }
  },
  {
    "item_id": "item_crit_reader",
    "name": "Crit Reader",
    "description": "Crit chance +4%",
    "rarity": "uncommon",
    "base_price": 39,
    "price_wave_scale": 1.05,
    "weight": 0.8,
    "effects": { "crit_chance": 0.04 }
  },
  {
    "item_id": "item_puncture_chip",
    "name": "Puncture Chip",
    "description": "Crit multiplier +0.15",
    "rarity": "rare",
    "base_price": 52,
    "price_wave_scale": 1.06,
    "weight": 0.58,
    "effects": { "crit_multiplier": 0.15 }
  },
  {
    "item_id": "item_blood_sink",
    "name": "Blood Sink",
    "description": "Lifesteal +2%",
    "rarity": "rare",
    "base_price": 50,
    "price_wave_scale": 1.06,
    "weight": 0.56,
    "effects": { "lifesteal": 0.02 }
  },
  {
    "item_id": "item_trade_voucher",
    "name": "Trade Voucher",
    "description": "Gold gain +12%",
    "rarity": "uncommon",
    "base_price": 44,
    "price_wave_scale": 1.05,
    "weight": 0.7,
    "effects": { "gold_gain_multiplier": 1.12 }
  },
  {
    "item_id": "item_glass_loop",
    "name": "Glass Loop",
    "description": "ATK +3, Armor -1",
    "rarity": "rare",
    "base_price": 54,
    "price_wave_scale": 1.06,
    "weight": 0.45,
    "effects": { "bonus_attack_damage": 3, "armor": -1.0 }
  },
  {
    "item_id": "item_anchor_frame",
    "name": "Anchor Frame",
    "description": "Armor +3, Attack speed -6%",
    "rarity": "rare",
    "base_price": 55,
    "price_wave_scale": 1.06,
    "weight": 0.43,
    "effects": { "armor": 3.0, "attack_speed_mult": 0.94 }
  }
]
```

---

## 6. 联调阈值（上线前检查）

- stage_005 目标：平均可承受触碰次数 `>= 6`。
- stage_010 目标：3 选 1 中至少有 2 个不同轴标签。
- stage_015 目标：通关构筑中，`output/survival` 两轴都至少有 1 个核心词条。
- 暴击流上限检查：`crit_chance <= 0.75`，`crit_multiplier <= 3.0`。
- 闪避流上限检查：`dodge_chance <= 0.6` 且不应成为唯一生存手段。

---

## 7. 实施顺序

1. 先补 `reward_catalog` 的 `stage_006~015` 稀有度权重。  
2. 再追加本方案 12 条奖励。  
3. 再扩容商店 `item_pool` 为 12~18 条。  
4. 最后打两轮平衡：`stage_001~005` 新手曲线、`stage_010~015` 后期压力。

该方案是“可执行基线”，后续按实测数据微调权重与价格，不需要回到复刻路径。
