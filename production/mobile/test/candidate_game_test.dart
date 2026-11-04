import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/candidate_game.dart';

Map<String, dynamic> matchState({
  bool canPass = false,
  List<Map<String, dynamic>>? cards,
}) {
  return {
    'view': {
      'match_id': 'candidate-only',
      'version': 7,
      'kingdom': 0,
      'completed_deals': 0,
      'phase': 'trix_active',
      'contract': 'trix',
      'seat': 2,
      'turn': 2,
      'scores': [0, -25, 50, -25],
      'hand': cards ??
          [
            {'suit': 2, 'rank': 11},
            {'suit': 3, 'rank': 12},
          ],
      'trick': {'plays': <Object>[]},
      'layout': {
        'low': [0, 0, 11, 0],
        'high': [0, 0, 11, 0],
      },
    },
    'legal_moves': {
      'version': 7,
      'cards': canPass
          ? <Object>[]
          : [
              {'suit': 2, 'rank': 11},
            ],
      'can_pass': canPass,
    },
  };
}

void main() {
  testWidgets('only server-sanctioned hand cards are interactive', (
    tester,
  ) async {
    String? issued;
    Map<String, dynamic>? sent;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateGamePanel(
              response: matchState(),
              busy: false,
              onAction: (type, payload) async {
                issued = type;
                sent = payload;
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('J♥'), findsOneWidget);
    expect(find.text('Q♠'), findsOneWidget);
    final blocked = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Q♠'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(blocked.onPressed, isNull);
    await tester.ensureVisible(find.text('J♥'));
    await tester.tap(find.text('J♥'));
    await tester.pump();
    expect(issued, 'play_card');
    expect(sent, {
      'card': {'suit': 2, 'rank': 11},
    });
  });

  testWidgets('candidate pass button requires server can_pass', (
    tester,
  ) async {
    String? issued;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateGamePanel(
              response: matchState(canPass: true, cards: []),
              busy: false,
              onAction: (type, _) async {
                issued = type;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('تمرير — لا توجد ورقة قانونية'));
    await tester.pump();
    expect(issued, 'pass');
  });

  testWidgets('inactive seat cannot choose legal move', (tester) async {
    final data = matchState();
    (data['view'] as Map<String, dynamic>)['turn'] = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateGamePanel(
              response: data,
              busy: false,
              onAction: (_, __) async {},
            ),
          ),
        ),
      ),
    );
    final blocked = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('J♥'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(blocked.onPressed, isNull);
  });
}
