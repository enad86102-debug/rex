-- REX candidate-only PostgreSQL evaluation: NOT an approved production datastore.
-- Apply with ON_ERROR_STOP=1 to an isolated test database.
BEGIN;
CREATE SCHEMA IF NOT EXISTS rex_candidate;
REVOKE ALL ON SCHEMA rex_candidate FROM PUBLIC;

CREATE TABLE rex_candidate.match_state (
    match_id text PRIMARY KEY CHECK (length(match_id) BETWEEN 1 AND 128),
    room_id text NOT NULL UNIQUE,
    game_id text NOT NULL CHECK (game_id IN ('trix_complex', 'tarneeb')),
    rules_version text NOT NULL CHECK (length(rules_version) BETWEEN 1 AND 180),
    state_version bigint NOT NULL CHECK (state_version >= 1),
    roster_revision bigint NOT NULL CHECK (roster_revision >= 1),
    checkpoint_ciphertext bytea NOT NULL CHECK (octet_length(checkpoint_ciphertext) > 16),
    checkpoint_nonce bytea NOT NULL CHECK (octet_length(checkpoint_nonce) = 12),
    checkpoint_key_id text NOT NULL CHECK (length(checkpoint_key_id) BETWEEN 1 AND 100),
    phase text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE rex_candidate.match_seat (
    match_id text NOT NULL REFERENCES rex_candidate.match_state(match_id) ON DELETE RESTRICT,
    seat smallint NOT NULL CHECK (seat BETWEEN 0 AND 3),
    player_id text NOT NULL,
    PRIMARY KEY (match_id, seat),
    UNIQUE (match_id, player_id)
);

CREATE TABLE rex_candidate.action_receipt (
    match_id text NOT NULL REFERENCES rex_candidate.match_state(match_id) ON DELETE RESTRICT,
    actor_player_id text NOT NULL,
    action_id text NOT NULL CHECK (length(action_id) BETWEEN 16 AND 128),
    request_sha256 bytea NOT NULL CHECK (octet_length(request_sha256) = 32),
    committed_version bigint NOT NULL CHECK (committed_version >= 2),
    response_public jsonb NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(response_public) = 'object'
           AND NOT (response_public ?| ARRAY['checkpoint','initial_deck','private_checkpoint','opponent_hands'])),
    committed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (match_id, actor_player_id, action_id),
    UNIQUE (match_id, committed_version),
    FOREIGN KEY (match_id, actor_player_id)
      REFERENCES rex_candidate.match_seat(match_id, player_id) ON DELETE RESTRICT
);

CREATE TABLE rex_candidate.match_event (
    match_id text NOT NULL REFERENCES rex_candidate.match_state(match_id) ON DELETE RESTRICT,
    event_seq bigint NOT NULL CHECK (event_seq > 0),
    committed_version bigint NOT NULL CHECK (committed_version >= 2),
    event_type text NOT NULL CHECK (length(event_type) BETWEEN 1 AND 100),
    event_public jsonb NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(event_public) = 'object'
           AND NOT (event_public ?| ARRAY['checkpoint','initial_deck','private_checkpoint','opponent_hands'])),
    committed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (match_id, event_seq)
);

CREATE TABLE rex_candidate.event_outbox (
    match_id text NOT NULL,
    event_seq bigint NOT NULL,
    dispatched_at timestamptz,
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    PRIMARY KEY (match_id, event_seq),
    FOREIGN KEY (match_id, event_seq)
      REFERENCES rex_candidate.match_event(match_id, event_seq) ON DELETE RESTRICT
);

CREATE TABLE rex_candidate.deal_settlement (
    match_id text NOT NULL REFERENCES rex_candidate.match_state(match_id) ON DELETE RESTRICT,
    deal_index smallint NOT NULL CHECK (deal_index BETWEEN 1 AND 8),
    contract text NOT NULL CHECK (contract IN ('complex', 'trix')),
    score_delta integer[] NOT NULL CHECK (array_length(score_delta, 1) = 4),
    committed_version bigint NOT NULL CHECK (committed_version >= 2),
    PRIMARY KEY (match_id, deal_index)
);

CREATE INDEX event_outbox_pending ON rex_candidate.event_outbox(match_id, event_seq)
    WHERE dispatched_at IS NULL;
CREATE INDEX event_by_version ON rex_candidate.match_event(match_id, committed_version);
COMMIT;
