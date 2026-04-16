# 节制_特性与Build_v1

> 版本：v1.0  
> 日期：2026-04-15  
> 关联基线：`docs/产品基线_v1.3.md`  
> 关联文档：`docs/角色系统设计.md`、`docs/数值模型设计.md`、`docs/关卡与流程设计_v2_奖励与属性.md`

---

## 1. 角色定位与风险画像
- 定位：双态切换与持续续航角色，强调“稳态运营”。
- 强势期：全阶段稳定，尤其 `stage_002~005` 控场优秀。
- 弱势期：极限爆发不足，清图上限不如纯输出角色。
- 失败点：切态节奏错误导致关键窗口输出/生存都不达标。

## 2. Lv1 低数值基线（v2.1口径）
- `character_id`: `temperance`
- `HP = 8`
- `基础伤害 = 7`
- 初始倾向：中等移速，较高续航，功能和经济协同稳定。

## 3. 核心机制定义
### 3.1 被动：均衡流
- 每隔固定时间在“攻势态/守势态”间可切换，切换后获得短时增益。
- 攻势态：提高攻击频率与命中形态效果。
- 守势态：提高减伤与恢复效率。
- 反协同：长时间单态停留会损失角色设计价值。

### 3.2 主动：调和结界
- 释放短时结界，对范围内敌人施加减速并提升自身回复。
- 触发窗口：精英压场、Boss 弹幕高峰、低血撤退。
- 反制关系：抑制远程怪密集区域，适合稳扎稳打。

## 4. Build 路线（4条）
### 4.1 稳定主线 Build（推荐）
- `build_id`: `temperance_balanced_main`
- 核心思路：攻守双态都能吃到收益，维持稳定推进。
- `core_rewards`: `attack_speed_up`, `max_hp_up`, `resource_cycle_up`, `cooldown_cut`
- `support_rewards`: `gold_gain_small`, `pickup_radius_up`
- `stat_targets`：攻击 `+25%~+40%`，生存 `+25%~+45%`，资源循环 `+20%~+35%`

### 4.2 高风险高回报 Build
- `build_id`: `temperance_cycle_burst`
- 核心思路：频繁切态叠短增益，打高密短爆发。
- `core_rewards`: `state_swap_bonus`, `attack_speed_up`, `split_shot`, `low_hp_damage_up`
- `support_rewards`: `panic_shield`, `stamina_cycle`
- `stat_targets`：攻击 `+40%~+60%`，生存 `+15%~+30%`
- 风险提示：操作密度高，容错低。

### 4.3 生存反制 Build
- `build_id`: `temperance_guarded_flow`
- 核心思路：守势态拉满续航，靠稳定伤害磨过高压波次。
- `core_rewards`: `shield_periodic`, `hit_recovery`, `damage_reduction_short`, `hp_regen_small`
- `support_rewards`: `base_damage_up`, `economy_small`
- `stat_targets`：生存 `+45%~+75%`，攻击 `+15%~+30%`

### 4.4 Boss-1 定向 Build
- `build_id`: `temperance_boss1_control`
- 核心思路：用调和结界控制 P2/P3 风险，保持稳定 DPS。
- `core_rewards`: `boss_tag_damage`, `cooldown_cut`, `damage_reduction_short`, `single_target_boost`
- `support_rewards`: `stamina_recover`, `hp_buffer`
- `stat_targets`：Boss输出 `+30%~+45%`，生存 `+30%~+50%`
- 失败补救：若 P3 压力大，优先补减伤/恢复而非继续提攻速。

## 5. Chapter I 分关策略（stage_001~005）
- `stage_001`：先用守势态稳血，快速拿到第一个输出项。
- `stage_002`：开始练习切态节奏（开战攻势、受压守势）。
- `stage_003`：补控制与资源项，准备精英连战。
- `stage_004`：将结界留给远程密集波次。
- `stage_005`：Boss P2/P3 切守势保命，窗口期切攻势追伤害。

## 6. 参数锚点与脚本映射
### 6.1 可直接映射（现有字段）
- `player.gd`: `max_hp`, `move_speed`, `bonus_attack_damage`, `stamina_recover_per_sec`, `bonus_target_range`
- `game_scene.gd`: 难度乘区、敌方伤害乘区、阶段结算奖励
- `upgrade_system.gd`: 奖励池抽样、分类权重、软保底

### 6.2 待新增（实现缺口）
- `stance_mode`（攻势/守势状态）
- `stance_swap_cd`（切换冷却）
- `aura_zone_profile`（主动结界参数）

## 7. MVP 落地顺序
1. 先做双态切换（纯数值层，先不加特效）。
2. 再接结界技能（减速 + 回复）。
3. 最后补奖励池联动词条与UI提示。
4. 用 `stage_004~005` 做 Boss 前后稳定性验收。
