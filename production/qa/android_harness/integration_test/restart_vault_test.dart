import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rex_production/api.dart';
import 'package:rex_production/controller.dart';
import 'package:rex_production/vault.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'cold Android process restores encrypted account and real table, then logs out',
    (tester) async {
      const endpoint = String.fromEnvironment('REX_TEST_API_URL');
      final vault = AndroidVault();
      final saved = await vault.read();
      expect(saved, isNotNull, reason: 'Phase one must persist a real session');
      final record = jsonDecode(saved!) as Map<String, dynamic>;
      expect(record['qa_marker'], 'rex-qa-public-persistence-marker');
      final c = RexController(RexApi(endpoint, allowLoopbackHttp: true), vault);
      addTearDown(c.dispose);
      await c.initialize();
      expect(c.error, isNull);
      expect(c.signedIn, isTrue);
      expect((c.me!['player'] as Map)['id'], record['qa_expected_player']);
      expect(c.table!['id'], record['qa_expected_table']);
      await c.logout();
      expect(c.error, isNull);
      expect(c.signedIn, isFalse);
      expect(await vault.read(), isNull);
    },
  );
}
