# 通用道具Build总表_v2

> 版本：v2.1  
> 日期：2026-04-14  
> 关联基线：`docs/产品基线_v1.3.md`  
> 关联文档：`docs/角色系统设计.md`、`docs/数值模型设计.md`、`docs/关卡与流程设计_v2_奖励与属性.md`

---

## 1. 低数值规则说明

- Chapter I 采用低数值实验基线：
- 愚者 `HP9/伤害6`，战车 `HP8/伤害7`，倒吊人 `HP7/伤害8`。
- 敌方伤害建议：普通接触1、远程/精英2、Boss接触2~3；普通子弹1、精英/Boss子弹2。
- 低数值阶段道具优先级：`生存/续航 > 输出乘区 > 经济收益`。

## 2. 道具分类索引

- 输出：`base_damage_up`、`attack_speed_up`、`boss_tag_damage`
- 生存：`max_hp_up`、`shield_periodic`、`damage_reduction_short`、`hit_recovery`
- 功能：`move_speed_up`、`control_resist`、`pierce_plus`
- 经济：`xp_gain_up`、`gold_gain_up`、`hub_discount`
- 核心：`glass_engine`、`fortress_cycle`、`tempo_overdrive`

## 3. Chapter I 速查卡（低数值口径）

- `stage_001`：先拿 1 生存 + 1 输出，避免开局崩盘。
- `stage_002`：补反制（护盾/减伤）应对远程压制。
- `stage_003`：补单体有效项（Boss 预埋）。
- `stage_004`：输出与生存平衡，不走纯经济。
- `stage_005`：至少满足“2 输出 + 1 生存”后再贪核心。

## 4. 低数值风险提示

- 禁止三连纯输出抽取（低HP体系下波动过大）。
- 若两次连续低血，下一次候选应强制加入生存项（软保底）。
- Boss-1 前纯经济 build 风险极高。

## 5. 实现映射附录（文档）

- 现有字段：`max_hp`、`bonus_attack_damage`、`move_speed`、`_xp_multiplier`、`_gold_multiplier`。
- 待扩展：低血标签、Boss 标签伤害、候选软保底状态。
