# 战车_特性与Build_v2

> 版本：v2.1  
> 日期：2026-04-14  
> 关联基线：`docs/产品基线_v1.3.md`  
> 关联文档：`docs/角色系统设计.md`、`docs/数值模型设计.md`、`docs/关卡与流程设计_v2_奖励与属性.md`

---

## 1. 低数值规则说明
- Lv1 基线：`HP 8 / 基础伤害 7`。
- 先保资源循环，再冲爆发。

## 2. 角色定位与风险画像
- 定位：机动换爆发 + 穿透直线清场 + 资源管理。
- 强势期：`stage_002~004`。
- 失败点：站桩导致节奏断档。

## 3. Build 路线（4条）

### 3.1 稳定主线 Build（推荐）
- 核心：`move_speed_up`、`base_damage_up`、`skill_cd_down`
- 目标区间：攻击 `+25%~+45%`，资源循环成型 1 条
- 早期策略：先保命再输出。

### 3.2 高风险高回报 Build
- 核心：`tempo_overdrive`、`combo_haste`、`boss_tag_damage`
- 目标区间：攻击 `+40%~+60%`
- 风险提示：空窗期明显，需操作兜底。

### 3.3 生存反制 Build
- 核心：`max_hp_up`、`shield_periodic`、`damage_reduction_short`
- 目标区间：生存 `+30%~+65%`
- 风险提示：输出不足会拖长 Boss 战。

### 3.4 Boss-1 定向 Build
- 核心：`pierce_plus`、`boss_tag_damage`、`hit_recovery`
- 前提：采用 v2.1 敌方伤害下调口径。
- 目标区间：输出 `+35%~+50%` + 生存 `+20%~+40%`

## 4. 关卡阶段打法（stage_001~005）
- `stage_001`：先成型机动与基础输出。
- `stage_002`：优先压制远程簇。
- `stage_003`：补 CD/体力，减少空窗。
- `stage_004`：输出与生存至少各 1 项。
- `stage_005`：爆发留给相位转换窗口。

## 5. 可落地参数锚点（文档）
- 角色 Lv1：`HP 8 / 伤害 7`
- 敌方建议：普通接触1，远程/精英2，Boss接触2~3；普通子弹1，精英/Boss子弹2。

## 6. 脚本映射
- 现有字段：`max_hp`、`move_speed`、`bonus_attack_damage`、`stamina_recover_per_sec`、`dash_cost`。
- 待扩展：动能条分段、Boss标签伤害。

## 7. MVP 落地顺序（文档级）
1. 优先上穿透与CD奖励。
2. 再接生存反制与风险分支。
3. 用 `stage_005` 验证 Boss 时长。
