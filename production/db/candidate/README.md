# REX — Candidate transactional match store (PostgreSQL evaluation)

**Status:** isolated engineering candidate. No production storage architecture has been approved or wired into `rexd`. The current Go snapshot service and the candidate Trix checkpoint are **not migrated** by these SQL files.

This schema tests a concrete transaction boundary between encrypted checkpoint bytes, match roster, durable action receipts, versioned public match events, and delivery outbox. The Go adapter must eventually use one SQL transaction to lock the match state row, validate the expected version and authenticated actor, update the encrypted checkpoint, append a unique receipt and event/outbox rows, and commit **before** acknowledging a turn. Candidate tests use a single PostgreSQL instance, not a claim of production HA, backup, GDPR compliance or scalability.

The `checkpoint_ciphertext` column **requires the application** to perform authenticated encryption (AES-GCM or equivalent approved AEAD) and to manage keys externally. SQL shape checks cannot prove that data is encrypted. SHA-256 without a secret key does not protect against malicious rewriting. Application/API tests must also defend against nested JSON sensitive data leakage, race conditions and mismatched room membership. Only seat-filtered public event data may be placed in `event_public` or `response_public`.

In a disposable test database:

```bash
psql -X -v ON_ERROR_STOP=1 -d rex_ci -f production/db/candidate/001_create_schema.sql
psql -X -v ON_ERROR_STOP=1 -d rex_ci -f production/db/candidate/test_atomic_schema.sql
```

The separate `002_drop_schema.sql` is destructive and never runs automatically in CI. No secrets or production passwords appear here. The matching GitHub Actions job uses an ephemeral PostgreSQL container for verification.

**Architecture review (D2):** Abdulaziz should review PostgreSQL versus SQLite, transactions, state storage, encryption/key rotation, room+match lifecycle, event/outbox semantics, backup/restore and operator costs before production adoption. Tarneeb is included only as a future schema `game_id`, not a working game implementation.
