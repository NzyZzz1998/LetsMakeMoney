# LetsMakeMoney v0.4 Animation Spec

**Version**: v0.4 Beta
**Status**: Confirmed baseline for V04-M1
**Platform**: Windows x86_64

---

## 1. Goal

v0.4 animation work upgrades the cat from "visible asset" to "state readable companion". The animation system must stay compatible with the v0.3 desktop pet runtime: transparent window, click-through regions, Panel hover, right-click menu, tray recovery, and Debug fallback.

The default v0.4 direction is warm companion: soft, low-pressure, readable, and suitable for staying on the desktop for a long time. This is not a theme system. Multi-theme, theme switching, custom theme settings, and theme store remain future work.

---

## 2. State Model

### 2.1 Base States

| State | Meaning | Loop | Minimum Frames | Recommended FPS | Notes |
|------|---------|------|----------------|-----------------|------|
| `idle` | No salary configured, before work, or neutral waiting state | Yes | 4 | 6-10 | Calm breathing/blinking is preferred over large motion. |
| `working` | Salary is configured and current time is within working hours | Yes | 6 | 8-12 | Must clearly read as working or making money. |
| `resting` | Salary is configured and current time is outside working hours | Yes | 4 | 6-10 | Must be visually distinct from `idle`. |

### 2.2 Interaction Extension States

Single-click and double-click are not standalone base states. They are extensions of the active base state and should change with `idle`, `working`, and `resting`.

| State family | Trigger | Loop | Minimum Frames | Recommended FPS | Recovery |
|--------------|---------|------|----------------|-----------------|----------|
| `<base>_clicked_single` | Short left click while a base state is active | No | 3 | 3-4 | Return to the same base state that was active before the click. The feedback must remain visually readable after the double-click arbitration delay and should not flash too quickly to notice. |
| `<base>_clicked_double` | Double left click while a base state is active | No | 4 | 3-4 | Return to the same base state that was active before the double click. The feedback should be more obvious than single-click and long enough for the full pose change to read. |
| `clicked_hold` | Left button held without dragging | Yes | 4 | 8-12 | Continue while held, then return to the base state that was active before hold. |

### 2.3 Required Animation Names

The required v0.4 animation names are:

```text
idle
working
resting
clicked_hold
idle_clicked_single
idle_clicked_double
working_clicked_single
working_clicked_double
resting_clicked_single
resting_clicked_double
```

The runtime may keep generic `clicked_single` / `clicked_double` fallback support for old or experimental resources, but v0.4 default acceptance does not require generic click animations. Base-specific click extensions are preferred because the click response should reflect whether the cat is idle, working, or resting.

### 2.4 Confirmed v2 Creative Direction

- Cat identity: orange cat v2 may lightly refine the current v1 look, but should remain recognizably the same app character.
- Working state: include work props such as a keyboard, computer, coins, or salary-related elements. The action should read as working or earning money at a glance.
- Resting state: explore multiple variants first, including sleepy sitting, lying down, and other low-motion resting poses. Final selection should be based on readability and long-term comfort.

---

## 3. Canvas and Alignment

| Requirement | Standard |
|-------------|----------|
| Canvas size | Same width and height across every frame in one animation set. |
| Transparent boundary | Transparent edge must be clean and not include random artifacts. |
| Anchor | Visual center and foot baseline must remain stable across frames. |
| Scale | Pet should remain fully visible at 50%, 75%, 100%, 125%, 150%, and 200% app scale. |
| Drift | Character center and foot baseline should not visibly jump between adjacent frames. |
| Crop | Ears, paws, tail, and outline must not be cut by canvas bounds. |

Recommended review overlay:

```text
canvas bounds
visual center
foot baseline
safe transparent padding
```

---

## 4. Naming Rules

v0.4 candidate assets should use:

```text
cat_orange_v2_<animation>_<frame>.png
```

Examples:

