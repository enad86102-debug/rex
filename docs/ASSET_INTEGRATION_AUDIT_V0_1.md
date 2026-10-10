# REX Starter Kit Asset Integration Audit v0.1

**Status: STAGING / NEEDS ART REVIEW — not visual approval**  
**Source:** `REX_Asset_Starter_Kit_v0_1.zip` supplied by Ammar on 2026-10-10.  
**Integration boundary:** assets and one layered 2D table prototype only. No gameplay, providers, backend, payments, or 3D renderer were added.

## Imported and validated

The kit is preserved under `assets/staging/rex_starter_kit/REX_Asset_Starter_Kit_2026_10_10/` and the verified PNG subset is copied into the Flutter asset bundle at `app/rex_mobile/assets/staging/rex_starter_kit/` without changing `assets/approved_ui/`.

| Asset group | Evidence | Classification |
|---|---|---|
| REX transparent logo | `REX_Logo_Original_Transparent.png`, 1254x1254, alpha present | READY for staging |
| Emerald felt | `Table_Emerald_Felt_Original.png`, 1448x1086, alpha present | READY for 2D prototype |
| Royal frame | `Table_Royal_Gold_Frame_Original.png`, 1448x1086, alpha present | READY for 2D prototype |
| Chair front / angled | 1086x1448 each, alpha present | STAGING; needs art review for perspective and production polish |
| Playing cards | 52 faces plus `rex_card_back.png`, 180x260 | STAGING; functional card system source |
| GLB tables/chairs | six table variants and six chair variants | STAGING; procedural assets, not final PBR |
| GLB guide players/scene | four guide-only players and four-seat scene | MISSING production characters; not rigged/skinned/animated |
| Reference images | atlas, game table, royal lobby | REFERENCE_ONLY; not composable production layers |

## Layered prototype

`app/rex_mobile/lib/main.dart` now composes the verified felt, gold frame, and chair PNGs as independent layers over the existing reference environment on the table route. The prototype keeps existing card selection, throw animation, and navigation intact. The backdrop is explicitly still reference art because the kit does not contain independent production environment layers.

This is an engineering preview, not a final visual recreation. The concept screenshots remain the art-direction baseline and are not treated as ready-to-ship UI.

## Gap table

| Area | State | Required before visual approval |
|---|---|---|
| Brand shield/logo | READY | final approved export and typography separation |
| Royal Hall / Wadi Rum / Petra / Aqaba environments | MISSING | independent optimized background layers |
| Table felt and gold frame | READY | art review, device-performance validation |
| Chairs | STAGING | correct four orientations and final production assets |
| Four adult seated characters | MISSING | independent transparent character art, rigging/animation plan |
| Card fronts/back | STAGING | final card design and readability review |
| UI chrome (plaques, controls, nameplates) | MISSING | separate RTL-ready components/assets |
| Ambient/win/throw/selection effects | MISSING | controlled, performant production effects |
| Full PBR 3D scene | NEEDS_ART_REVIEW | Abdulaziz technical review before renderer decision |

## Side-by-side comparison

The source references are retained at `assets/staging/.../references/` for human comparison. The current Flutter table route is a layered preview only; no image-perfect match is claimed. Human review must compare a device screenshot against `REF_06_GAME_TABLE_FOUR_PLAYERS.png` and record deviations in a subsequent approved visual task.

## Constraints carried forward

- Do not overwrite approved UI assets.
- Do not claim guide-only GLBs are game-ready characters.
- Do not select a Flutter 3D pipeline without Abdulaziz technical review.
- Do not resume full visual reconstruction until missing P0 character, environment, and UI layers are supplied and reviewed.
