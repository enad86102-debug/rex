import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/api.dart';
import 'package:rex_production/controller.dart';

import 'controller_test.dart' show MemoryVault, Transport;

class FailingVault extends MemoryVault {
  bool failing = false;
  @override
  Future<void> write(String? value) async {
    if (failing) throw StateError('storage unavailable');
    await super.write(value);
  }
}

void main() {
  test(
    'failed guest persistence never publishes a half-initialized identity',
    () async {
      final transport = Transport();
      final vault = FailingVault();
      final c = RexController(transport, vault);
      addTearDown(c.dispose);
      await c.initialize();
      vault.failing = true;
      await c.enterGuest();
      expect(c.signedIn, isFalse);
      expect(c.me, isNull);
      expect(c.error, 'secure_storage_or_response_failed');
      expect(
        transport.calls.any(
          (call) => call['method'] == 'DELETE' && call['path'] == '/v1/session',
        ),
        isTrue,
      );
    },
  );
  test(
    'request deadline cancels a stalled body and later requests recover',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      addTearDown(() async {
        for (final socket in sockets) {
          socket.destroy();
        }
        await server.close();
      });
      final disconnected = Completer<void>();
      server.listen((socket) {
        sockets.add(socket);
        var responded = false;
        socket.listen(
          (data) {
            if (responded) return;
            responded = true;
            final slow = utf8.decode(data).contains('/slow');
            socket.write(
              slow
                  ? 'HTTP/1.1 200 OK\r\nContent-Length: 1000\r\nContent-Type: application/json\r\n\r\n{'
                  : 'HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}',
            );
            if (!slow) unawaited(socket.close());
          },
          onDone: () {
            if (!disconnected.isCompleted) disconnected.complete();
            socket.destroy();
          },
          onError: (Object _) {
            if (!disconnected.isCompleted) disconnected.complete();
            socket.destroy();
          },
        );
      });
      final api = RexApi(
        'http://127.0.0.1:${server.port}',
        allowLoopbackHttp: true,
        requestTimeout: const Duration(milliseconds: 250),
      );
      addTearDown(api.close);
      await expectLater(
        api.request('GET', '/slow'),
        throwsA(isA<ApiFailure>()),
      );
      await disconnected.future.timeout(const Duration(seconds: 2));
      expect(await api.request('GET', '/ok'), isEmpty);
    },
  );

  test(
    'redirects, oversized and malformed responses never become success',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var redirected = false;
      server.listen((request) async {
        switch (request.uri.path) {
          case '/redirect':
            request.response.statusCode = 302;
            request.response.headers.set('Location', '/destination');
            request.response.write('{}');
          case '/destination':
            redirected = true;
            request.response.write('{}');
          case '/large':
            request.response.write('x' * 70000);
          case '/unauthorized':
            request.response.statusCode = 401;
            request.response.write('not JSON');
          default:
            request.response.write('[]');
        }
        await request.response.close();
      });
      final api = RexApi(
        'http://127.0.0.1:${server.port}',
        allowLoopbackHttp: true,
      );
      addTearDown(api.close);
      for (final path in ['/redirect', '/large', '/malformed']) {
        await expectLater(api.request('GET', path), throwsA(isA<ApiFailure>()));
      }
      expect(redirected, isFalse);
      await expectLater(
        api.request('GET', '/unauthorized'),
        throwsA(isA<ApiFailure>().having((f) => f.status, 'status', 401)),
      );
    },
  );

  test(
    'a request path cannot send bearer credentials to another origin',
    () async {
      final destination = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => destination.close(force: true));
      var received = 0;
      destination.listen((request) {
        received++;
        request.response.write('{}');
        unawaited(request.response.close());
      });
      final api = RexApi('http://127.0.0.1:1', allowLoopbackHttp: true);
      addTearDown(api.close);
      for (final path in [
        'http://127.0.0.1:${destination.port}/steal',
        '//127.0.0.1:${destination.port}/steal',
      ]) {
        await expectLater(
          api.request('GET', path, token: 'qa-synthetic-session'),
          throwsA(isA<ApiFailure>()),
        );
      }
      expect(received, 0);
    },
  );

  test(
    'failed secure write cannot later replay an unpersisted action',
    () async {
      final transport = Transport();
      final vault = FailingVault();
      final c = RexController(transport, vault);
      addTearDown(c.dispose);
      await c.initialize();
      await c.enterGuest();
      vault.failing = true;
      await c.create('tarneeb');
      expect(transport.calls.where((x) => x['path'] == '/v1/tables'), isEmpty);
      expect(c.hasPendingAction, isFalse);
      // An in-memory action that never reached durable storage must not be
      // automatically transmitted when a new controller restores the session.
      expect((jsonDecode(vault.value!) as Map)['pending'], isNull);
    },
  );
}
