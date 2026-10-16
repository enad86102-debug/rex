import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/controller.dart';
import 'package:rex_production/main.dart';
import 'package:rex_production/strings.dart';

import 'controller_test.dart' show MemoryVault, Transport;

void main() {
  for (final size in [const Size(320, 640), const Size(800, 1280)]) {
    testWidgets('Arabic guest and private-table entry fits $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = RexController(Transport(), MemoryVault());
      await tester.pumpWidget(RexApp(controller: c));
      await tester.pumpAndSettle();
      final entry = find.text(RexStrings.guest);
      expect(entry, findsOneWidget);
      expect(Directionality.of(tester.element(entry)), TextDirection.rtl);
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text(RexStrings.create), findsOneWidget);
      expect(find.text(RexStrings.unavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
