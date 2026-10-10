# REX asset starter kit — 2026-10-10

## What IS delivered
- 19 **real GLB geometry files**: six royal table color versions, six royal upholstered chair color versions, a four-seat layout scene, four seated human figure guides, and two basic physical cards.
- 5 exact user-supplied transparent PNG assets: REX crest, two viewpoints of a chair, table felt, table frame.
- 53 independently generated 2D playing-card PNGs: 52 card faces and one back.
- Three original source concept references (reference only); a preview contact sheet.
- Full JSON manifest and the editable Python geometry-generation script.

## What is NOT delivered / MUST NOT be claimed
- NOT production-quality photorealistic characters. The four `PLAYER-GUIDE` meshes are simple geometry for seat blocking only. They are **not rigged, skinned, animated or fit as final human characters**.
- The procedural GLB tables and chairs are **real 3D geometry**, but do not match the ornate sculpting, PBR textures, lighting and realism of the supplied concept art exactly. They are staging models for engineering, camera and scale checks.
- No full photorealistic environment meshes, palaces, rigged outfits or animations. Images of places and interfaces supplied by the team remain flattened references, not independent environment textures.
- No ready-to-run Flutter 3D renderer. Flutter cannot display GLB by itself without a selected rendering pipeline; that choice must be reviewed by Abdulaziz.
- No independently extracted character PNGs from flattened screenshot collages. This would be misleading.
- No 100% visual fidelity claim. No copyright or commercial-rights verification independent of the team's source ownership.

## Folder guide
- `3d/glb/`: actual GLB meshes. Coordinates: **Z-up** authored locally, meters-ish; after import check engine axis conversion. Card designs are separately provided as 2D, not automatically texture mapped to GLB.
- `2d/extracted_verified/`: original assets with real alpha from user-uploaded files; pixels unaltered.
- `2d/playing_cards/`: generated single-card PNGs.
- `references/`: exact concept renders, **not production layers**.
- `source/build_rex_assets.py`: procedural Python generator; requires trimesh, Pillow and numpy.
- `ASSET_MANIFEST.json`: individual file status.

## Recommended implementation
1. For an immediately faithful *2D/2.5D* Android visual preview, use supplied alpha table + chair sprites, preserve dynamic Flutter cards, and acquire 4 independent character images. Do not put interactive buttons over flattened reference screenshots.
2. For production *true 3D*, commission/model real detailed chairs, tables, 4 rigged characters, calibrated cameras, light rigs and optimized material textures. These GLBs can be proportion/placement prototypes only.
3. Select Flutter rendering integration after hardware benchmark. Do not silently switch architecture.
4. Optimize PNGs, texture atlases and GLB meshes before mobile shipment.
5. Do not treat shop prices/coins/voice or any other visible mockup text as approved application requirements.
