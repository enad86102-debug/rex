import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/controller.dart';
import 'package:rex_production/main.dart';
import 'package:rex_production/strings.dart';

import 'controller_test.dart' show MemoryVault, Transport;

class RoomTransport extends Transport {
  static const owner = '0123456789abcdef0123456789abcdef';
  RoomTransport() {
    table = {
      'id': 'room',
      'game': 'tarneeb',
      'invite': 'a' * 32,
      'version': 4,
      'seats': [
        {'player_id': owner, 'ready': true},
        {'player_id': '1' * 32, 'ready': false},
        {'player_id': '2' * 32, 'ready': true},
        null,
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    if (path == '/v1/me') {
      return {
        'player': {'id': owner},
        'table_id': 'room',
      };
    }
    final result = await super.request(method, path, token: token, body: body);
    if (path == '/v1/guests') {
      result['me'] = {
        'player': {'id': owner},
      };
    }
    return result;
  }
}

void main() {
  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets(
      'waiting room supports landscape, large Arabic text and tap targets $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        try {
          final c = RexController(RoomTransport(), MemoryVault());
          await c.initialize();
          await c.enterGuest();
          await c.retry();
          await tester.pumpWidget(RexApp(controller: c));
          await tester.pumpAndSettle();
          expect(find.text(RexStrings.game('tarneeb')), findsOneWidget);
          await tester.ensureVisible(find.text(RexStrings.copy));
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );
  }
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
