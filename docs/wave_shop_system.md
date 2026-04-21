# 波间商店系统实现文档（Brotato布局）

## 1. 已实现范围
- 战斗改为多波流程：`Wave N` 结束后（非最终波）进入全屏商店，点击“Start Next Wave”进入 `Wave N+1`。
- 状态连续继承：等级、经验、属性、金币、武器槽会在波次之间与下一关之间持续保留，不再重置。
- 商店为独立场景：顶部资源栏、中部 4 卡位商品区、右侧属性摘要、底部 6 武器槽与“下一波”按钮。
- 武器系统支持：6 槽装备、满槽替换、基础 2 合 1 升阶（同武器同稀有度）。
- 存档扩展：包含 `wave_progress_index`、`shop_runtime_state`、`equipped_weapons`、`locked_shop_offers`。

## 2. 核心流程
1. `GameScene` 波次计时结束调用 `_on_wave_time_up()`
2. 清场并发放波次奖励（金币/经验）
3. `WaveManager.advance_wave_or_open_shop(snapshot)`：
   - 最终波：返回 `stage_complete`
   - 非最终波：`GameManager.open_wave_shop(snapshot)`
4. `ShopScene` 读取 `GameManager.consume_pending_shop_snapshot()`
5. 玩家购物后 `GameManager.continue_from_shop(snapshot)` 回战斗场景
6. 新战斗场景使用快照恢复状态，进入下一波

## 3. 新增/更新接口

### `WaveManager` (`scripts/systems/wave_manager.gd`)
- `advance_wave_or_open_shop(runtime_snapshot: Dictionary) -> Dictionary`
- `is_final_wave() -> bool`
- `build_wave_runtime_snapshot(base_snapshot: Dictionary) -> Dictionary`
- 支持从 `stages.*.waves[]` 读取多波配置（兼容旧 `spawn_profile.target_duration` 回退）

### `GameManager` (`scripts/autoload/game_manager.gd`)
- `open_wave_shop(snapshot: Dictionary) -> void`
- `consume_pending_shop_snapshot() -> Dictionary`
- `continue_from_shop(snapshot: Dictionary) -> void`
- 兼容方法：`consume_pending_hub_snapshot()`、`continue_from_hub()`

### `ShopSystem` (`scripts/systems/shop_system.gd`)
- `roll_shop_offers(context: Dictionary) -> Array[Dictionary]`
- `purchase_offer(offer_id: String, state: Dictionary) -> Dictionary`
- `merge_weapons_if_possible(state: Dictionary) -> Dictionary`

## 4. 新增资源
- 商店场景：`scenes/shop_scene.tscn`
- 商店脚本：`scripts/ui/shop_scene.gd`
- 商店系统：`scripts/systems/shop_system.gd`
- 商店配置：`data/balance/shop_catalog.json`

## 5. 关键数据结构

### `shop_runtime_state`
```json
{
  "equipped_weapons": [{}, {}, {}, {}, {}, {}],
  "inventory_overflow": [],
  "locked_shop_offers": [],
  "refresh_count": 0,
  "shop_locked": false
}
```

### 存档扩展字段
- `wave_progress_index`
- `current_gold`
- `shop_runtime_state`
- `equipped_weapons`
- `locked_shop_offers`

## 6. 平衡配置入口

### `data/balance/combat_balance.json`
- `stages.*.waves[]` 已接入：
  - `duration`
  - `reward_gold`
  - `reward_xp`
  - `shop_enabled`

### `data/balance/shop_catalog.json`
- `shop_rules`
- `merge_rules`
- `item_pool`
- `weapon_pool`

## 7. 回归测试建议
- 连续通过两波后检查：等级、经验、属性、金币、武器槽是否继承。
- 商店购买后进入下一波，属性是否即时生效。
- 满 6 槽购买武器时：可替换、可合成路径是否正常。
- 存档/读档后是否能回到正确波次与正确商店运行态。
