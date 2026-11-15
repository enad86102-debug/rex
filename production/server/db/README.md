# REX candidate PostgreSQL match transactions

**D2 architecture candidate — NOT connected to the live Go server and NOT approved as the production database.**

This schema provides a **real PostgreSQL transaction boundary** for a future authoritative match coordinator: encrypted private checkpoint (opaque ciphertext + nonce + external key reference), immutable four-seat roster, optimistic version, durable action receipts, public event ledger, outbox, and at-most-once settlement.

The PL/pgSQL `record_match_transition` locks the match row, verifies seat membership, returns matching prior receipts on a retry, rejects same-ID/different-input and stale versions, and writes state+receipt+events+outbox+optional settlement as one transaction. PostgreSQL rolls back the entire mutation on any statement failure.

**Critical integration limits:** This function does not validate card rules, token authentication, or table roster against the legacy JSON waiting-room adapter; the application must do those before calling it. An approved production deployment must migrate room/session identity into a consistent transactional boundary, use AEAD encryption in the Go server with a secret outside the DB, restrict DB roles/row access, define backups, backups/restore drills, eviction/retention, multiserver locking and outbox delivery. The current SHA-256 candidate checkpoint by itself is not tamper authentication.

**Testing:** `psql -v ON_ERROR_STOP=1 -f production/server/db/migrations/0001_candidate_match.sql -f production/server/db/tests/match_atomicity.sql` against a *disposable* CI postgres database. The workflow `database-contract` provides a Postgres 16 service and verifies retry, rejection, rollback and outbox effects. These SQL tests are not end-to-end Go integration.

**Status:** Engineer-reviewed **proposal with executable SQL tests**, pending Abdulaziz D2 database/transport and founder rules approvals. Do not store real user secrets/cards here and do not expose this schema in a public deployment.
