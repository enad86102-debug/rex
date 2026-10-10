# REX — Codex asset intake (do not replace the existing app)

Repository: `enad86102-debug/rex`

Read `AGENTS.md`, `docs/VISUAL_ASSET_REQUIREMENTS_V1.md`, and the pack `ASSET_MANIFEST.json`.

1. Import this kit into a **new staging** folder such as `assets/staging/rex_starter_kit/` without overwriting `assets/approved_ui/`.
2. Keep the user's existing concept art and art direction authoritative. Do not treat these new procedural models as visually approved production 3D.
3. Validate each PNG transparency and each GLB's loadability; do not claim rigged/skinned characters when the assets are only seating guides.
4. For the existing Flutter Android app, first implement a **layered 2D table prototype** using actual verified transparent PNGs; remaining chair angles and independent human sprites are missing.
5. If a full 3D scene is proposed, compare renderer options and device performance, seek Abdulaziz's technical review, and do not silently switch the app technology.
6. Keep gameplay logic, payments, gems, VIP, voice, multiplayer and user accounts unchanged by this asset intake.
7. Produce a side-by-side comparison with the original concept screenshots and a gap table containing READY / STAGING / MISSING / NEEDS_ART_REVIEW.
8. Do not publish or mark as final until the detailed production assets pass visual review.

Do not claim image-perfect fidelity based on this pack. Record missing professional character modeling/rigging and full PBR art as explicit blockers.
