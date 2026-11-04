# REX match checkpoint encryption primitive

This package provides candidate AES-256-GCM sealing/unsealing for private Trix checkpoint bytes with a secure random 96-bit nonce and authenticated association to `match_id` and `rules_version`. There are unit tests for tampering, wrong key, cross-match copy and nonces.

The encrypted values map conceptually to `production/db/candidate/001_create_schema.sql` columns. **No Go database adapter currently uses this package.** The key must originate outside the database and Git; key provisioning/rotation/recovery and final storage choice require Abdulaziz's D2 review.

The existing SHA-256 in private checkpoint is only an error-detection checksum, not malicious-write protection. This package adds an AEAD primitive but does not make any current file store production-ready. No endpoint exports the plaintext by design.
