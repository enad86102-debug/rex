# REX — candidate Trix screen contract

This change adds a **real server-view model** for the existing Go `PlayerMatchView` and `PlayerLegalMoves` JSON, a read-only authenticated GET adapter, and a reusable Arabic RTL Flutter match panel. It does **not** turn on gameplay in `RexHome`. The Go API match endpoints are not implemented on this branch; displaying a pretend match to the owner would be deceptive.

The widget accepts a server-derived snapshot and callbacks that must later be wired to a reviewed secure durable-action controller. A legal card is **advisory** from `LegalMoves`; Go `Apply` must validate the actual movement and state version again.

The parser rejects stale `LegalMoves`, wrong turn options, duplicate hand cards, illegal card hints, invalid suits/ranks, and obvious hidden checkpoint material. Transport refuses malformed table IDs or bearer-shaped credentials; it never submits actor ID. This client-side filtering is **not a substitute** for authenticated per-seat server projections or independent API privacy tests.

Next implementation step: candidate API under `rex_candidate` build tag with real HTTP integration; secure action IDs persisted through Android Keystore before any mutating network call, then wiring the panel only when the candidate server returns real data. No public production game activation or launch claim.
