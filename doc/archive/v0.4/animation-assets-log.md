# LetsMakeMoney v0.4 Animation Assets Log

**Version**: v0.4 Beta
**Status**: Baseline log

This file records generated, imported, screened, and integrated animation candidates for v0.4. It is intentionally separate from the implementation plan so asset experiments can be reviewed without rewriting project planning documents.

---

## Baseline: cat_orange_v1

- Source path: `assets/pets/cat_orange_v1/`
- Current role: v0.3 default orange cat resource and v0.4 fallback baseline.
- Resource file: `assets/pets/cat_orange_v1/cat_orange_v1_resource.tres`
- SpriteFrames file: `assets/pets/cat_orange_v1/cat_orange_v1_sprite_frames.tres`
- Status: Keep as fallback. Do not delete during v0.4 animation work.

### Existing frame groups

| Group | Path | Current use |
|-------|------|-------------|
| idle | `assets/pets/cat_orange_v1/frames/idle/` | Base state candidate |
| working | `assets/pets/cat_orange_v1/frames/working/` | Base state candidate |
| resting | `assets/pets/cat_orange_v1/frames/resting/` | Base state candidate |
| clicked_hold | `assets/pets/cat_orange_v1/frames/clicked_hold/` | Hold overlay candidate |
| idle_clicked_single | `assets/pets/cat_orange_v1/frames/idle_clicked_single/` | Base-specific click overlay |
| idle_clicked_double | `assets/pets/cat_orange_v1/frames/idle_clicked_double/` | Base-specific double-click overlay |
| working_clicked_single | `assets/pets/cat_orange_v1/frames/working_clicked_single/` | Base-specific click overlay |
| working_clicked_double | `assets/pets/cat_orange_v1/frames/working_clicked_double/` | Base-specific double-click overlay |
| resting_clicked_single | `assets/pets/cat_orange_v1/frames/resting_clicked_single/` | Base-specific click overlay |
| resting_clicked_double | `assets/pets/cat_orange_v1/frames/resting_clicked_double/` | Base-specific double-click overlay |

### Baseline conclusion

cat_orange_v1 is usable as a fallback, but v0.4 still needs v2 screening because:

- v0.4 confirms that click feedback should be base-specific: `idle_clicked_*`, `working_clicked_*`, and `resting_clicked_*`.
- Existing click feedback already follows the base-specific direction, so v2 should keep this model and improve quality rather than flattening clicks into generic standalone animations.
- Visual rhythm and state distinction still need manual quality review.

Confirmed creative decisions:

- Orange cat v2 may lightly refine the current cat identity.
- Working should include work or money props such as keyboard, computer, and coins.
- Resting should explore multiple variants first: sleepy sitting, lying down, and other low-motion resting poses.
- Single-click and double-click are extensions of the current base state, not generic standalone actions.

---

## Runtime target directory: cat/orange_v2

- Target path: `assets/pets/cat/orange_v2/`
- Status: v0.4 runtime default resource after manual review accepted the current imagegen concept-derived batch as good enough to continue.
- Required folders prepared: `idle`, `working`, `resting`, `clicked_hold`, `idle_clicked_single`, `idle_clicked_double`, `working_clicked_single`, `working_clicked_double`, `resting_clicked_single`, `resting_clicked_double`.
- Prompt pack: `doc/v0.4-animation-prompt-pack.md`
- Asset manifest: `assets/pets/cat/orange_v2/asset-manifest.json`
- Current decision: Use `cat_orange_v2` as the v0.4 default while keeping `cat_orange_v1` as fallback. The current v2 art is accepted as a beta-quality runtime candidate, not as the final long-term animation quality target.

---

## Asset Production Routes

This section records current production-route research so v0.4 animation work does not depend on one free quota or one external service.

### Route A: SpriteCook

- Role: short-term candidate generation.
- Local support: `spritecook-generate-sprites`, `spritecook-animate-assets`, and `spritecook-use-assets-in-godot` skills are available locally.
- Current blocker: callable SpriteCook MCP tools are not available in the current Codex tool list, so this route requires external SpriteCook setup or manual use.
- Strength: fastest route for trying orange v2 stills and animation candidates when credits are available.
- Constraint: credit/quota based. Do not treat free credits as the only long-term production capacity.
- v0.4 use: suitable for first candidate batches once a SpriteCook account/MCP flow is ready.

### Route B: ComfyUI local workflow

- Role: long-term self-hosted production Spike.
- Candidate components: IP-Adapter for reference identity, ControlNet for pose/shape control, AnimateDiff or equivalent workflow for short motion exploration.
- Strength: can become a reusable local pipeline with no per-batch service quota.
- Constraint: setup, GPU, model selection, transparency cleanup, and workflow maintenance cost are higher.
- v0.4 use: non-blocking Spike. Before default v2 replacement, record whether ComfyUI can keep the orange cat identity while producing usable idle / working / resting candidates.

