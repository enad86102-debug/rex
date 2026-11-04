-- Run AFTER 001_create_schema.sql on an isolated PostgreSQL database.
-- This test checks database constraints/rollback; it does NOT prove a Go adapter exists.
\set ON_ERROR_STOP on
BEGIN;
INSERT INTO rex_candidate.match_state
 (match_id, room_id, game_id, rules_version, state_version, roster_revision,
  checkpoint_ciphertext, checkpoint_nonce, checkpoint_key_id, phase)
VALUES ('match-a', 'room-a', 'trix_complex', 'candidate/unapproved', 1, 5,
  decode(repeat('a1', 32), 'hex'), decode(repeat('11', 12), 'hex'), 'ci-only-k1', 'contract_selection');
INSERT INTO rex_candidate.match_seat(match_id, seat, player_id) VALUES
 ('match-a', 0, 'player-0'), ('match-a', 1, 'player-1'),
 ('match-a', 2, 'player-2'), ('match-a', 3, 'player-3');
COMMIT;

-- Accepted action, receipt, public event, and outbox are in ONE SQL transaction.
BEGIN;
UPDATE rex_candidate.match_state SET state_version=2, phase='complex_active', updated_at=now()
 WHERE match_id='match-a' AND state_version=1;
INSERT INTO rex_candidate.action_receipt
 (match_id, actor_player_id, action_id, request_sha256, committed_version, response_public)
VALUES ('match-a','player-0','action-a-00000001',decode(repeat('aa',32),'hex'),2,'{"status":"accepted"}');
INSERT INTO rex_candidate.match_event
 (match_id,event_seq,committed_version,event_type,event_public)
VALUES ('match-a',1,2,'contract_selected','{"contract":"complex"}');
INSERT INTO rex_candidate.event_outbox(match_id,event_seq) VALUES ('match-a',1);
COMMIT;

DO $$
BEGIN
 IF (SELECT state_version FROM rex_candidate.match_state WHERE match_id='match-a') <> 2 THEN
   RAISE EXCEPTION 'Committed state version missing';
 END IF;
 IF (SELECT count(*) FROM rex_candidate.action_receipt) <> 1 OR
    (SELECT count(*) FROM rex_candidate.match_event) <> 1 OR
    (SELECT count(*) FROM rex_candidate.event_outbox) <> 1 THEN
   RAISE EXCEPTION 'Atomic accept did not persist all rows';
 END IF;
END $$;

-- A failed/rolled-back candidate action leaves NO new state, event or receipt.
BEGIN;
UPDATE rex_candidate.match_state SET state_version=3 WHERE match_id='match-a' AND state_version=2;
INSERT INTO rex_candidate.action_receipt
 (match_id, actor_player_id, action_id, request_sha256, committed_version)
VALUES ('match-a','player-1','action-b-00000001',decode(repeat('bb',32),'hex'),3);
INSERT INTO rex_candidate.match_event
 (match_id,event_seq,committed_version,event_type,event_public)
VALUES ('match-a',2,3,'card_played','{"card":"hidden-from-this-test"}');
INSERT INTO rex_candidate.event_outbox(match_id,event_seq) VALUES ('match-a',2);
ROLLBACK;

DO $$
BEGIN
 IF (SELECT state_version FROM rex_candidate.match_state WHERE match_id='match-a') <> 2 THEN
   RAISE EXCEPTION 'Rollback failed: advanced state';
 END IF;
 IF EXISTS (SELECT 1 FROM rex_candidate.action_receipt WHERE action_id='action-b-00000001') OR
    EXISTS (SELECT 1 FROM rex_candidate.match_event WHERE event_seq=2) OR
    EXISTS (SELECT 1 FROM rex_candidate.event_outbox WHERE event_seq=2) THEN
   RAISE EXCEPTION 'Rollback failed: orphan receipt/event/outbox';
 END IF;
END $$;

DO $$
BEGIN
 -- Duplicate action cannot create a second receipt.
 BEGIN
   INSERT INTO rex_candidate.action_receipt
    (match_id, actor_player_id, action_id, request_sha256, committed_version)
   VALUES ('match-a','player-0','action-a-00000001',decode(repeat('ff',32),'hex'),3);
   RAISE EXCEPTION 'Duplicate action unexpectedly accepted';
 EXCEPTION WHEN unique_violation THEN NULL;
 END;
 -- Another player cannot claim a seat or submit a receipt for an unrelated actor.
 BEGIN
   INSERT INTO rex_candidate.action_receipt
    (match_id,actor_player_id,action_id,request_sha256,committed_version)
   VALUES ('match-a','stranger','action-c-00000001',decode(repeat('ff',32),'hex'),3);
   RAISE EXCEPTION 'Nonmember action unexpectedly accepted';
 EXCEPTION WHEN foreign_key_violation THEN NULL;
 END;
 -- A duplicate seat for another player is prohibited.
 BEGIN
   INSERT INTO rex_candidate.match_seat(match_id,seat,player_id)
   VALUES ('match-a',0,'stranger');
   RAISE EXCEPTION 'Duplicate seat unexpectedly accepted';
 EXCEPTION WHEN unique_violation THEN NULL;
 END;
 -- Invalid non-AEAD nonce shape rejected at DB boundary.
 BEGIN
   INSERT INTO rex_candidate.match_state
    (match_id,room_id,game_id,rules_version,state_version,roster_revision,
     checkpoint_ciphertext,checkpoint_nonce,checkpoint_key_id,phase)
   VALUES ('match-b','room-b','trix_complex','draft',1,1,
     decode(repeat('aa',32),'hex'),decode('11','hex'),'ci-only-k1','contract_selection');
   RAISE EXCEPTION 'Invalid nonce accepted';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
 -- Never store top-level checkpoint in the public receipt.
 BEGIN
   INSERT INTO rex_candidate.action_receipt
    (match_id, actor_player_id, action_id, request_sha256, committed_version, response_public)
   VALUES ('match-a','player-1','action-d-00000001',decode(repeat('ff',32),'hex'),3,'{"checkpoint":"secret"}');
   RAISE EXCEPTION 'Private checkpoint leaked through public receipt';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
END $$;

DO $$
BEGIN
 IF (SELECT count(*) FROM rex_candidate.action_receipt) <> 1 THEN
   RAISE EXCEPTION 'Negative constraint tests wrote unexpected receipts';
 END IF;
END $$;