```text
cat_orange_v2_idle_00.png
cat_orange_v2_working_03.png
cat_orange_v2_idle_clicked_single_01.png
cat_orange_v2_working_clicked_double_02.png
cat_orange_v2_clicked_hold_02.png
```

Target directory:

```text
assets/pets/cat/orange_v2/
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

## 5. Acceptance Gates

An animation set can replace the default cat only if all gates pass:

- The ten required animations exist: `idle`, `working`, `resting`, `clicked_hold`, `idle_clicked_single`, `idle_clicked_double`, `working_clicked_single`, `working_clicked_double`, `resting_clicked_single`, `resting_clicked_double`.
- Every required animation has at least one valid frame and meets the minimum frame target or has an explicit exception recorded in the asset log.
- Base states loop; base-specific single-click and double-click extensions do not loop; `clicked_hold` loops.
- No obvious crop, jitter, random transparency noise, or frame-to-frame scale jump.
- `working` is visually distinguishable from `idle`.
- `resting` is visually distinguishable from `idle`.
- Single and double click feedback are short, base-specific, and do not look like permanent base states.
- The animation style matches the warm companion direction.
- The v0.3 cat asset remains available as fallback.

---

## 6. Asset Log Format

Every generated or imported batch should be recorded in `doc/v0.4-animation-assets-log.md`.

```markdown
## Batch YYYYMMDD-NN

- Tool:
- Input image:
- Prompt:
- Output path:
- Candidate animations:
- Accepted:
- Rejected:
- Reason:
- Integration notes:
- Manual confirmation needed:
```

---

## 7. Asset Production Routes

v0.4 should not depend on a single free quota or a single external generation service. Candidate assets can come from multiple routes, but every route must still satisfy the same naming, canvas, alignment, and acceptance gates above.

| Route | Role | v0.4 Usage | Main Risk |
|-------|------|------------|-----------|
| SpriteCook | Short-term candidate generation | Use existing SpriteCook skills/MCP when available to quickly generate orange v2 stills and animation candidates. | Requires SpriteCook MCP and credits; free quota should not be treated as permanent production capacity. |
| ComfyUI local workflow | Long-term self-hosted production spike | Evaluate IP-Adapter / ControlNet / AnimateDiff style workflows for reference-preserving cat stills, pose control, and keyframe or short-loop generation. | Setup, GPU, model, and workflow maintenance cost are higher than SpriteCook. |
| Local sprite editors | Cleanup and frame normalization | Use Pixelorama, LibreSprite, Aseprite, or equivalent tools to clean transparency, normalize canvas, fix drift, and patch low-frame animations. | Manual time cost; does not solve generation by itself. |
| Godot cutout animation | Deterministic fallback | Split the cat into stable parts such as head, body, tail, paws, eyes, keyboard, computer, and coins, then animate with Godot AnimationPlayer or equivalent runtime resources. | Less rich than full frame-by-frame animation, but much more controllable. |

Production decision rule:

- SpriteCook is acceptable for fast v2 candidate exploration.
- ComfyUI is tracked as a non-blocking v0.4 Spike for longer-term self-hosted capacity.
- Local editors are expected for cleanup even when AI generation is used.
- Godot cutout is the fallback when generated frame sequences are inconsistent, jittery, or too expensive to iterate.
- The final default asset can use any route, but it must pass the same v0.4 quality gates and manual approval.

---

## 8. Verification

Automatic verification should check structural correctness:

- SpriteFrames resource can be loaded.
- Required base animations and base-specific click extension animation names exist.
- Required animations have frames.
- FPS and loop policy are readable and match the spec.
- PetManager still exposes base state and interaction overlay APIs.
- v0.3 orange cat fallback resource remains present.

Manual verification should check visual quality:

- Cropping.
- Drift.
- Flicker.
- State readability.
- Warm companion feel.
- Interaction recovery after click, double click, hold, and drag.
