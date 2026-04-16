# 🧑‍🚀 九、补给站 NPC 立绘与静态交互精灵提示词

## 📋 项目视觉核心参数（继承）

| 参数 | 值 |
|------|-----|
| **艺术风格** | 梦核故障艺术 (Dreamcore Glitch Aesthetics) |
| **视角** | 俯视2D (Top-down) |
| **渲染风格** | 像素艺术 + CRT 后处理痕迹 |
| **设计分辨率** | 1280×720 (16:9) |
| **主背景色** | `#0a1628` 深空蓝 |
| **强调色系** | 信号绿 `#00ff41` / 故障紫 `#b967ff` / 干扰红 `#ff0040` / 青色 `#00ffff` |

---

### 【NPC01】女巫 (Witch) - 恢复与强化

#### 📐 立绘提示词（非卡牌）

```text
PROMPT: Full-body character portrait of "Witch" NPC from Tarot Dreamscape supply hub
STYLE: Pixel art, dreamcore glitch aesthetics, production-ready in-game character asset
ROLE: Recovery and upgrade vendor, ritual healer-engineer hybrid

DESCRIPTION:
- Standalone character composition, centered, transparent background
- Slim silhouette with asymmetrical layered robe, signal-thread embroidery, and ritual utility belt
- Signature accessory: floating vial lanterns with green glow indicating healing services
- Left hand holds a rune-tuning tool, right hand shows an open palm with soft repair particles
- Face partly shadowed by hood, calm but observant expression
- Hair and cloth edges include subtle RGB split and scanline-like breakup
- Boots and gloves look practical, stitched with patchwork techno-occult motifs
- Add 1-2 tiny hovering charm drones near shoulder level (non-weapon utility)

COLOR PALETTE:
- Main cloth: deep plum and violet (#3a1f4f, #5a2d72)
- Healing glow: signal green (#00ff41) with cyan edge (#00ffff)
- Accent glitch: magenta/pink noise (#b967ff, #ff0040)
- Metal parts: dark steel blue (#2d3f5c)
- Skin tone: pale cool tone (#d9c9dd)

TECHNICAL SPECS:
- Portrait ratio: 3:4, target 768×1024px
- Crisp pixel clusters, medium detail, game readability first
- Strong silhouette readability on dark UI background
- Transparent background PNG

MOOD: Quietly mystical, reliable, restorative, surgical ritual vibe
```

中文说明：
- 关键词聚焦“修复/强化”的服务感，不做战斗施法动作。
- 轮廓上使用披袍 + 药剂灯，保证与其他 NPC 一眼区分。

#### 🎮 静态交互精灵图提示词（无攻击动作）

```text
PROMPT: Top-down NPC interaction sprite sheet for "Witch" in Tarot Dreamscape supply hub
VIEW: Direct top-down, non-combat NPC sheet
USAGE: Hub interaction only (talk, trade, upgrade), not battle

DESCRIPTION:
- Compact top-down robe silhouette with hood peak clearly readable
- Green healing vials orbit slightly during idle
- One hand gesture for "blessing/upgrade confirmation"
- Keep visual center stable for UI dialogue overlays

ANIMATION SET (NON-COMBAT):
1. Idle (4 frames): gentle breathing + vial glow pulse
2. Turn (4 directions, 2 frames each): N/E/S/W facing pivots
3. Talk/Gesture (4 frames): hand and sleeve motion, subtle head nod
4. Trade/Offer (4 frames): presents glowing vial and upgrade sigil

TECHNICAL SPECS:
- Base size: 56×56px per frame
- Sprite sheet grid, transparent background
- Center-aligned pivot, stable foot anchor
- Max 18 colors, clean readability on #0a1628 background
```

```text
NEGATIVE PROMPT:
Tarot card frame, card border, text watermark, photorealism, cinematic background scene,
combat pose, weapon swing, attack animation, hit reaction, death animation, blood, gore
```

```text
CONSISTENCY LOCK:
- same witch silhouette family (hood + layered robe + vial lanterns)
- same palette family (violet + green healing glow)
- same top-down facing logic and body proportions
- same outfit structure and accessory placement across all frames
```

---

### 【NPC02】裂隙旅者 (Rift Traveler) - 道具交易

#### 📐 立绘提示词（非卡牌）

