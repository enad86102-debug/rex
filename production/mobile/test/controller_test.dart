import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/api.dart';
import 'package:rex_production/controller.dart';
import 'package:rex_production/vault.dart';

class MemoryVault implements SessionVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? value) async => this.value = value;
}

class ReadFailingVault extends MemoryVault {
  @override
  Future<String?> read() async => throw StateError('keystore unavailable');
}

class Transport implements RexTransport {
  final calls = <Map<String, dynamic>>[];
  bool loseResponse = false;
  bool unauthorized = false;
  Completer<void>? blockedRead;
  Map<String, dynamic>? table;
  @override
  void close() {}
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    calls.add({'method': method, 'path': path, 'body': body});
    if (unauthorized) throw const ApiFailure('unauthorized', status: 401);
    if (path == '/v1/guests') {
      return {
        'token': 'test-token',
        'me': {
          'player': {'id': 'owner'},
        },
      };
    }
    if (method == 'POST') {
      table = {'id': 'table', 'version': 1, 'seats': []};
      if (loseResponse) throw const ApiFailure('connection_failed');
      return table!;
    }
    if (path == '/v1/me') {
      await blockedRead?.future;
      return {
        'player': {'id': 'owner'},
        if (table != null) 'table_id': 'table',
      };
    }
    return table!;
  }
}

void main() {
  test(
    'corrupt saved session requires explicit reset and then permits entry',
    () async {
      for (final damaged in ['{broken', '[]', '{"token":null}']) {
        final vault = MemoryVault()..value = damaged;
        final c = RexController(Transport(), vault);
        await c.initialize();
        expect(c.recoveryRequired, isTrue);
        expect(c.initialized, isFalse);
        expect(c.error, 'invalid_local_session');
        expect(vault.value, damaged);
        await c.resetCorruptSession();
        expect(vault.value, isNull);
        expect(c.recoveryRequired, isFalse);
        expect(c.initialized, isTrue);
        await c.enterGuest();
        expect(c.signedIn, isTrue);
        c.dispose();
      }
    },
  );

  test(
    'temporary secure-store read failure never offers destructive reset',
    () async {
      final vault = ReadFailingVault()
        ..value = '{"token":"saved","pending":null}';
      final c = RexController(Transport(), vault);
      addTearDown(c.dispose);
      await c.initialize();
      expect(c.recoveryRequired, isFalse);
      expect(c.error, 'secure_storage_or_response_failed');
      await c.resetCorruptSession();
      expect(vault.value, isNotNull);
    },
  );

  test(
    'ambiguous command survives process death with original action ID',
    () async {
      final vault = MemoryVault();
      final transport = Transport();
      final c = RexController(transport, vault);
      await c.initialize();
      await c.enterGuest();
      transport.loseResponse = true;
      await c.create('tarneeb');
      expect(c.hasPendingAction, isTrue);
      final saved = jsonDecode(vault.value!) as Map<String, dynamic>;
      final id = ((saved['pending'] as Map)['body'] as Map)['action_id'];
      final before = transport.calls
          .where((x) => x['path'] == '/v1/tables')
          .length;
      await c.create('trix_complex');
      expect(
        transport.calls.where((x) => x['path'] == '/v1/tables').length,
        before,
      );
      c.dispose();
      transport.loseResponse = false;
      final restored = RexController(transport, vault);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.table?['id'], 'table');
      expect(restored.hasPendingAction, isFalse);
      final last = transport.calls.lastWhere((x) => x['path'] == '/v1/tables');
      expect((last['body'] as Map)['action_id'], id);
    },
  );

  test(
    'expired session clears private state and secure local record',
    () async {
      final vault = MemoryVault();
      final transport = Transport();
      final c = RexController(transport, vault);
      addTearDown(c.dispose);
      await c.initialize();
      await c.enterGuest();
      await c.create('tarneeb');
      transport.unauthorized = true;
      await c.refresh();
      expect(c.signedIn, isFalse);
      expect(c.table, isNull);
      expect(vault.value, isNull);
    },
  );

  test(
    'action waits for a concurrent poll and is never silently dropped',
    () async {
      final transport = Transport();
      final c = RexController(transport, MemoryVault());
      addTearDown(c.dispose);
      await c.initialize();
      await c.enterGuest();
      transport.blockedRead = Completer<void>();
      final refresh = c.refresh();
      await Future<void>.delayed(Duration.zero);
      final action = c.create('tarneeb');
      transport.blockedRead!.complete();
      await refresh;
      await action;
      expect(c.table?['id'], 'table');
      expect(transport.calls.where((x) => x['path'] == '/v1/tables').length, 1);
    },
  );

  test('production transport rejects insecure and credential-bearing URLs', () {
    for (final url in [
      'http://example.com',
      'https://user:pass@example.com',
      'https://example.com?token=x',
      '',
    ]) {
      expect(() => RexApi(url), throwsA(isA<ApiFailure>()));
    }
    final api = RexApi('https://example.com');
    api.close();
  });

  test('valid guest token survives corrupt or unsafe pending action', () async {
    for (final pending in [
      {'path': 5, 'body': <String, dynamic>{}},
      {
        'path': '/v1/guests',
        'body': {'action_id': 'a' * 32},
      },
      {
        'path': '/v1/tables',
        'body': {'action_id': 'not-an-action-id'},
      },
    ]) {
      final saved = jsonEncode({'token': 'saved-token', 'pending': pending});
      final vault = MemoryVault()..value = saved;
      final transport = Transport();
      final c = RexController(transport, vault);
      await c.initialize();
      expect(c.recoveryRequired, isTrue);
      expect(c.canPreserveSession, isTrue);
      expect(c.error, 'invalid_local_action');
      expect(vault.value, saved);
      expect(transport.calls, isEmpty);
      await c.resetCorruptSession();
      expect(c.signedIn, isTrue);
      expect(c.error, isNull);
      expect(jsonDecode(vault.value!)['token'], 'saved-token');
      expect(jsonDecode(vault.value!)['pending'], isNull);
      expect(transport.calls.map((call) => call['path']), ['/v1/me']);
      c.dispose();
    }
  });
}
