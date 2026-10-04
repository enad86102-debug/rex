# REX V1 — Visual Asset Requirements

This document freezes visual implementation. It specifies the separable production assets required before visual coding resumes. It does not authorize asset generation, UI changes, feature work, or application-code changes.

## Asset specification

| ID | Screen | Asset name | Purpose | Dimensions / ratio | Transparent | Motion | Layer | Separate text | Interaction dependency | Reuse | Priority |
|---|---|---|---|---|---|---|---|---|---|---|---|
| BRAND-001 | All | REX shield/logo | Primary identity mark | 1024×1024, 1:1 | Yes | Static | Foreground | Yes | None | All screens | P0 |
| BRAND-002 | Splash, Home | Crown emblem | Crown detail for identity and plaques | 512×256, 2:1 | Yes | Static | Foreground | Yes | None | Splash, home, victory | P1 |
| BRAND-003 | All | Decorative crest ornaments | Framing and identity decoration | Vector or 1024×256, 4:1 | Yes | Static | Foreground | Yes | None | Shared chrome | P2 |
| ENV-001 | Splash, Home, Table | Royal Hall environment | Cinematic palace background | 1080×1500, portrait 18:25 | No | Static | Background | Yes | Environment selection | Splash, home, table | P0 |
| ENV-002 | World, Table | Wadi Rum environment | Desert lounge destination and table setting | 1080×1500, portrait 18:25 | No | Static | Background | Yes | Environment selection | World, picker, table | P0 |
| ENV-003 | World, Table | Petra environment | Petra lounge destination and table setting | 1080×1500, portrait 18:25 | No | Static | Background | Yes | Environment selection | World, picker, table | P0 |
| ENV-004 | World, Table | Aqaba environment | Coastal lounge destination and table setting | 1080×1500, portrait 18:25 | No | Static | Background | Yes | Environment selection | World, picker, table | P0 |
| TABLE-001 | Table, Session | Table body | Physical table silhouette and structural geometry | 1080×1050, transparent PNG, 36:35 | Yes | Static | Midground | Yes | Selected environment | Table, session | P0 |
| TABLE-002 | Table | Table felt | Replaceable felt surface | 900×700, transparent PNG, 9:7 | Yes | Static | Midground | Yes | Environment/table theme | Table variants | P0 |
| TABLE-003 | Table | Gold frame | Rim, corner metalwork, and depth edge | 1080×1050, transparent PNG, 36:35 | Yes | Static | Foreground | Yes | Table theme | All table themes | P0 |
| TABLE-004 | Table, Session | Chairs | Four perspective-matched physical chairs | 4× assets, each 360×520, transparent | Yes | Static | Midground | Yes | Seat position | Table, session | P0 |
| PLAYER-001 | Table, Session | North seated character | Adult character seated behind table | 520×720, transparent PNG, 13:18 | Yes | Static with replaceable rig | Midground | Yes | Seat state/nameplate | Table, session | P0 |
| PLAYER-002 | Table, Session | East seated character | Adult character seated at right seat | 520×720, transparent PNG, 13:18 | Yes | Static with replaceable rig | Midground | Yes | Seat state/nameplate | Table, session | P0 |
| PLAYER-003 | Table, Session | West seated character | Adult character seated at left seat | 520×720, transparent PNG, 13:18 | Yes | Static with replaceable rig | Midground | Yes | Seat state/nameplate | Table, session | P0 |
| PLAYER-004 | Table, Session | Local/bottom seated character | Adult local player seen from table perspective | 600×760, transparent PNG, 15:19 | Yes | Static with replaceable rig | Foreground | Yes | Local hand/nameplate | Table, session | P0 |
| CARD-001 | Table | Card front system | Reusable ranks, suits, typography, and face layout | 180×260 per card, 9:13 | Yes | Static | Foreground | Yes | Selection, legal state | Table, victory | P0 |
| CARD-002 | Table | Card back | REX-backed card surface | 180×260, 9:13 | Yes | Static | Foreground | Yes | Deck interaction | Table, session | P0 |
| CARD-003 | Table | Deck | Stacked card source with depth | 220×290, transparent | Yes | Static | Midground | Yes | Deal/throw actions | Table | P0 |
| CARD-004 | Table | Selected-card state | Lifted card border, shadow, and highlight | Card-size overlay | Yes | Animated | Foreground | Yes | Card selection | Table | P0 |
| CHROME-001 | All | Title plaque | Gold-edged dark title panel | 900×170, transparent, 90:17 | Yes | Static | Foreground | Yes | Screen title | All screens | P1 |
| CHROME-002 | Home, Session, Victory | Primary CTA | Gold dimensional button surface | 900×150, transparent, 6:1 | Yes | Static/pressed | Foreground | Yes | Tap target | Shared | P0 |
| CHROME-003 | All | Secondary button | Dark/navy button with gold edge | 720×130, transparent, 36:6.5 | Yes | Static/pressed | Foreground | Yes | Tap target | Shared | P1 |
| CHROME-004 | All | Circular control | Notification, settings, back, social control frame | 128×128, transparent, 1:1 | Yes | Static/pressed | Foreground | Yes | Tap target | Shared | P1 |
| CHROME-005 | Table, Session | Player nameplate | Seat-linked name and status plaque | 360×110, transparent, 36:11 | Yes | Static/stateful | Foreground | Yes | Player/seat state | Table, session | P0 |
| CHROME-006 | Home | Currency panel | Coins and gems panel surfaces | 420×120 each, transparent | Yes | Static/stateful | Foreground | Yes | Balance display | Home | P1 |
| CHROME-007 | Home | Bottom navigation | Four-item premium navigation chrome | 1080×180, transparent, 6:1 | Yes | Static/selected | Foreground | Yes | Navigation state | Home and shells | P1 |
| CHROME-008 | World, Environment | Environment card frame | Reusable image frame with selected state | 520×360, transparent, 13:9 | Yes | Static/selected | Foreground | Yes | Environment selection | World, picker | P0 |
| CHROME-009 | Home, Game selection | Game card frame | Trix/Tarneeb card presentation | 520×620, transparent, 26:31 | Yes | Static/selected | Foreground | Yes | Game selection | Home, game selection | P1 |
| FX-001 | Splash, Home, Table | Gold ambient particles | Restrained atmospheric dust/light | 1080×1500, transparent | Yes | Animated loop | Foreground | Yes | None | All cinematic screens | P1 |
| FX-002 | Victory | Win particles | Confetti and gold celebration burst | 1080×1500, transparent | Yes | Animated one-shot | Foreground | Yes | Victory state | Victory | P1 |
| FX-003 | Table | Card throw trail | Controlled motion trail for thrown card | 600×300, transparent | Yes | Animated one-shot | Foreground | Yes | Card throw | Table | P1 |
| FX-004 | Table | Selected glow | Localized halo under selected card/control | 220×290, transparent | Yes | Animated loop/state | Foreground | Yes | Selection state | Table | P1 |

