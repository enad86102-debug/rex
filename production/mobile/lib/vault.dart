import 'package:flutter/services.dart';

/// Shared contract: Android Keystore and iOS Keychain are required native
/// implementations. Missing native handlers are errors, never plaintext storage.
abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String? value);
}

class PlatformSessionVault implements SessionVault {
  static const _channel = MethodChannel('rex/session_vault');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String? value) =>
      _channel.invokeMethod<void>('write', value);
}

/// Temporary compatibility alias for existing Android-only integrations.
@Deprecated('Use PlatformSessionVault for Android and iOS')
class AndroidVault extends PlatformSessionVault {}
