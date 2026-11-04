import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/candidate_match_models.dart';
import 'package:rex_production/candidate_match_panel.dart';
import 'package:rex_production/candidate_match_read.dart';
import 'package:rex_production/api.dart';

Map<String, dynamic> example() => {
  'view': {
    'match_id': 'candidate-match-id',
    'rules_version': 'REX-GAME-TRIX-COMPLEX/0.9.0-draft',
    'version': 6,
    'seat': 0,
    'owner': 0,
    'turn': 0,
    'kingdom': 1,
    'phase': 'complex_active',
    'contract': 'complex',
    'completed_deals': 2,
    'hand': [
      {'suit': 0, 'rank': 11},
      {'suit': 2, 'rank': 7},
    ],
    'scores': [100, -50, 20, -70],
    'opponent_counts': [0, 13, 13, 13],
    'trick': {
      'leader': 0,
      'plays': [],
    },
    'layout': {
      'low': [0, 0, 0, 0],
      'high': [0, 0, 0, 0],
    },
    'finish_order': [],
  },
  'legal_moves': {
    'version': 6,
    'cards': [
      {'suit': 0, 'rank': 11},
    ],
    'can_pass': false,
  },
};

class RecordingMatchRead implements RexTransport {
  String? path;
  String? token;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    expect(method, 'GET');
    this.path = path;
    this.token = token;
    expect(body, isNull);
    return example();
  }

  @override
  void close() {}
}

void main() {
  test('candidate snapshot accepts valid server view', () {
    final snapshot = RexCandidateMatchSnapshot.fromServer(example());
    expect(snapshot.hand.length, 2);
    expect(snapshot.legalCards, [const RexCard(0, 11)]);
    expect(snapshot.isMyTurn, isTrue);
    expect(snapshot.scores, [100, -50, 20, -70]);
  });

  test('malformed or stale private responses fail closed', () {
    final leaked = example()..['private_checkpoint'] = {'secret': true};
    expect(
      () => RexCandidateMatchSnapshot.fromServer(leaked),
      throwsFormatException,
    );
    final stale = example();
    (stale['legal_moves'] as Map<String, dynamic>)['version'] = 5;
    expect(
      () => RexCandidateMatchSnapshot.fromServer(stale),
      throwsFormatException,
    );
    final illegal = example();
    (illegal['legal_moves'] as Map<String, dynamic>)['cards'] = [
      {'suit': 3, 'rank': 14},
    ];
    expect(
      () => RexCandidateMatchSnapshot.fromServer(illegal),
      throwsFormatException,
    );
    final duplicate = example();
    (duplicate['view'] as Map<String, dynamic>)['hand'] = [
      {'suit': 2, 'rank': 7},
      {'suit': 2, 'rank': 7},
    ];
    expect(
      () => RexCandidateMatchSnapshot.fromServer(duplicate),
      throwsFormatException,
    );
  });

  test('non-actor cannot receive playable options', () {
    final response = example();
    (response['view'] as Map<String, dynamic>)['turn'] = 1;
    expect(
      () => RexCandidateMatchSnapshot.fromServer(response),
      throwsFormatException,
    );
  });

  test('read-only transport supplies the bearer but never actor_id', () async {
    final transport = RecordingMatchRead();
    final snapshot = await RexCandidateMatchRead(transport).fetch(
      tableId: 'a' * 32,
      bearer: 'b' * 64,
    );
    expect(snapshot.version, 6);
    expect(transport.path, '/v1/tables/${'a' * 32}/match');
    expect(transport.token, 'b' * 64);
    await expectLater(
      RexCandidateMatchRead(transport).fetch(
        tableId: '../private',
        bearer: 'b' * 64,
      ),
      throwsA(isA<ApiFailure>()),
    );
  });

  testWidgets('server legal card is enabled, illegal card is disabled', (
    tester,
  ) async {
    final snapshot = RexCandidateMatchSnapshot.fromServer(example());
    RexCard? played;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RexCandidateMatchPanel(
              snapshot: snapshot,
              onPlayCard: (card) => played = card,
            ),
          ),
        ),
      ),
    );
    final legal = find.byKey(const Key('rex-card-0-11'));
    final blocked = find.byKey(const Key('rex-card-2-7'));
    expect(legal, findsOneWidget);
    expect(blocked, findsOneWidget);
    expect(tester.widget<OutlinedButton>(blocked).onPressed, isNull);
    await tester.ensureVisible(legal);
    await tester.tap(legal);
    expect(played, const RexCard(0, 11));
    expect(find.text('دورك الآن'), findsOneWidget);
    expect(find.text('100'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server-completed match does not fabricate winner', (
    tester,
  ) async {
    final response = example();
    (response['view'] as Map<String, dynamic>)['phase'] = 'match_complete';
    (response['view'] as Map<String, dynamic>)['turn'] = 1;
    (response['legal_moves'] as Map<String, dynamic>)['cards'] = [];
    final snapshot = RexCandidateMatchSnapshot.fromServer(response);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RexCandidateMatchPanel(snapshot: snapshot)),
      ),
    );
    expect(find.textContaining('لم تُعتمد قاعدة كسر التعادل'), findsOneWidget);
    expect(find.byKey(const Key('rex-pass')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
