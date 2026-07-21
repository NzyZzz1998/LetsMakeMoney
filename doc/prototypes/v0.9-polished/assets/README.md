# v0.9 polished prototype pet assets

This folder contains prototype-only runtime preview assets copied from PetManager.

## Sources

- Classic Pro:
  - `<PetManager>/examples/letsmakemoney-classic-pro-complete/package`
- Duoduo:
  - `<PetManager>/.worktrees/duoduo-base-image/examples/duoduo-cat-pro-complete/package`

## Included files

- `pet.json`: package identity and display metadata.
- `actions.json`: action rows, frame counts, and per-frame durations.
- `extra-actions.webp`: 1536x832 atlas, 192x208 cell size, 4 actions x 8 frames.

## Prototype mapping

- `working` -> `making-money`
- `awake_rest` -> `eating`
- `sleeping` -> `sleeping`
- state-aware single click -> current `celebrating` is a timing proxy only; final assets differ by base state
- long-press drag -> `run_prepare`, directional running, and `run_settle`; current `making-money` preview is a timing proxy only
- lunch/work-end event -> one-shot `celebrating`, then resolve the latest base state
- double click has no independent product action in the revised v0.9 contract

These files are embedded only so the prototype can show real PetManager frame playback. They do not mean the Godot runtime has already switched to these packages.
