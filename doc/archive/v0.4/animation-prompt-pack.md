# LetsMakeMoney v0.4 橘猫动画提示词执行集

**版本**: v0.4 Beta
**状态**: 素材生成前执行集
**目标目录**: `assets/pets/cat/orange_v2/`

本文档用于指导橘猫 v2 动画素材生成和筛选。它不代表素材已经接入；所有输出都必须先记录到 `doc/v0.4-animation-assets-log.md`，再通过自动验证和人工预览后才能替换默认素材。

---

## 1. 已确认方向

- 角色身份：允许轻微优化当前橘猫外观，但必须保持 LetsMakeMoney 的橘猫识别度。
- 默认体验：warm companion，柔和、轻量、低压力，适合长期常驻桌面。
- working：必须加入 work props，例如 keyboard、computer、coins，让用户一眼看出正在工作或赚钱。
- resting：同时探索 sleepy sitting、lying down 和其他 low-motion resting pose，再选最舒服的一版。
- click 规则：single-click 和 double-click 是 base-state extension，不是 generic standalone action。
- hold 规则：`clicked_hold` 是通用持续反馈，拖拽开始后不应继续保持长按语义。
- 视觉反馈：cutout 贴片式道具方案已被人工拒绝。后续生成应让 laptop、keyboard、coins、sleeping pose 和 hold pose 成为角色构图的一部分，而不是在既有小猫图上后贴符号。

---

## 2. 全局生成约束

所有动画都遵守：

- Transparent background.
- Same canvas size across the whole set.
- Stable visual center and foot baseline.
- No cropped ears, paws, tail, or outline.
- No random transparency noise.
- Flat cute orange cat, rounded shapes, soft warm color palette.
- Keep the cat readable at 50%, 75%, 100%, 125%, 150%, and 200% app scale.
- Props should be integrated into the pose and composition. Avoid sticker-like overlays, pasted symbols, floating UI marks, or objects that visually sit on top of the cat without perspective or contact.
- Generate clean pose concepts first when using AI image tools, then derive frames from approved poses. Do not generate final runtime frames from an unapproved visual direction.

建议输出命名：

```text
cat_orange_v2_<animation>_<frame>.png
```

---

## 3. 动画目录

```text
assets/pets/cat/orange_v2/idle/
assets/pets/cat/orange_v2/working/
assets/pets/cat/orange_v2/resting/
assets/pets/cat/orange_v2/clicked_hold/
assets/pets/cat/orange_v2/idle_clicked_single/
assets/pets/cat/orange_v2/idle_clicked_double/
assets/pets/cat/orange_v2/working_clicked_single/
assets/pets/cat/orange_v2/working_clicked_double/
assets/pets/cat/orange_v2/resting_clicked_single/
assets/pets/cat/orange_v2/resting_clicked_double/
```

---

## 4. Base Animations

### idle

Purpose:
- Default calm companion state.
- Long-term desktop presence should not feel noisy.

Prompt core:

```text
Create a frame sequence for a cute flat orange cat desktop pet in idle state, warm companion feeling, subtle breathing and blinking, transparent background, stable center, stable foot baseline, same canvas size, no crop, no jitter.
```

Acceptance:
- Calm breathing or blinking.
- No large body movement.
- Minimum 4 frames.
- Loop.

### working

Purpose:
- Must clearly communicate earning money or working.
- Include keyboard, computer, coins.

Prompt core:

```text
Create a frame sequence for a cute flat orange cat desktop pet working at a tiny computer, paws typing on a keyboard, small coins or salary sparkles nearby, warm companion feeling, transparent background, stable center, stable foot baseline, same canvas size, no crop, no jitter.
```

Acceptance:
- Keyboard or computer visible.
- Coins or money cue visible but not noisy.
- Minimum 6 frames.
- Loop.
- Distinct from idle.

### resting

Generate at least three variants before selecting:

1. sleepy sitting
2. lying down
3. another low-motion resting pose

Prompt core for sleepy sitting:

```text
Create a frame sequence for a cute flat orange cat desktop pet in a sleepy sitting resting pose, eyes relaxed, soft breathing, warm companion feeling, transparent background, stable center, stable foot baseline, same canvas size, no crop, no jitter.
```

Prompt core for lying down:

```text
Create a frame sequence for a cute flat orange cat desktop pet lying down and resting, relaxed body, small sleepy expression, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter.
```

Acceptance:
- Visibly different from idle.
- Low motion.
- Minimum 4 frames.
- Loop.

---

## 5. Base-State Extension Click Animations

These are base-state extension animations. They should reflect the active base state.

### idle_clicked_single

```text
Create a short single-click reaction for the idle cute flat orange cat, tiny happy bounce or blink, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This is an idle base-state extension, not a generic action.
```

### idle_clicked_double

```text
Create a stronger double-click reaction for the idle cute flat orange cat, playful but short, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This is an idle base-state extension.
```

### working_clicked_single

```text
Create a short single-click reaction for the working cute flat orange cat at a computer, paws pause briefly on keyboard, small coin sparkle, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This is a working base-state extension.
```

### working_clicked_double

```text
Create a stronger double-click reaction for the working cute flat orange cat at a computer, quick excited typing and coin sparkle, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This is a working base-state extension.
```

### resting_clicked_single

```text
Create a short single-click reaction for the resting cute flat orange cat, sleepy eye open or tiny ear twitch, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This is a resting base-state extension.
```

### resting_clicked_double

```text
Create a stronger double-click reaction for the resting cute flat orange cat, briefly surprised but still cozy, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This is a resting base-state extension.
```

Acceptance:
- Single-click minimum 3 frames.
- Double-click minimum 4 frames.
- One-shot, not loop.
- Returns visually to the same base state.
- Does not look like a separate permanent state.

---

## 6. Hold Animation

### clicked_hold

```text
Create a loopable hold reaction for a cute flat orange cat desktop pet, gently squished or patiently held, warm companion feeling, transparent background, stable center, same canvas size, no crop, no jitter. This hold animation is shared across base states and should loop while the mouse is held.
```

Acceptance:
- Minimum 4 frames.
- Loop.
- Calm, not distressed.
- Should not conflict with drag behavior.

---

## 7. Batch Recording Template

每次生成后，在 `doc/v0.4-animation-assets-log.md` 新增：

```markdown
## Batch YYYYMMDD-NN

- Tool:
- Input image:
- Prompt source: `doc/v0.4-animation-prompt-pack.md`
- Output path:
- Candidate animations:
- Accepted:
- Rejected:
- Reason:
- Integration notes:
- Manual confirmation needed:
```

同时更新：

```text
assets/pets/cat/orange_v2/asset-manifest.json
```
