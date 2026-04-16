# 愚者_特性与Build_v2

> 版本：v2.1  
> 日期：2026-04-14  
> 关联基线：`docs/产品基线_v1.3.md`  
> 关联文档：`docs/角色系统设计.md`、`docs/数值模型设计.md`、`docs/关卡与流程设计_v2_奖励与属性.md`

---

## 1. 低数值规则说明
- Lv1 基线：`HP 9 / 基础伤害 6`。
- 低数值阶段优先级：先`生存容量/恢复续航`，再`攻频/命中形态`。

## 2. 角色定位与风险画像
- 定位：广域命中 + 节奏平滑 + 经济滚雪球。
- 强势期：`stage_001~003`。
- 失败点：Boss 前输出补强不足。

## 3. Build 路线（4条）

### 3.1 稳定主线 Build（推荐）
- 核心：`base_damage_up`、`attack_speed_up`、`pickup_radius_up`
- 中后期补：`pierce_plus`、`shield_periodic`
- 目标区间：生存容量 `+15%~+35%`，攻击强度 `+20%~+40%`
- 早期策略：先保命再输出。

### 3.2 高风险高回报 Build
- 核心：`attack_speed_up`、`split_shot`、`glass_engine`
- 目标区间：攻击强度 `+35%~+55%`，攻频 `+40%~+65%`
- 风险提示：无护盾/恢复时易崩盘。

### 3.3 生存反制 Build
- 核心：`max_hp_up`、`shield_periodic`、`hit_recovery`
- 目标区间：生存容量 `+35%~+70%`
- 风险提示：纯生存会拖慢 Boss 输出。

### 3.4 Boss-1 定向 Build
- 核心：`boss_tag_damage`、`pierce_plus`、`damage_reduction_short`
- 前提：敌方伤害采用 v2.1 下调口径（普通1，远程/精英2，Boss2~3）
- 目标区间：输出 `+35%~+50%` + 生存 `+20%~+40%`

## 4. 关卡阶段打法（stage_001~005）
- `stage_001`：先拿 1 生存 + 1 输出。
- `stage_002`：对远程单位优先清理。
- `stage_003`：补单体有效项。
- `stage_004`：维持走位，避免全功能抽牌。
- `stage_005`：P2/P3 以存活优先。

## 5. 可落地参数锚点（文档）
- 角色 Lv1：`HP 9 / 伤害 6`
- 建议敌方口径：普通接触1、远程/精英2、Boss接触2~3；普通子弹1、精英/Boss子弹2。

## 6. 脚本映射
- 现有字段：`player.gd` 的 `max_hp`、`bonus_attack_damage`、`move_speed`、`pickup_radius`。
- 现有结算：`game_scene.gd` 的 `_xp_multiplier`、`_gold_multiplier`。
- 待扩展：`boss_tag_damage`、核心池前置条件。

## 7. MVP 落地顺序（文档级）
1. 先落实“稳定主线”与“Boss定向”奖励ID。
2. 再加高风险分支与约束。
3. 用 `stage_004~005` 验证稳定性。