```text
PROMPT: Full-body character portrait of "Rift Traveler" NPC from Tarot Dreamscape supply hub
STYLE: Pixel art, dreamcore glitch aesthetics, practical merchant-adventurer visual language
ROLE: Item trader carrying cross-rift supplies and utility goods

DESCRIPTION:
- Standalone full-body portrait, transparent background, no frame
- Broad cloak silhouette with layered travel gear and dimensional backpack rig
- Backpack includes strapped crates, folded maps, spare modules, and sealed containers
- One hand points to a hovering inventory hologram tile, the other secures cargo strap
- Scarf tail and cloak hem show mild glitch tearing and chromatic separation
- Face is partially visible: weathered, focused, trustworthy wanderer
- Belt contains utility pouches, tags, and tiny beacon lights
- Add subtle rift dust particles near boots, hinting recent traversal

COLOR PALETTE:
- Cloak base: slate blue and muted cyan (#2e4c66, #3d6f8f)
- Cargo accents: amber and warm gray (#c28b4a, #8b9bb4)
- Rift accents: cyan and magenta (#00ffff, #b967ff)
- Deep shadow: navy (#0a1628)
- Utility lights: signal green (#00ff41)

TECHNICAL SPECS:
- Portrait ratio: 3:4, target 768×1024px
- Medium-detail pixel art, readable at UI scale
- Transparent background PNG
- Clear gear silhouette; avoid noisy over-detail

MOOD: Road-worn, resourceful, efficient, dimension-hopping trader
```

中文说明：
- 强调“补给商人”的功能语义：背包系统、货箱、库存投影。
- 形体偏三角披风+大背包，和女巫、先知、经纪人形成明显差异。

#### 🎮 静态交互精灵图提示词（无攻击动作）

```text
PROMPT: Top-down NPC interaction sprite sheet for "Rift Traveler" in Tarot Dreamscape supply hub
VIEW: Direct top-down, non-combat NPC sheet
USAGE: Hub item shop interaction only

DESCRIPTION:
- Top-down cloak + large backpack read clearly as merchant silhouette
- Cargo strap and side pouches visible from above
- Offer gesture includes opening a small crate or showing an item module
- Motion remains grounded and practical, no combat theatrics

ANIMATION SET (NON-COMBAT):
1. Idle (4 frames): slight sway from backpack weight, tiny beacon blink
2. Turn (4 directions, 2 frames each): N/E/S/W pivot with bag rotation
3. Talk/Gesture (4 frames): one-arm presentation and nodding
4. Trade/Offer (4 frames): opens crate lid and displays item chip

TECHNICAL SPECS:
- Base size: 56×56px per frame
- Sprite sheet grid, transparent background
- Center pivot with stable ground anchor
- Max 18 colors, dark-background readability priority
```

```text
NEGATIVE PROMPT:
Tarot card border, ornate card template, scenic market background, realistic rendering,
combat stance, sword/gun action, attack animation, hit animation, death animation, gore
```

```text
CONSISTENCY LOCK:
- same traveler silhouette family (cloak + oversized backpack + cargo modules)
- same palette family (slate blue + cyan/magenta rift accents)
- same accessory layout and proportion in all directions
- same non-combat interaction tone across frames
```

---

### 【NPC03】先知 (Seer) - 构筑偏向

#### 📐 立绘提示词（非卡牌）

```text
PROMPT: Full-body character portrait of "Seer" NPC from Tarot Dreamscape supply hub
STYLE: Pixel art, dreamcore glitch aesthetics, enigmatic analytic oracle design
ROLE: Build-bias advisor guiding output/survival/economy paths

DESCRIPTION:
- Standalone portrait, transparent background, no card frame
- Tall, elegant silhouette with layered veil and ring-like prediction apparatus
- Floating probability shards orbit around forearms (triangle, arc, node symbols)
- One hand draws branching light-lines in air, suggesting path selection
- Eyes covered by translucent band, expression serene and unreadable
- Robe geometry is clean and vertical, with occasional mirrored glitch slices
- Add subtle holographic runes representing decision branches
- Keep pose still and composed, "consultation" not "casting attack"

COLOR PALETTE:
- Main robe: deep indigo and violet (#241a44, #4a2f78)
- Oracle glow: cyan + soft white (#00ffff, #e0e6ed)
- Bias highlights: green/red/purple pulses (#00ff41, #ff0040, #b967ff)
- Metallic rings: cold silver-blue (#8ba4c4)
- Shadow core: near-black navy (#0a1628)

TECHNICAL SPECS:
- Portrait ratio: 3:4, target 768×1024px
- Medium-detail pixel clusters, clean symbolic readability
- Transparent background PNG
- Maintain calm, centered composition

MOOD: Detached, prophetic, precise, emotionally quiet
```

中文说明：
- “路径建议者”语义通过分叉光线与概率碎片体现，不做攻击性法术。
- 先知的主识别是“环形装置 + 眼部遮罩 + 垂直轮廓”。

#### 🎮 静态交互精灵图提示词（无攻击动作）

