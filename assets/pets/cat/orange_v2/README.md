# cat orange v2 runtime asset

License: visual PNG assets are covered by the repository root
`ASSETS_LICENSE.md`; metadata, resources, and generation scripts are covered
by the root MIT `LICENSE`. See `ASSETS_MANIFEST.md` for provenance.

This directory is the v0.4 runtime area for the next orange cat animation set.
It currently contains an image-generation concept candidate derived from a
six-pose orange-cat concept sheet. The earlier deterministic cutout batch is
kept only as an engineering pipeline fallback and is not considered final art.

Required animation folders:

- `idle/`
- `working/`
- `resting/`
- `clicked_hold/`
- `idle_clicked_single/`
- `idle_clicked_double/`
- `working_clicked_single/`
- `working_clicked_double/`
- `resting_clicked_single/`
- `resting_clicked_double/`

Creative direction confirmed for v0.4:

- v2 may lightly refine the current orange cat while keeping it recognizable.
- `working` should include work or money props such as keyboard, computer, and coins.
- `resting` should explore several variants before selection.
- Single-click and double-click are base-state extension animations, not generic standalone actions.

Current generated candidate:

- Generator: `scripts/generate_cat_orange_v2_from_concept_sheet.py`
- Batch id: `20260704-imagegen-concept-derived`
- Manifest: `asset-manifest.json`
- SpriteFrames: `cat_orange_v2_sprite_frames.tres`
- PetResource: `cat_orange_v2_resource.tres`
- Preview sheet: `_review/imagegen_candidate_contact_sheet.png`

Regenerate the current image-generation concept candidate:

```powershell
python .\scripts\generate_cat_orange_v2_from_concept_sheet.py
```

Import the new PNGs and rebuild Godot resources:

```powershell
$ProjectRoot = (Resolve-Path .).Path
$env:APPDATA = Join-Path $ProjectRoot ".godot_user"
$env:LOCALAPPDATA = $env:APPDATA
& $env:LMM_GODOT_EXE --headless --path $ProjectRoot --script "res://scripts/build_cat_orange_v2_resource.gd"
```

The generated `.tres` files should reference external PNG textures. They should
not become large embedded `ImageTexture` resources.

The v0.4 default pet now points to this resource after manual review accepted
the current candidate as good enough to continue. `cat_orange_v1` remains in
the repository as the fallback resource.
