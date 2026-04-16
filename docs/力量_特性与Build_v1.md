# 力量_特性与Build_v1

> 版本：v1.0  
> 日期：2026-04-15  
> 关联基线：`docs/产品基线_v1.3.md`  
> 关联文档：`docs/角色系统设计.md`、`docs/数值模型设计.md`、`docs/关卡与流程设计_v2_奖励与属性.md`

---

## 1. 角色定位与风险画像
- 定位：近距压制与受击收益角色，偏“越打越硬”。
- 强势期：`stage_003~005`（生存反制池成型后显著变强）。
- 弱势期：`stage_001~002`（远程怪较多时贴脸难度高）。
- 失败点：过分追求坦度导致清怪效率过低，被远程拉扯。

## 2. Lv1 低数值基线（v2.1口径）
- `character_id`: `strength`
- `HP = 9`
- `基础伤害 = 5`
- 初始倾向：较低移速、较高生存容量、近战偏好。

## 3. 核心机制定义
### 3.1 被动：狮心硬化
- 每次受击获得短时减伤层（上限3层），鼓励“可控换血”。
- 战术价值：高压窗口能稳住阵型，不易猝死。
- 反协同：与极限风筝打法冲突（层数利用率低）。

### 3.2 主动：震地猛扑
- 向前短突进并造成范围压制伤害，附带短硬直。
- 触发窗口：被包围时开路、Boss 转阶段抢站位。
- 反制关系：克制密集近战波，但需规避远程集火。

## 4. Build 路线（4条）
### 4.1 稳定主线 Build（推荐）
- `build_id`: `strength_stable_frontline`
- 核心思路：坦度先行，输出靠稳定命中堆起来。
- `core_rewards`: `max_hp_up`, `damage_reduction_short`, `attack_strength_up`, `hit_recovery`
- `support_rewards`: `move_speed_small`, `pickup_radius_up`
- `stat_targets`：生存 `+45%~+75%`，攻击 `+20%~+35%`
- 不推荐组合：纯经济路线（前期压力过高）。

### 4.2 高风险高回报 Build
- `build_id`: `strength_berserk_trade`
- 核心思路：低血换高伤，利用受击后短爆发清场。
- `core_rewards`: `low_hp_damage_up`, `attack_speed_up`, `life_steal_small`, `burst_window`
- `support_rewards`: `panic_shield`, `stamina_cycle`
- `stat_targets`：攻击 `+45%~+65%`，生存 `+20%~+30%`
- 风险提示：血线管理要求高，不适合新手硬抄。

### 4.3 生存反制 Build
- `build_id`: `strength_reflect_guard`
- 核心思路：把挨打转成收益（反伤/回能/减伤）。
- `core_rewards`: `thorns_like`, `shield_periodic`, `hit_recovery`, `armor_stack`
- `support_rewards`: `base_damage_up`, `xp_gain_small`
- `stat_targets`：生存 `+60%~+90%`，攻击 `+10%~+25%`
- 反协同：Boss 长轴机制中纯反制收益下降。

### 4.4 Boss-1 定向 Build
- `build_id`: `strength_boss1_anchor`
- 核心思路：确保 P2/P3 不暴毙，再用突进抢输出窗口。
- `core_rewards`: `boss_tag_damage`, `damage_reduction_short`, `hp_buffer`, `cooldown_cut`
- `support_rewards`: `stamina_recover`, `single_target_boost`
- `stat_targets`：生存 `+40%~+65%`，Boss输出 `+30%~+45%`
- 失败补救：若时间超时风险高，优先补单体增伤。

## 5. Chapter I 分关策略（stage_001~005）
- `stage_001`：优先拿生存与移速小补，避免前期被远程拉死。
- `stage_002`：开始补伤害，保证清图节奏不掉。
- `stage_003`：形成“受击收益 + 护盾”双保险。
- `stage_004`：模拟 Boss 节奏，突进技能只在安全窗口用。
- `stage_005`：P2/P3 把主动留给高压期，不贪平A站桩。

## 6. 参数锚点与脚本映射
### 6.1 可直接映射（现有字段）
- `player.gd`: `max_hp`, `move_speed`, `bonus_attack_damage`, `stamina_max`, `stamina_recover_per_sec`
- `game_scene.gd`: `enemy_damage`乘区、奖励结算乘区、关卡结算流
- `upgrade_system.gd`: 奖励池分类（生存反制池、基础成长池）

### 6.2 待新增（实现缺口）
- `damage_taken_stack`（受击层）
- `guard_reduction_per_stack`（每层减伤系数）
- `slam_skill_profile`（主动技能参数）

## 7. MVP 落地顺序
1. 先实现被动减伤层。
2. 再接“受击收益”奖励条目。
3. 最后上主动位移压制技能。
4. 用 `stage_003~005` 做闭环验证。