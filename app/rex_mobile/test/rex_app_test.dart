import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_mobile/main.dart';

void main() {
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
}
