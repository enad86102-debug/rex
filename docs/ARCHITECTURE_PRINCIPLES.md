# Architecture principles

Source: the master onboarding baseline supplied by Ammar on 2026-10-04.

## Registered direction

- Client: Flutter / Dart.
- Backend: Go.
- Backend structure: modular monolith initially.
- Delivery: Android first; preserve sensible future iOS compatibility.

Unity/C#, ASP.NET Core, Godot, microservices, Kubernetes, and other stacks are
research alternatives, not adopted replacements. Changes follow
[governance](GOVERNANCE.md) and the [decision register](DECISIONS.md).

Prefer simple, modular, testable, observable, secure, documented systems.
Avoid premature distributed systems, Kubernetes, multiple databases, and large
infrastructure before need is established. This definition task selects no
database, cloud, library, transport, framework extension, or provider.

## Conceptual boundaries

Potential internal modules: Identity, Player Profile, Sessions, Games, Tables,
Matches, Invitations, Presence, Social, Inventory, Economy, Purchases,
LiveOps, Content, Reports, Moderation, Support, Analytics, and Admin.

These are conceptual boundaries, not services or existing code. Create only
what later missions require. Future compatibility must be proportional to
real need; do not engineer for speculative five-year features.

## Authoritative gameplay and visibility

The client requests actions and renders accepted state. The server validates
distribution, legal moves, turns, scores, match outcomes, rewards, Coins/Gems,
inventory, purchases, and tournament results.

Never send all players' private cards to every client and hide them in the UI.
Filter state per player. Spectators need a separate filtered view; server bots
receive only legitimate seat knowledge. Responses, transport payloads, logs,
analytics, and crash reports must preserve these boundaries.

## Reliability on mobile networks

Future match processing needs match IDs, action IDs, state/version numbers,
authoritative event processing, logical idempotency, reconnect/recovery,
timeout policy, duplicate protection, and replay/audit capability.

Retries must not play another card, grant another reward, settle the same match
twice, or execute a purchase twice. Do not claim exactly-once networking;
design safe retries and logical idempotency. Concrete persistence, ordering,
transport, and recovery mechanisms await scoped design and review.

## Versioned Game Rules Contracts

Rules must be independently testable and not embedded in UI logic. Each game
eventually needs an approved versioned contract specifying players, seats,
teams, deck, distribution, starting player, bidding/contracts where applicable,
valid actions, follow-suit rules, scoring, round/match completion, ties,
timeouts, disconnects, surrender, bot replacement, and rule version.

Do not copy competitor rules as the REX specification. First-game selection
and exact rules require approval before production implementation.

## Future economy integrity

Use an auditable transaction/ledger approach for future server-owned balances.
Sensitive entries should capture transaction ID, account/player, currency or
asset, source, reason, delta, before/after or derivable balance, server time,
reference, idempotency key, policy/version, and admin actor where relevant.

Administrative grants must not be invisible database edits. The mobile client
never sets its own balance. Gameplay must not depend on activating the full
economy immediately.

## Admin and content

Future administration may manage LiveOps, events, seasons, content, prices,
rewards, configuration, reports, sanctions, support, grants, feature flags,
experiments, and analytics. Constrain permissions and record audit trails;
do not design unrestricted super-admin control.

Future characters, tables, environments, items, prices, events, durations,
rewards, availability, rarity, and sources should use reasonable data/config
boundaries rather than all being hard-coded in client releases. Do not build
a giant content platform before the first game works.
