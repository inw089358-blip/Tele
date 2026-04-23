# 土豆兄弟道具到 TeleTarot 标签体系重映射说明

生成日期：2026-04-22（增强版：Tag + Effects 双信号）

输出文件：
- docs/土豆兄弟_全道具_TeleTarot重映射.csv
- docs/土豆兄弟_全道具_TeleTarot重映射.json

总条目：231

## 类别分布

| tele_category | count |
|---|---:|
| build_core | 104 |
| economy_ops | 12 |
| rhythm_resource | 8 |
| survival_counter | 35 |
| weapon_behavior | 72 |

## 标签分布

| tele_tag | count |
|---|---:|
| economy | 58 |
| output | 159 |
| survival | 120 |
| utility | 128 |

## 规则
1. 稀有度：Tier1/2/3/4 -> common/uncommon/rare/epic。
2. 分类采用 Tag 与 Effects 关键词双信号。
3. 经济纯项 -> economy_ops；生存纯项 -> survival_counter；输出纯项 -> weapon_behavior；功能纯项 -> rhythm_resource。
4. 混合项（如输出+生存、经济+战斗）统一归为 build_core。
