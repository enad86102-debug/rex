import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/api.dart';
import 'package:rex_production/controller.dart';

import 'controller_test.dart' show MemoryVault;

void main() {
  final endpoint = Platform.environment['REX_TEST_SERVER_URL'];
  test(
    'four Flutter controllers use real server-backed private rooms',
    () async {
      final clients = List.generate(
        4,
        (_) => RexController(
          RexApi(endpoint!, allowLoopbackHttp: true),
          MemoryVault(),
        ),
      );
      addTearDown(() {
        for (final c in clients) {
          c.dispose();
        }
      });
      for (final c in clients) {
        await c.initialize();
        await c.enterGuest();
        expect(c.error, isNull);
        expect(c.signedIn, isTrue);
      }
      await clients.first.create('tarneeb');
      expect(clients.first.error, isNull);
      final invite = clients.first.table!['invite'] as String;
      final id = clients.first.table!['id'];
      for (final c in clients.skip(1)) {
        await c.join(invite);
        expect(c.error, isNull);
        expect(c.table?['id'], id);
      }
      for (final c in clients) {
        await c.retry();
        await c.ready(true);
        expect(c.error, isNull);
      }
      await clients.first.retry();
      final seats = clients.first.table!['seats'] as List;
      expect(seats.whereType<Map>().length, 4);
      expect(seats.every((seat) => (seat as Map)['ready'] == true), isTrue);
      await clients.last.leave();
      expect(clients.last.table, isNull);
      for (final c in clients) {
        await c.retry();
        await c.logout();
        expect(c.signedIn, isFalse);
      }
    },
    skip: endpoint == null
        ? 'Requires isolated running Go server; see README.'
        : false,
  );
}
