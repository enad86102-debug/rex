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

## Mission 004.1 verification record

- CI run `38081962840` could not be queried from this Windows workspace because GitHub CLI (`gh`) is not installed or available on PATH. No CI result is claimed; the remote run must be checked in GitHub or with an authenticated CLI on an operator machine.
- The implementation now exposes the selected environment name with a `STAGING` label. Because independent production environment layers are unavailable, the scene uses an explicit neutral staging fallback instead of silently rendering the selected flattened concept.
- Code constants `_seatAnchors` use normalized table-space coordinates: North (0.50, 0.16), East (0.84, 0.50), South (0.50, 0.84), West (0.16, 0.50), represented in Flutter alignment space as (0,-0.68), (0.68,0), (0,0.68), (-0.68,0). The four labels use those constants.
- A real-device screenshot was not captured: `adb devices` returned no connected devices and `adb exec-out screencap -p` produced a zero-byte file. This is **DEVICE SCREENSHOT BLOCKED**, not visual evidence.
- Reference comparison remains qualitative and blocked for direct measurement until a device screenshot is supplied. Known differences: neutral background instead of the reference environment, proxy chairs, missing adult characters, simplified UI chrome, and staging labels.

## Mission 005 implementation record

The table composition is now separated into `lib/features_table_scene.dart`:

- `TableScene` owns composition order.
- `EnvironmentLayer` owns environment IDs and Arabic staging labels.
- `SeatLayer` iterates one shared `rexSeatDefinitions` list.
- `SeatSlot` owns the shared anchor for chair and character slots.
- `CharacterSlot` and `ChairSlot` are stable production asset interfaces.
- `TableSurface` owns felt/frame and the independent card-layer boundary.
- `InteractiveCardLayer` and `TableOverlay` reserve explicit front layers without adding gameplay.

`RexTablePage` now passes a meaningful `RexEnvironment` identifier rather than a raw background filename. Missing environments use the neutral staging fallback and preserve the selected ID through navigation. No reference screenshot is loaded as runtime artwork.

Targeted tests cover environment fallback and North/East/South/West anchor definitions in addition to the existing card and navigation tests. The scene is technically ready to receive production art, but artistic approval remains blocked by the missing independent characters, perspective-correct chairs, and environment layers.
