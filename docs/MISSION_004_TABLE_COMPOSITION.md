# REX Mission 004 — Table Composition Contract

**Starting point:** `61ceeb5`  
**Status:** engineering staging only; visual approval is not granted.

## Candidate scene

The production candidate no longer uses a flattened table screenshot as its scene background. Full-screen concept references contain their own table, chairs, and people, so placing independent layers above them duplicates geometry and invalidates occlusion. The table route now uses an empty dark environment scaffold and independent staging layers. References remain under `assets/staging/rex_starter_kit/REX_Asset_Starter_Kit_2026_10_10/references/` for comparison.

## Rendering order

Back to front: environment; chairs; characters; table body/frame; felt; rim/highlights; real Flutter playing cards; UI chrome; effects. The environment is currently a scaffold because independent Royal Hall/Wadi Rum/Petra/Aqaba layers are missing. Cards remain independent widgets/assets and are never baked into reference artwork.

## Four-seat anchor contract

Coordinates are normalized to the table bounds (origin top-left):

| Seat | Anchor | Perspective | State |
|---|---|---|---|
| North | (0.50, 0.16) | camera-facing | front chair proxy; character missing |
| East | (0.84, 0.50) | right three-quarter inward | angled proxy; dedicated final chair missing |
| South/local | (0.50, 0.84) | camera-facing; hand occludes lower body | front chair proxy; character missing |
| West | (0.16, 0.50) | left three-quarter inward | dedicated left-facing chair missing; no mirroring claimed |

All four positions are labeled `ART MISSING` in the staging preview.

## Missing production assets

| ID | Required asset | Requirements | Priority |
|---|---|---|---|
| CHAR-N/E/S/W | Four adult seated characters | independent transparent production art or approved rigged source; seat-specific pose/perspective; Android 2x/3x exports | P0 |
| CHAIR-N/S | North/south chairs | camera-facing production chair with occlusion masks | P0 |
| CHAIR-E | East chair | right-facing three-quarter production chair | P0 |
| CHAIR-W | West chair | left-facing three-quarter production chair; no mirrored substitute | P0 |
| ENV-RH | Royal Hall | independent portrait background with no baked table/chairs/players | P0 |
| ENV-WR/PE/AQ | Wadi Rum/Petra/Aqaba | same independent-layer contract | P1 |
| UI-LAYERS | plaques, nameplates, controls | separate RTL-ready layers; text not baked into art | P1 |
| FX-TABLE | ambient, selection and throw effects | separate and Android-performance validated | P1 |

Procedural tables/chairs and guide-only player GLBs remain staging references. They are not finished characters and are not proven rigged/skinned. No Flutter 3D renderer is introduced; that requires Abdulaziz technical review.

## Comparison and approval gate

Baseline: `REF_06_GAME_TABLE_FOUR_PLAYERS.png`. Compare anchor placement, table scale, perspective, card readability, lighting and occlusion against a real Android screenshot. The current implementation intentionally differs because P0 environment, chair and character layers are missing. Visual approval is blocked until those assets are delivered and reviewed.
