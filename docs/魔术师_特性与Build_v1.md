# 魔术师_特性与Build_v1

> 版本：v1.0  
> 日期：2026-04-15  
> 关联基线：`docs/产品基线_v1.3.md`  
> 关联文档：`docs/角色系统设计.md`、`docs/数值模型设计.md`、`docs/关卡与流程设计_v2_奖励与属性.md`

---

## 1. 角色定位与风险画像
- 定位：技能循环与触发资源的节奏型输出，擅长“稳定滚动成长”。
- 强势期：`stage_002~004`（奖励池成型后压制感明显）。
- 弱势期：`stage_001` 前半（未成型时清图速度一般）。
- 失败点：过度堆功能项导致单次爆发不足，Boss-1 P3 收尾慢。

## 2. Lv1 低数值基线（v2.1口径）
- `character_id`: `the_magician`
- `HP = 8`
- `基础伤害 = 6`
- 初始倾向：中速移速、较高索敌范围、资源恢复偏稳。

## 3. 核心机制定义
### 3.1 被动：奥术回路
- 每累计 4 次命中，下一次自动攻击附带“额外命中形态”（优先穿透/分裂修饰）。
- 战术价值：在不抬高基础伤害的前提下提升清图效率。
- 反协同：与纯防御堆叠路线冲突（触发频率不足）。

### 3.2 主动：速咏脉冲
- 主动释放后短时提高攻击频率，结束后进入短冷却。
- 触发窗口：精英出现、Boss 转阶段、被包夹时拉开节奏。
- 反制关系：可对抗高密刷怪窗口，但不适合长时间硬拖战。

## 4. Build 路线（4条）
### 4.1 稳定主线 Build（推荐）
- `build_id`: `magician_stable_core`
- 核心思路：稳定触发被动，持续压制中近距离目标。
- `core_rewards`: `attack_speed_up`, `pierce_plus`, `resource_cycle_up`, `base_damage_up`
- `support_rewards`: `pickup_radius_up`, `shield_periodic`
- `stat_targets`：攻击强度 `+25%~+40%`，攻频 `+30%~+50%`，生存 `+20%~+35%`
- 不推荐组合：纯经济三连（前中期输出断档）。

### 4.2 高风险高回报 Build
- `build_id`: `magician_glass_loop`
- 核心思路：放大命中形态与攻频，以最短时间清屏。
- `core_rewards`: `split_shot`, `attack_speed_up`, `glass_engine`, `crit_like_proc`
- `support_rewards`: `dash_recover`, `short_shield`
- `stat_targets`：攻击 `+40%~+60%`，攻频 `+45%~+70%`，生存 `+10%~+20%`
- 反协同：高波次下缺少减伤会直接崩盘。

### 4.3 生存反制 Build
- `build_id`: `magician_counter_survival`
- 核心思路：用受击反制和护盾维持站场，降低操作压力。
- `core_rewards`: `max_hp_up`, `damage_reduction_short`, `hit_recovery`, `shield_periodic`
- `support_rewards`: `attack_speed_up`, `economy_small`
- `stat_targets`：生存 `+40%~+70%`，攻击 `+15%~+30%`
- 反协同：清图速度慢，需补至少 1 个武器行为项。

### 4.4 Boss-1 定向 Build
- `build_id`: `magician_boss1_focus`
- 核心思路：维持稳定输出窗口，规避 P2/P3 压制。
- `core_rewards`: `boss_tag_damage`, `pierce_plus`, `cooldown_cut`, `damage_reduction_short`
- `support_rewards`: `stamina_cycle`, `hp_buffer`
- `stat_targets`：Boss输出 `+35%~+50%`，生存 `+25%~+40%`
- 失败补救：若输出不足，优先补 `attack_strength` 而非继续堆功能。

## 5. Chapter I 分关策略（stage_001~005）
- `stage_001`：先拿 1 生存 + 1 输出，确保不会被早期远程压血。
- `stage_002`：优先成型一次被动循环（攻频或命中形态二选一先拉满）。
- `stage_003`：补中期续航（资源循环/护盾），避免精英窗口断节奏。
- `stage_004`：对齐 Boss 前配置，优先“减伤 + 稳定输出”。
- `stage_005`：P1 攒资源，P2 开主动抢节奏，P3 保命优先。

## 6. 参数锚点与脚本映射
### 6.1 可直接映射（现有字段）
- `player.gd`: `max_hp`, `move_speed`, `bonus_attack_damage`, `bonus_target_range`, `stamina_recover_per_sec`
- `game_scene.gd`: `_xp_multiplier`, `_gold_multiplier`, `_enemy_hp_multiplier`, `_enemy_damage_multiplier`
- `upgrade_system.gd`: 奖励条目分类、权重与选择应用入口

### 6.2 待新增（实现缺口）
- `arcane_stack_count`（命中累计计数）
- `spellburst_window_sec`（主动增幅窗口）
- `on_hit_proc_profile`（命中形态附加规则）

## 7. MVP 落地顺序
1. 先做低风险版本：被动仅改“每N次命中+少量额外伤害”。
2. 再接入命中形态扩展（穿透/分裂）。
3. 最后补主动技能和提示表现。
4. 用 `stage_004~005` 做稳定性回归。