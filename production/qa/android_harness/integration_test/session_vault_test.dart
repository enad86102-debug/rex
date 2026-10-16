import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rex_production/api.dart';
import 'package:rex_production/controller.dart';
import 'package:rex_production/vault.dart';

// Device-only tests: this file never substitutes an in-memory vault or fake
// transport. Run against a fresh emulator and an isolated Go service.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final vault = AndroidVault();
  String? expectedPlayer;
  String? expectedTable;

  testWidgets('native Keystore round-trip, deletion and size limit', (
    tester,
  ) async {
    await vault.write(null);
    expect(await vault.read(), isNull);
    const value = 'REX QA — جلسة اختبار آمنة';
    await vault.write(value);
    expect(await AndroidVault().read(), value);
    await expectLater(
      vault.write('x' * 20000),
      throwsA(isA<PlatformException>()),
    );
    expect(await vault.read(), value);
    await vault.write(null);
    expect(await vault.read(), isNull);
  });

  testWidgets('real Android session and waiting table restore from Keystore', (
    tester,
  ) async {
    const endpoint = String.fromEnvironment('REX_TEST_API_URL');
    expect(
      endpoint,
      isNotEmpty,
      reason: 'A real isolated Go service is required',
    );
    final first = RexController(
      RexApi(endpoint, allowLoopbackHttp: true),
      vault,
    );
    await first.initialize();
    await first.enterGuest();
    expect(first.error, isNull);
    await first.create('tarneeb');
    expect(first.error, isNull);
    final id = first.table!['id'];
    final player = first.me!['player'];
    first.dispose();

    final restored = RexController(
      RexApi(endpoint, allowLoopbackHttp: true),
      AndroidVault(),
    );
    addTearDown(restored.dispose);
    await restored.initialize();
    expect(restored.error, isNull);
    expect(restored.me!['player'], player);
    expect(restored.table!['id'], id);
    await restored.ready(true);
    expect(restored.error, isNull);
    expectedPlayer = (restored.me!['player'] as Map)['id'] as String;
    expectedTable = id as String;
    // Keep the real session alive for the separate post-force-stop process.
  });

  testWidgets('leave a public marker for encrypted-preferences inspection', (
    tester,
  ) async {
    // Test metadata is stored inside the encrypted record. Production ignores
    // these QA-only keys; no bearer is ever printed or written to host logs.
    final record = jsonDecode((await vault.read())!) as Map<String, dynamic>;
    expect(record['token'], isA<String>());
    expect(expectedPlayer, isNotNull);
    expect(expectedTable, isNotNull);
    record['qa_marker'] = 'rex-qa-public-persistence-marker';
    record['qa_expected_player'] = expectedPlayer;
    record['qa_expected_table'] = expectedTable;
    await vault.write(jsonEncode(record));
  });
}