```text
PROMPT: Top-down NPC interaction sprite sheet for "Seer" in Tarot Dreamscape supply hub
VIEW: Direct top-down, non-combat NPC sheet
USAGE: Build bias consultation interaction only

DESCRIPTION:
- Circular oracle ring visible from top-down as primary identity marker
- Body footprint compact, with floating shard accents around upper body
- Gesture focuses on indicating options/branches, not combat casting
- Motion should feel levitating and controlled

ANIMATION SET (NON-COMBAT):
1. Idle (4 frames): slow float bob + ring shimmer
2. Turn (4 directions, 2 frames each): smooth orientation change with ring alignment
3. Talk/Gesture (4 frames): branch-line gesture and subtle hand motion
4. Trade/Offer (4 frames): presents three glowing bias nodes

TECHNICAL SPECS:
- Base size: 52×52px per frame
- Sprite sheet grid, transparent background
- Center pivot, low drift between frames
- Max 18 colors, ring silhouette must remain readable
```

```text
NEGATIVE PROMPT:
Tarot card template, decorative border frame, full background scenery, photoreal face,
battle spell attack, projectile casting, hit reaction, death pose, gore, text overlay
```

```text
CONSISTENCY LOCK:
- same seer silhouette family (veil + oracle ring + floating shards)
- same palette family (indigo/violet with cyan oracle glow)
- same floating posture and non-combat gesture grammar
- same symbol language for branch/bias cues
```

---

### 【NPC04】经纪人 (Broker) - 风险契约

#### 📐 立绘提示词（非卡牌）

```text
PROMPT: Full-body character portrait of "Broker" NPC from Tarot Dreamscape supply hub
STYLE: Pixel art, dreamcore glitch aesthetics, contract-dealer with cold strategic presence
ROLE: Risk contract negotiator, trade-off specialist

DESCRIPTION:
- Standalone full-body portrait, transparent background, no card frame
- Sharp tailored silhouette: long coat, angular shoulders, clean geometric cut
- Holds a luminous contract slate in one hand, chip-token stack in the other
- Around waist: suspended seal-tags and thin data chains indicating binding terms
- Face expression controlled and unreadable, slight confident smirk
- Coat edges show occasional data-fragment glitches, restrained not chaotic
- Shoes and gloves polished, emphasizing professional precision
- Add subtle hovering clause symbols near contract hand (small, legible, minimal)

COLOR PALETTE:
- Main outfit: charcoal and dark steel (#1f2633, #2d3b4f)
- Contract glow: red + cyan contrast (#ff0040, #00ffff)
- Neutral highlights: cool gray (#8b9bb4, #c0c8d0)
- Premium accent: muted gold (#b08a4a)
- Background-independent shadow tone: #0a1628

TECHNICAL SPECS:
- Portrait ratio: 3:4, target 768×1024px
- Medium-detail pixel art, strong clean silhouette
- Transparent background PNG
- Keep visual language corporate-occult, not gangster or military

MOOD: Calculating, composed, high-stakes negotiator energy
```

中文说明：
- 经纪人必须体现“风险换收益”的交易压力感，主道具为契约板与筹码。
- 轮廓偏硬朗几何，与先知的神秘漂浮形成互补对照。

#### 🎮 静态交互精灵图提示词（无攻击动作）

```text
PROMPT: Top-down NPC interaction sprite sheet for "Broker" in Tarot Dreamscape supply hub
VIEW: Direct top-down, non-combat NPC sheet
USAGE: Contract negotiation interaction only

DESCRIPTION:
- Angular top-down silhouette with long-coat hem and contract slate
- Token chips or seal tags visible near one hand
- Gesture language: presenting terms, waiting for confirmation
- Motion restrained and deliberate, minimal emotional exaggeration

ANIMATION SET (NON-COMBAT):
1. Idle (4 frames): subtle coat flutter + contract glow pulse
2. Turn (4 directions, 2 frames each): controlled pivots, slate remains visible
3. Talk/Gesture (4 frames): one-hand negotiation gestures
4. Trade/Offer (4 frames): extends contract slate and token stack

TECHNICAL SPECS:
- Base size: 54×54px per frame
- Sprite sheet grid, transparent background
- Center pivot, stable feet/ground anchor
- Max 18 colors, high readability on dark background
```

```text
NEGATIVE PROMPT:
Tarot card border/frame, casino hall scene, realistic photography, weapon attack pose,
combat animation, hit flash, death sequence, blood effects, watermark text
```

```text
CONSISTENCY LOCK:
- same broker silhouette family (angular coat + contract slate + token cues)
- same palette family (charcoal with red/cyan contract accents)
- same restrained non-combat body language
- same accessory scale and placement in all frames
```

---

## ✅ 交付自检清单

- 已覆盖 4 位补给站 NPC：Witch / Rift Traveler / Seer / Broker
- 每位均包含两组可直接投喂代码块：立绘 + 静态交互精灵
- 全文立绘均为非卡牌形式（无边框、无卡牌模板）
- 精灵动作集仅含 Idle / Turn / Talk-Gesture / Trade-Offer（无攻击动作）
- 含每位 NPC 的 Negative Prompt 与 Consistency Lock，便于批量生产与质量回归
