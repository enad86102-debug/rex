# Security, privacy, trust, and asset rights

Source: the master onboarding baseline supplied by Ammar on 2026-10-04.
These principles apply when relevant features are implemented; no security
provider or production infrastructure is selected in onboarding.

## Secrets and operational security

Never commit API keys, passwords, private keys, production tokens, signing
secrets, credentials, or real-user secrets. Use environment configuration and
secret management. Do not commit sensitive local-machine configuration.

Use least privilege, input validation, authentication, authorization, appropriate
rate limits, auditability, separate environments, dependency review, secure
logging, backup/restore planning, and incident readiness. Android platform
integrity/attestation is possible later scoped work, not today's setup.

## Gameplay, purchases, and economy

The server controls sensitive gameplay, outcomes, balances, inventory,
purchases, and rewards. Clients never set their own balances. Protect retries
with logical idempotency and duplicate handling; economic changes and admin
grants need auditable entries.

Private hands or restricted state must not leak through API responses,
WebSocket or other transport payloads, logs, analytics, crash reports, or
spectator feeds. Filter every view by recipient permissions, including bots.

Use secure randomness and unbiased shuffling; preserve audit/replay evidence
and rule versions. Do not casually invent cryptography. Claims of complete
security, impossible cheating, or provable fairness need a precise threat model
and evidence; hashing a deal alone does not prove fair randomness.

## Privacy and identity

Minimize collected data. Do not collect precise location, contacts, microphone
data, phone numbers, or personal information unless a necessary feature and
its requirement have explicit approval.

Guest play is desirable to reduce onboarding friction. Later account systems
need recovery, linking, deletion, ownership, purchase restoration, and privacy
handling. Do not introduce unnecessary identity friction in the first game loop.
Specific auth, retention, and privacy mechanisms remain undecided.

## Community and child safety

Before activating chat, voice, UGC, clubs, public profiles, or creator uploads,
scope reporting, blocking, moderation, abuse prevention, age-related safety,
and evidence/audit handling. Do not activate large social surfaces without the
required safety systems. Avoid dating-oriented mechanics.

## Intellectual property

Use original, team/company-owned, or properly licensed assets with understood
commercial rights. Record provenance and license information. Royalty-free
does not imply unrestricted ownership.

Do not use unauthorized celebrity/football-player likenesses, anime/cartoon
characters, brands, music, or artwork. Original music/ambience is a possible
future direction. No assets are acquired or licensed in this phase.

## Administrative authority and risk handling

Admin access must be constrained, authorized, and auditable. Economic grants
cannot be hidden edits. Review features with ambiguous payment/randomness/
loss/prize/transferability before implementation.

Stop and explain serious security, data-loss, IP, payment, or architecture
risks. Do not invent legal conclusions, entity arrangements, or country-specific
business obligations. Record concrete decisions and approvals when obtained.
