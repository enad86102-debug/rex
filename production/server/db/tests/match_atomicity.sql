-- CI ONLY: execute against a disposable postgres test service.
BEGIN;
INSERT INTO rex_candidate.matches
  (match_id,table_id,game_id,rules_version,status,state_version,encrypted_checkpoint,nonce,key_id)
VALUES ('match-ci-1','table-ci-1','trix_complex','CANDIDATE/0.9','active',1,
        decode(repeat('ab',32),'hex'),decode(repeat('0a',12),'hex'),'ci-only-key');
INSERT INTO rex_candidate.match_seats(match_id,seat,player_id) VALUES
 ('match-ci-1',0,'player-north'),
 ('match-ci-1',1,'player-east'),
 ('match-ci-1',2,'player-south'),
 ('match-ci-1',3,'player-west');
COMMIT;

SELECT rex_candidate.record_match_transition(
  'match-ci-1','player-north','ci-action-000000001',1,
  decode(repeat('01',32),'hex'), '{"status":"accepted"}'::jsonb,
  decode(repeat('ff',32),'hex'), decode(repeat('01',12),'hex'), 'ci-only-key',
  '[{"type":"contract_selected"}]'::jsonb
);
DO $$
BEGIN
 IF (SELECT state_version FROM rex_candidate.matches WHERE match_id='match-ci-1') <> 2 THEN
   RAISE EXCEPTION 'version increment not atomic';
 END IF;
 IF (SELECT count(*) FROM rex_candidate.action_receipts WHERE match_id='match-ci-1') <> 1 THEN
   RAISE EXCEPTION 'missing durable receipt';
 END IF;
 IF (SELECT count(*) FROM rex_candidate.match_events WHERE match_id='match-ci-1') <> 1 OR
    (SELECT count(*) FROM rex_candidate.outbox_events WHERE match_id='match-ci-1') <> 1 THEN
   RAISE EXCEPTION 'event and outbox not written in same transaction';
 END IF;
END $$;
-- Same accepted action/version may be retried without duplicating mutations.
DO $$
DECLARE result jsonb;
BEGIN
 result := rex_candidate.record_match_transition(
  'match-ci-1','player-north','ci-action-000000001',1,
  decode(repeat('01',32),'hex'), '{"status":"accepted"}'::jsonb,
  decode(repeat('ee',32),'hex'), decode(repeat('02',12),'hex'), 'ci-only-key',
  '[{"type":"different_attempt_ignored"}]'::jsonb);
 IF result->>'duplicate' <> 'true' OR (result->>'state_version')::int <> 2 THEN
   RAISE EXCEPTION 'duplicate receipt not idempotent';
 END IF;
 IF (SELECT count(*) FROM rex_candidate.outbox_events WHERE match_id='match-ci-1') <> 1 THEN
   RAISE EXCEPTION 'duplicate action wrote outbox';
 END IF;
END $$;
-- Reusing same action ID with different fingerprint is forbidden.
DO $$
BEGIN
 PERFORM rex_candidate.record_match_transition(
  'match-ci-1','player-north','ci-action-000000001',1,
  decode(repeat('02',32),'hex'), '{"status":"accepted"}'::jsonb,
  decode(repeat('aa',32),'hex'), decode(repeat('03',12),'hex'), 'ci-only-key',
  '[{"type":"x"}]'::jsonb);
 RAISE EXCEPTION 'receipt conflict accepted';
EXCEPTION WHEN unique_violation THEN
 NULL;
END $$;
-- A stale version must be rejected.
DO $$
BEGIN
 PERFORM rex_candidate.record_match_transition(
  'match-ci-1','player-east','ci-action-000000002',1,
  decode(repeat('03',32),'hex'), '{}'::jsonb,
  decode(repeat('aa',32),'hex'),decode(repeat('03',12),'hex'),'ci-only-key',
  '[{"type":"x"}]'::jsonb);
 RAISE EXCEPTION 'stale version accepted';
EXCEPTION WHEN serialization_failure THEN
 NULL;
END $$;
-- A nonmember must not be allowed to act.
DO $$
BEGIN
 PERFORM rex_candidate.record_match_transition(
  'match-ci-1','outsider','ci-action-000000003',2,
  decode(repeat('03',32),'hex'), '{}'::jsonb,
  decode(repeat('aa',32),'hex'),decode(repeat('03',12),'hex'),'ci-only-key',
  '[{"type":"x"}]'::jsonb);
 RAISE EXCEPTION 'unauthorized actor accepted';
EXCEPTION WHEN insufficient_privilege THEN
 NULL;
END $$;
-- The second transaction can roll back all side-effects, including outbox.
BEGIN;
SELECT rex_candidate.record_match_transition(
 'match-ci-1','player-east','ci-action-000000004',2,
 decode(repeat('04',32),'hex'),'{}'::jsonb,
 decode(repeat('aa',32),'hex'),decode(repeat('04',12),'hex'),'ci-only-key',
 '[{"type":"rollback_test"}]'::jsonb);
ROLLBACK;
DO $$
BEGIN
 IF (SELECT state_version FROM rex_candidate.matches WHERE match_id='match-ci-1') <> 2 OR
 (SELECT count(*) FROM rex_candidate.action_receipts WHERE match_id='match-ci-1') <> 1 OR
 (SELECT count(*) FROM rex_candidate.outbox_events WHERE match_id='match-ci-1') <> 1 THEN
    RAISE EXCEPTION 'rollback did not restore atomic match state';
 END IF;
END $$;

-- No public/production data used. Leave CI database disposable.
