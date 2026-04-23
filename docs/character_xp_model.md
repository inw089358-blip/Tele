# 角色经验成长模型（项目实装版）

## 目标
- 采用二次曲线经验需求，替代旧指数曲线。
- 稀有度不影响经验曲线，角色差异通过 `xp_required_mult` 控制。
- 存档默认值与战斗运行时使用同一公式，避免读档后经验阈值漂移。

## 经验需求公式
设当前等级为 `L`（从 1 开始），则升级所需经验：

`XPRequired(L) = max(xp_required_min, round((L + xp_curve_level_offset)^2 * xp_curve_base_multiplier * xp_required_mult))`

参数来源：
- 全局：`data/balance/combat_balance.json -> global.combat`
- 角色：`data/balance/combat_balance.json -> characters.<id>.xp_required_mult`

## 当前配置
全局（`global.combat`）：
- `xp_curve_level_offset = 3`
- `xp_curve_base_multiplier = 6.0`
- `xp_required_min = 1`

角色（`characters`）：
- `the_fool.xp_required_mult = 1.0`
- `the_chariot.xp_required_mult = 1.08`
- `the_hanged_man.xp_required_mult = 0.94`

## 代码接入点
- 战斗运行时：`scripts/ui/game_scene.gd`
  - `_xp_required_for_level(current_level)`
  - `_resolve_character_xp_required_multiplier(character_id)`
  - `_spawn_player()` / `_reset_progress_state()` 中刷新 `_xp_required_multiplier_runtime`
- 存档归一化：`scripts/autoload/save_system.gd`
  - `_xp_required_for_level(current_level, xp_required_mult)`
  - `_resolve_character_xp_required_multiplier(character_id)`
  - `_normalize_save_data()` 里按选中角色计算 `xp_to_next_default`

## 调参建议
- 想要整体升级更慢：提高 `xp_curve_base_multiplier`。
- 想要前期更平滑、后期更陡：提高 `xp_curve_level_offset`（同时可略降 `xp_curve_base_multiplier`）。
- 想做角色学习成本差异：调 `xp_required_mult`（建议范围 0.85 ~ 1.15）。

## 第三轮实测调参结论（等级上限目标）
- 目标：`stage_012` 时角色等级不超过 13 级。
- 将 `xp_curve_base_multiplier` 调整为 `6.0`。
- 按当前关卡配置估算：
  - 中位击杀效率（`kill_eff=0.8`）：`12/12/12`（愚者/战车/倒吊人）
  - 高击杀效率（`kill_eff=1.0`）：`13/12/13`（愚者/战车/倒吊人）
