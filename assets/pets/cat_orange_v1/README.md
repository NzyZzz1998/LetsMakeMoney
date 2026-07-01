# cat_orange_v1 final 256 pack

Generated on: 2026-06-29
Source character: <TEMP_PROJECT>\content.png
Purpose: final 256x256 transparent PNG set for the first Godot integration pass.

## Included animations

| Animation | Frames | Suggested playback | Notes |
| --- | ---: | --- | --- |
| idle | 4 | 2 FPS loop | Optimized cute front-facing idle. |
| working | 4 | 5 FPS loop / about 0.8s cycle | Keyboard working loop with coin pop reward. |
| resting | 2 | about 0.67 FPS loop / about 3s cycle | Sleeping / breathing loop. |
| idle_clicked_single | 3 | 0.6s one-shot | Subtle click reaction: squash, happy eyes, return. No raised paw. |
| idle_clicked_double | 3 | 0.8s one-shot | Small celebration bounce with sparkles. Frame 2 uses the more expressive raised-paw version; frame 3 returns cleanly to sitting pose. |
| working_clicked_single | 3 | 0.6s one-shot | Click reaction while continuing to work at keyboard. |
| working_clicked_double | 3 | 0.8s one-shot | Stronger earnings burst with larger coin/plus feedback. |
| resting_clicked_single | 3 | 0.6s one-shot | Drowsy stir while remaining in resting pose. |
| resting_clicked_double | 3 | 0.8s one-shot | Larger sleepy reaction with sparkles, still lying down. |
| clicked_hold | 2 | shared hold fallback / about 1 FPS | Common long-press confused/frozen state used by all base states. |

## Folder layout

```text
cat_orange_v1/
  idle/
  working/
  resting/
  idle_clicked_single/
  idle_clicked_double/
  working_clicked_single/
  working_clicked_double/
  resting_clicked_single/
  resting_clicked_double/
  clicked_hold/
  _previews/
  README.md
```

## Godot import notes

Copy this folder to `res://assets/pets/cat_orange_v1/`, then create a SpriteFrames resource using the folder names as animation names.

For state-aware interaction mapping, prefer:

- idle + single click -> `idle_clicked_single`
- idle + double click -> `idle_clicked_double`
- working + single click -> `working_clicked_single`
- working + double click -> `working_clicked_double`
- resting + single click -> `resting_clicked_single`
- resting + double click -> `resting_clicked_double`
- any state + hold -> common `clicked_hold`
