import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbt08/main.dart';
import 'package:pbt08/pbt08/widgets/rex_card.dart';
import 'package:pbt08/pbt08/widgets/rex_player_seat.dart';

void main() {
  testWidgets('PBT08 renders the table and four player positions', (
    tester,
  ) async {
    await tester.pumpWidget(const RexSpikeApp());
    expect(find.text('REX'), findsOneWidget);
    expect(find.text('PBT08 • Flutter Device Spike'), findsOneWidget);
    expect(find.byKey(const ValueKey('table-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('center-deck')), findsOneWidget);
    expect(find.byType(RexPlayerSeat), findsNWidgets(4));
    for (final label in [
      'شمال / North',
      'شرق / East',
      'جنوب / South',
      'غرب / West',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('The Arabic deal-test button is available', (tester) async {
    await tester.pumpWidget(const RexSpikeApp());
    expect(find.text('اختبار التوزيع'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('deal-test-button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('The local hand has exactly 13 face-up sample cards', (
    tester,
  ) async {
    await tester.pumpWidget(const RexSpikeApp());
    final handCards = find.descendant(
      of: find.byKey(const ValueKey('local-hand')),
      matching: find.byType(RexCard),
    );
    expect(handCards, findsNWidgets(13));
    for (final card in tester.widgetList<RexCard>(handCards))
      expect(card.faceDown, isFalse);
  });

  testWidgets('Dealing moves cards, completes, and can be repeated', (
    tester,
  ) async {
    await tester.pumpWidget(const RexSpikeApp());
    final button = find.byKey(const ValueKey('deal-test-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byKey(const ValueKey('deal-flight-0')), findsOneWidget);
    final before = tester.getCenter(
      find.byKey(const ValueKey('deal-flight-0')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final after = tester.getCenter(find.byKey(const ValueKey('deal-flight-0')));
    expect(after, isNot(before));
    await tester.pumpAndSettle();
    expect(find.text('اكتملت تجربة التوزيع 1'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('اكتملت تجربة التوزيع 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets('Scene lays out without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const RexSpikeApp());
      await tester.ensureVisible(
        find.byKey(const ValueKey('deal-test-button')),
      );
      expect(find.byType(RexPlayerSeat), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }
}
