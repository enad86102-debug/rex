-- REX prospective transactional match schema (D2 candidate only).
-- Not enabled in rexd. No raw cards/checkpoint plaintext may be written here.
-- Execute with a non-production, least-privilege role in isolated integration CI.
CREATE SCHEMA IF NOT EXISTS rex_candidate;

CREATE TABLE rex_candidate.matches (
    match_id text PRIMARY KEY CHECK (length(match_id) BETWEEN 1 AND 128),
    table_id text NOT NULL CHECK (length(table_id) BETWEEN 1 AND 128),
    game_id text NOT NULL CHECK (game_id IN ('trix_complex', 'tarneeb')),
    rules_version text NOT NULL CHECK (length(rules_version) > 0),
    status text NOT NULL CHECK (status IN ('active', 'paused', 'finished')),
    state_version bigint NOT NULL CHECK (state_version > 0),
    encrypted_checkpoint bytea NOT NULL CHECK (octet_length(encrypted_checkpoint) >= 16),
    nonce bytea NOT NULL CHECK (octet_length(nonce) = 12),
    key_id text NOT NULL CHECK (length(key_id) >= 3),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX one_live_match_per_table
  ON rex_candidate.matches(table_id)
  WHERE status IN ('active', 'paused');

CREATE TABLE rex_candidate.match_seats (
    match_id text NOT NULL REFERENCES rex_candidate.matches(match_id) ON DELETE RESTRICT,
    seat smallint NOT NULL CHECK (seat BETWEEN 0 AND 3),
    player_id text NOT NULL CHECK (length(player_id) > 0),
    PRIMARY KEY(match_id, seat),
    UNIQUE(match_id, player_id)
);

CREATE TABLE rex_candidate.action_receipts (
    match_id text NOT NULL REFERENCES rex_candidate.matches(match_id) ON DELETE RESTRICT,
    player_id text NOT NULL,
    action_id text NOT NULL CHECK (length(action_id) BETWEEN 16 AND 128),
    request_hash bytea NOT NULL CHECK (octet_length(request_hash) = 32),
    accepted_version bigint NOT NULL CHECK (accepted_version > 1),
    public_ack jsonb NOT NULL CHECK (jsonb_typeof(public_ack) = 'object'),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY(match_id, player_id, action_id),
    FOREIGN KEY (match_id, player_id)
      REFERENCES rex_candidate.match_seats(match_id, player_id)
);

CREATE TABLE rex_candidate.match_events (
    match_id text NOT NULL REFERENCES rex_candidate.matches(match_id) ON DELETE RESTRICT,
    state_version bigint NOT NULL CHECK (state_version > 1),
    ordinal smallint NOT NULL CHECK (ordinal BETWEEN 0 AND 99),
    public_payload jsonb NOT NULL CHECK (jsonb_typeof(public_payload) = 'object'),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY(match_id, state_version, ordinal)
);

CREATE TABLE rex_candidate.outbox_events (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id text NOT NULL,
    state_version bigint NOT NULL,
    ordinal smallint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    delivered_at timestamptz,
    UNIQUE(match_id, state_version, ordinal),
    FOREIGN KEY (match_id, state_version, ordinal)
      REFERENCES rex_candidate.match_events(match_id, state_version, ordinal)
);

CREATE TABLE rex_candidate.match_settlements (
    match_id text PRIMARY KEY REFERENCES rex_candidate.matches(match_id) ON DELETE RESTRICT,
    settled_version bigint NOT NULL CHECK (settled_version > 1),
    final_scores jsonb NOT NULL CHECK (jsonb_typeof(final_scores) = 'array' AND jsonb_array_length(final_scores) = 4),
    settled_at timestamptz NOT NULL DEFAULT now()
);

-- One database transaction for mutation, receipt, event, outbox and settlement.
-- Caller MUST authenticate bearer, authorize roster and validate GameAction
-- against the server rules engine BEFORE calling this function.
-- The bytes must already be AEAD encrypted using a key OUTSIDE this database.
CREATE FUNCTION rex_candidate.record_match_transition(
    p_match_id text,
    p_player_id text,
    p_action_id text,
    p_expected_version bigint,
    p_request_hash bytea,
    p_public_ack jsonb,
    p_encrypted_checkpoint bytea,
    p_nonce bytea,
    p_key_id text,
    p_public_events jsonb,
    p_final_scores jsonb DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SET search_path = pg_catalog, rex_candidate
AS $body$
DECLARE
    current_match rex_candidate.matches%ROWTYPE;
    old_receipt rex_candidate.action_receipts%ROWTYPE;
    next_version bigint;
    event_record jsonb;
    idx integer := 0;
    delivered_ack jsonb;
BEGIN
    IF p_match_id IS NULL OR p_player_id IS NULL OR
       length(p_action_id) < 16 OR length(p_action_id) > 128 OR
       octet_length(p_request_hash) <> 32 OR
       octet_length(p_encrypted_checkpoint) < 16 OR
       octet_length(p_nonce) <> 12 OR
       p_key_id IS NULL OR length(p_key_id) < 3 OR
       jsonb_typeof(p_public_ack) IS DISTINCT FROM 'object' OR
       jsonb_typeof(p_public_events) IS DISTINCT FROM 'array' OR
       jsonb_array_length(p_public_events) NOT BETWEEN 1 AND 100 OR
       (p_final_scores IS NOT NULL AND
         (jsonb_typeof(p_final_scores) IS DISTINCT FROM 'array' OR
          jsonb_array_length(p_final_scores) <> 4)) THEN
        RAISE EXCEPTION 'invalid_match_transition' USING ERRCODE = '22023';
    END IF;

    -- Row lock serializes concurrent clients competing for the same version.
    SELECT * INTO current_match FROM rex_candidate.matches
     WHERE match_id = p_match_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found' USING ERRCODE = 'P0002';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM rex_candidate.match_seats
                   WHERE match_id = p_match_id AND player_id = p_player_id) THEN
        RAISE EXCEPTION 'match_actor_not_authorized' USING ERRCODE = '42501';
    END IF;

    -- Receipt lookup before version check: same accepted action can be retried
    -- after a lost response, without duplicating event/score mutations.
    SELECT * INTO old_receipt FROM rex_candidate.action_receipts
      WHERE match_id = p_match_id
        AND player_id = p_player_id
        AND action_id = p_action_id;
    IF FOUND THEN
        IF old_receipt.request_hash <> p_request_hash THEN
            RAISE EXCEPTION 'action_id_conflict' USING ERRCODE = '23505';
        END IF;
        RETURN jsonb_build_object('duplicate', true,
                                  'state_version', old_receipt.accepted_version,
                                  'ack', old_receipt.public_ack);
    END IF;

    IF current_match.status <> 'active' THEN
        RAISE EXCEPTION 'match_not_active' USING ERRCODE = '55000';
    END IF;
    IF current_match.state_version <> p_expected_version THEN
        RAISE EXCEPTION 'match_version_conflict' USING ERRCODE = '40001';
    END IF;
    next_version := current_match.state_version + 1;
    delivered_ack := p_public_ack || jsonb_build_object('version', next_version);

    UPDATE rex_candidate.matches
       SET state_version = next_version,
           encrypted_checkpoint = p_encrypted_checkpoint,
           nonce = p_nonce, key_id = p_key_id,
           status = CASE WHEN p_final_scores IS NULL THEN status ELSE 'finished' END,
           updated_at = now()
     WHERE match_id = p_match_id;

    INSERT INTO rex_candidate.action_receipts
      (match_id, player_id, action_id, request_hash, accepted_version, public_ack)
    VALUES (p_match_id, p_player_id, p_action_id, p_request_hash, next_version, delivered_ack);

    FOR event_record IN SELECT value FROM jsonb_array_elements(p_public_events) LOOP
        IF jsonb_typeof(event_record) <> 'object' THEN
            RAISE EXCEPTION 'invalid_public_event' USING ERRCODE = '22023';
        END IF;
        INSERT INTO rex_candidate.match_events
          (match_id, state_version, ordinal, public_payload)
        VALUES (p_match_id, next_version, idx, event_record);
        INSERT INTO rex_candidate.outbox_events(match_id, state_version, ordinal)
        VALUES (p_match_id, next_version, idx);
        idx := idx + 1;
    END LOOP;

    IF p_final_scores IS NOT NULL THEN
        INSERT INTO rex_candidate.match_settlements(match_id, settled_version, final_scores)
        VALUES (p_match_id, next_version, p_final_scores);
    END IF;

    RETURN jsonb_build_object('duplicate', false,
                              'state_version', next_version,
                              'ack', delivered_ack);
END;
$body$;
