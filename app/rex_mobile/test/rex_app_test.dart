import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_mobile/main.dart';

void main() {
  test('table scene contract exposes stable environments and anchors', () {
    expect(rexEnvironmentFromId('wadi_rum'), RexEnvironment.wadiRum);
    expect(rexEnvironmentFromId('unknown'), RexEnvironment.royalHall);
    expect(rexSeatDefinitions.map((seat) => seat.id),
        ['north', 'east', 'south', 'west']);
    expect(rexSeatDefinitions[0].anchor, const Alignment(0, -.68));
    expect(rexSeatDefinitions[1].anchor, const Alignment(.68, 0));
  });

  testWidgets('official splash renders REX identity', (tester) async {
    await tester.pumpWidget(const RexApp());
    expect(find.text('REX'), findsOneWidget);
    expect(find.text('جار التحميل...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
  testWidgets('table renders local hand and controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RexTablePage()));
    expect(find.text('طاولة REX'), findsOneWidget);
    expect(find.text('رمي البطاقة'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Card'),
      findsNWidgets(13),
    );
  });

  testWidgets('main CTA opens the game selection', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RexHome()));
    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pumpAndSettle();
    expect(find.text('ألعاب REX'), findsOneWidget);
    expect(find.text('تريكس كومبلكس'), findsOneWidget);
    expect(find.text('طرنيب'), findsOneWidget);
  });

  testWidgets('official preview journey reaches the table', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RexGameSelection()));
    await tester.tap(find.text('تريكس كومبلكس'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('القاعة الملكية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وادي رم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ الجلسة').last);
    await tester.pumpAndSettle();
    expect(find.text('طاولة REX'), findsOneWidget);
    expect(find.text('رمي البطاقة'), findsOneWidget);
  });

  testWidgets('table preview reaches local victory screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RexTablePage()));
    await tester.tap(find.text('فوز تجريبي'));
    await tester.pumpAndSettle();
    expect(find.text('فوز رائع!'), findsOneWidget);
    expect(find.text('العب مجددًا'), findsOneWidget);
  });
}