## Layering requirements

Each table environment must be composited in this order:

1. Environment background.
2. Architectural and lighting midground.
3. Chairs and adult seated characters.
4. Table body, felt, and frame.
5. Deck, played cards, and local hand.
6. Nameplates and interactive chrome.
7. Effects and temporary feedback.

Text must remain outside artwork wherever it can change, localize, or respond to state. No complete concept screenshot is a production UI layer.

## P0 assets required before visual coding resumes

1. `BRAND-001` — REX shield/logo.
2. `ENV-001` — Royal Hall environment.
3. `ENV-002` — Wadi Rum environment.
4. `ENV-003` — Petra environment.
5. `ENV-004` — Aqaba environment.
6. `TABLE-001` — table body.
7. `TABLE-002` — table felt.
8. `TABLE-003` — table gold frame.
9. `TABLE-004` — four chairs.
10. `PLAYER-001` — north seated character.
11. `PLAYER-002` — east seated character.
12. `PLAYER-003` — west seated character.
13. `PLAYER-004` — local/bottom seated character.
14. `CARD-001` — card front system.
15. `CARD-002` — card back.
16. `CARD-003` — deck.
17. `CARD-004` — selected-card state.
18. `CHROME-002` — primary CTA.
19. `CHROME-005` — player nameplate.
20. `CHROME-008` — environment card frame.

No Flutter UI, application code, dependencies, or existing visual implementation was changed by this specification.
