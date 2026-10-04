# Product principles

Source: the master onboarding baseline supplied by Ammar on 2026-10-04.
Future systems below are conditional principles, not activation requests.

## Quality priorities

Correctness before scale; reliability before feature count; gameplay clarity
before visual excess; player trust before monetization tricks; maintainability
before architectural fashion. Measure before rewriting. Do not fabricate
metrics or describe the product as production-ready without evidence.

A beautiful lobby with an incomplete match is not a successful vertical slice.

## Table experience and performance

The known visual direction uses a central table, four small player characters,
visible chairs, clear names, and card-play animations. Entrance/win effects and
customizable environments are later enhancements. Decoration must never obscure
the player's hand, current turn, legal actions, score, timer, or game state.

Adaptive visual quality may later reduce effects and animation on low-end
Android hardware while preserving identical rules and fairness. Consider app
size, caching, resource bundles, downloadable/on-demand assets where appropriate,
and real-device measurements. Emulator results alone do not prove performance.

Arabic is first-class: support RTL, mixed Arabic/English names, localization,
regional differences, and future languages. Do not scatter hard-coded
user-facing strings throughout code.

## Social experience and safety

Future friends, private tables, invitations, clubs, Diwaniyas, Rex Majlis, quick
messages, animated emotes, spectators, tournaments, and community features
must be scoped progressively. Social interaction must not evolve into
dating-oriented or uncontrolled anonymous interaction.

Reporting, blocking, moderation, abuse handling, and age-related safety must
accompany activated social surfaces. Voice is historically deferred and needs
an explicit implementation request.

## Ethical boundaries

Do not propose or silently implement gambling, real-money/casino wagering,
player-to-player monetary wagering, cash-out, pay-to-win card advantages,
paid better distribution, paid protection from legitimate losses, paid random
loot boxes, or dating-oriented mechanics. REX is not intended to be marketed
as a religious application; these are product values.

If a feature combines payment, randomness, loss, prizes, and transferability
in an ambiguous way, flag it for review before implementation.

## Future economy

| Concept | Recorded direction |
| --- | --- |
| XP | Progression only; primarily earned by play; not spendable. |
| Coins | Basic currency from selected play/rewards/challenges/events; ordinary and potentially expensive prestige items; avoid unlimited inflation. |
| Gems | Premium currency; may be purchased and possibly earned through limited special sources; rewarded ads must not be an ordinary Gems source. |

Items may be acquired with Coins, Gems, direct purchase, tournaments,
achievements, challenges, or events. Some rare items must remain impossible to
buy. Preserve acquisition-source prestige. No cash-out; no player currency
transfer unless a later explicit decision changes this after legal/security
analysis. Do not activate the full economy in the first coding task.

Future balances and purchases are server-authoritative and auditable; see
[architecture](ARCHITECTURE_PRINCIPLES.md) and [security](SECURITY_BASELINE.md).

## Ads, ranks, and prestige

No interruptive ads during active gameplay. Future ads should primarily be
optional/rewarded and outside the match, potentially granting Coins, selected
temporary cosmetics, or small rewards. Ads must not block normal gameplay.
Do not add an ad SDK without an explicit task.

Levels, ranks, VIP/status, titles, frames, entrances, and victory effects are
future systems. Payment status must not be confused with skill; payment must
not improve cards or artificially improve ranked outcomes. Ranked play and the
cosmetic store are historically deferred.

## Bots and fairness

Bots may serve training, tests, or table liquidity. Clearly identify them as
bots. They may use only information available to their seat, even when running
on the server. Difficulty comes from decision quality, not hidden-card access.

Consider secure randomness, unbiased shuffle, match audits/replays, rule
versions, disputes, collusion, and fraud. Do not casually invent cryptography
or claim impossible cheating, provable fairness, or complete security without
a defined threat model and evidence. A hash alone does not prove fair dealing.

## Future evidence and metrics

Possible measurements: time to first playable match, first-match completion,
table/matchmaking completion time, reconnect success, rematches, invitation
conversion, group return, D1/D7/D30 retention, crash-free sessions, latency,
fairness/support complaints, economy issuance/spend, and later purchase
conversion. Providers, event schemas, and thresholds remain undecided.
