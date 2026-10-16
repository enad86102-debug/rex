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
    await restored.logout();
    expect(restored.error, isNull);
    expect(restored.signedIn, isFalse);
    expect(await vault.read(), isNull);
  });

  testWidgets('leave a public marker for encrypted-preferences inspection', (
    tester,
  ) async {
    // The host checks ciphertext contains no plaintext marker, then clears data.
    await vault.write('rex-qa-public-persistence-marker');
    expect(await vault.read(), 'rex-qa-public-persistence-marker');
  });
}
