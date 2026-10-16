import 'package:integration_test/integration_test_driver.dart';

// flutter drive keeps the package installed, allowing the host to inspect the
// encrypted record and force-stop/relaunch the actual Android process.
Future<void> main() => integrationDriver();
