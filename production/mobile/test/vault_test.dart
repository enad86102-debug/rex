import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rex_production/vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('rex/session_vault');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('secure vault round trip and deletion', () async {
    String? stored;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return stored;
        case 'write':
          stored = call.arguments as String?;
          return null;
        default:
          throw MissingPluginException();
      }
    });

    final vault = PlatformSessionVault();
    expect(await vault.read(), isNull);
    await vault.write('جلسة REX — test 🔐');
    expect(await vault.read(), 'جلسة REX — test 🔐');
    await vault.write(null);
    expect(await vault.read(), isNull);
  });

  test('missing native implementation fails closed', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final vault = PlatformSessionVault();
    await expectLater(vault.read(), throwsA(isA<MissingPluginException>()));
    await expectLater(
      vault.write('do-not-store-in-plaintext'),
      throwsA(isA<MissingPluginException>()),
    );
  });

  test('native storage failures propagate', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'vault_unavailable');
    });
    final vault = PlatformSessionVault();
    await expectLater(
      vault.write('secret'),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(vault.read(), throwsA(isA<PlatformException>()));
  });
}