### Route C: Local sprite editing tools

- Role: cleanup, frame normalization, and low-frame manual fixes.
- Candidate tools: Pixelorama, LibreSprite, Aseprite, or equivalent editors.
- Strength: useful regardless of generation source; can clean alpha edges, align canvas, fix drift, and patch small frame issues.
- Constraint: manual effort. It improves generated output but does not create the whole animation set by itself.
- v0.4 use: recommended cleanup step before importing any AI-generated frames into Godot.

### Route D: Godot cutout animation

- Role: deterministic fallback when frame-by-frame AI output is inconsistent or too expensive.
- Candidate parts: head, body, tail, paws, eyes, keyboard, computer, coins.
- Strength: stable, controllable, lightweight, and easy to keep aligned with click-through/window constraints.
- Constraint: less expressive than full frame-by-frame animation unless more parts are prepared.
- v0.4 use: acceptable fallback for breathing, blinking, typing, coin bounce, and small reaction loops if orange v2 frame sequences fail quality gates.

### Current Route Decision

- Primary route: SpriteCook for fast first candidates if usable credits/MCP are available.
- Backup route: ComfyUI local workflow Spike for longer-term capacity.
- Cleanup route: Pixelorama / LibreSprite / Aseprite class tools for transparency and alignment cleanup.
- Deterministic fallback: Godot cutout animation using stable parts.
- Manual approval required: yes. The 20260704 imagegen concept-derived batch has received enough manual approval to become the v0.4 beta default. Future batches still need the same gate before replacing it.

---

## ComfyUI Preflight

- Script: `scripts/check_comfyui_prereqs.ps1`
- Spike document: `doc/v0.4-comfyui-spike.md`
- Suggested external install path: `<LOCAL_SOFTWARE>\ComfyUI`
- Repository rule: keep model checkpoints, virtual environments, ComfyUI custom nodes, caches, and raw bulk output outside this repository.
- Current machine check:
  - GPU: NVIDIA GeForce RTX 5070 Ti
  - VRAM: about 16GB reported by `nvidia-smi`
  - Python: 3.12.8 available
  - Git: available
  - Reference image: `assets/pets/cat_orange_v1/frames/idle/idle_01.png`
- ComfyUI source install:
  - Zip source: `%USERPROFILE%\Downloads\ComfyUI-master.zip`
  - Install path: `<LOCAL_SOFTWARE>\ComfyUI`
  - Virtual environment: `<LOCAL_SOFTWARE>\ComfyUI\.venv`
  - Dependency status: installed and `pip check` reports no broken requirements
  - PyTorch status: `torch 2.11.0+cu128`, CUDA 12.8, GPU detected as `NVIDIA GeForce RTX 5070 Ti`
  - Startup status: ComfyUI starts locally at `http://127.0.0.1:8188` with `cuda:0`
  - Model status: not installed
- Conclusion: ComfyUI is worth testing on this machine, and the source tree plus CUDA-enabled runtime are installed outside the repository. V04-M1.5.5 remains open until a real idle / working / resting candidate batch is generated and reviewed.

---

## Batch 20260704-cutout-v1-derived

- Tool: Pillow deterministic cutout fallback
- Input image: `assets/pets/cat_orange_v1/frames`
- Prompt source: `doc/v0.4-animation-prompt-pack.md`
- Generator: `scripts/generate_cat_orange_v2_cutout_candidates.py`
- Output path: `assets/pets/cat/orange_v2/`
- Candidate animations:
  - `idle`: 4 frames
  - `working`: 6 frames, with laptop / keyboard / coin overlays
  - `resting`: 4 frames, with sleepy rest cue overlays
  - `clicked_hold`: 4 frames
  - `idle_clicked_single`: 3 frames
  - `idle_clicked_double`: 4 frames
  - `working_clicked_single`: 3 frames
  - `working_clicked_double`: 4 frames
  - `resting_clicked_single`: 3 frames
  - `resting_clicked_double`: 4 frames
- Preview: `assets/pets/cat/orange_v2/_review/cutout_contact_sheet.png`
- Accepted: Accepted only as an engineering candidate for v2 pipeline validation.
- Rejected: Rejected as a visual/default-art candidate after manual review.
- Reason: This batch proves the v2 directory, naming, frame-count, import, SpriteFrames, and PetResource pipeline. Visual quality is too crude because the laptop, coins, rest marks, and click marks are deterministic overlays on top of v1 frames.
- Cleanup needed: Do not polish this batch as final art. Replace with SpriteCook / ComfyUI / hand-edited candidates, or use a cleaner Godot cutout approach where props are designed as proper parts rather than stickers.
- Integration notes:
  - `cat_orange_v2_sprite_frames.tres` and `cat_orange_v2_resource.tres` were generated.
  - Godot import must run before building the resource if external texture references are desired.
  - `cat_orange_v1` remained the runtime default after this rejected visual batch.
- Manual confirmation needed: yes.

---

## Batch 20260704-imagegen-concept-derived

- Tool: image generation concept sheet + crop normalization
- Input image: `assets/pets/cat/orange_v2/_review/imagegen_concept_sheet_20260704.png`
- Click action image: `assets/pets/cat/orange_v2/_review/imagegen_click_actions_20260704.png`
- Idle click sequence image: `assets/pets/cat/orange_v2/_review/imagegen_idle_click_sequence_20260704.png`
- Generator: `scripts/generate_cat_orange_v2_from_concept_sheet.py`
- Output path: `assets/pets/cat/orange_v2/`
- Candidate animations:
  - `idle`: 4 frames
  - `working`: 6 frames, using an integrated laptop / coin pose
  - `resting`: 4 frames, using a curled sleeping pose
  - `clicked_hold`: 4 frames, using a gentle cheek-hold pose
  - `idle_clicked_single`: 3 frames
  - `idle_clicked_double`: 4 frames
  - `working_clicked_single`: 3 frames, derived from the working pose
  - `working_clicked_double`: 4 frames, derived from the working pose
  - `resting_clicked_single`: 3 frames, derived from the resting pose
  - `resting_clicked_double`: 4 frames, derived from the resting pose
- Preview: `assets/pets/cat/orange_v2/_review/imagegen_candidate_contact_sheet.png`
- Accepted: Accepted as the v0.4 beta runtime default after manual iteration on idle, single-click, and double-click frames.
- Rejected: Not rejected as a runtime default; still not considered final long-term animation quality.
- Reason: This batch avoids sticker-like props by generating laptop, coins, sleeping, and hold as integrated poses. It is still mostly static pose animation, so frame-to-frame motion richness remains limited, but the current result is good enough for v0.4 beta integration.
- Cleanup applied:
  - Replaced the original `idle_clicked_double` crop because the source pose showed raised paws plus seated paws at the same time, creating a six-paw visual error. The current double-click frames derive from the cleaner single-click pose and add spark feedback.
  - Adjusted the lower-row crop boxes for `clicked_hold` and `idle_clicked_single` so ear tips are no longer cut off. `idle_clicked_double` inherits the same fix because it now derives from the single-click pose.
  - Changed white-background removal to flood-fill only the edge-connected white background, preserving the cat's white muzzle and chest instead of making those areas transparent.
  - Replaced scale-only click feedback after manual feedback that single-click should have real action changes. Click extensions now use a dedicated action concept sheet: idle single waves, working single taps the laptop, resting single wakes slightly, idle double hops, working double celebrates, and resting double stretches awake.
  - Increased click animation frame counts with real transition stages instead of duplicated keyframes. Single-click now has 5 frames: neutral, anticipation squash, action start, action peak, recovery. Double-click now has 7 frames: neutral, anticipation squash, takeoff, first peak, landing squash, second peak, recovery.
  - Narrowed the idle click sequence after manual feedback: `idle_clicked_single` and `idle_clicked_double` now use only selected safe frames from the idle sequence sheet, excluding generated frames with extra-paw artifacts.
  - Restored non-idle click actions after manual comparison: `working_clicked_*` and `resting_clicked_*` use the shorter action-pose feedback from the click-action concept sheet rather than the reduced base-state-only feedback.
  - Extended runtime readability after manual feedback that single-click and double-click were still too hard to see: all single-click extensions now play at 3fps; `idle_clicked_double` plays at 3.5fps; `working_clicked_double` and `resting_clicked_double` play at 3.25fps. Runtime click feedback is held for 1.55s so the pose change is not immediately overwritten by the base state.
  - Reweighted click frame durations after a deeper review: many click sequences intentionally begin and end on neutral/base-like frames, so a non-looping animation could spend too much visible time looking unchanged. The current v2 builder writes 0.35 duration for the first/last click frames and 2.2 duration for action frames, making the actual action pose dominate the playback.
- Cleanup still needed: Further style consistency, transparent-edge quality, 256px readability, and richer transition motion can be improved in later v0.4 passes or v0.5+. Current known limitation: several click reactions are still pose-based rather than fully animated.
- Integration notes:
  - Existing `cat_orange_v2_sprite_frames.tres` and `cat_orange_v2_resource.tres` were rebuilt from this batch.
  - `cat_orange_v2` is now the v0.4 default resource.
  - `cat_orange_v1` remains available as fallback and should not be deleted.
  - Godot headless runs should use a project-local `.godot_user` directory for `APPDATA` / `LOCALAPPDATA` on this machine, otherwise Godot may crash while trying to write editor settings or logs under the normal user directory.
- Manual confirmation needed: no for beta default integration; yes for future replacement batches.

---

## Batch Template

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
