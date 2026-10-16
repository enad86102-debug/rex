import 'package:flutter/services.dart';

abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String? value);
}

// Android implements this channel with AES-GCM and a non-exportable Keystore
// key. No fallback to plaintext preferences or in-memory pretend persistence.
class AndroidVault implements SessionVault {
  static const _channel = MethodChannel('rex/session_vault');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String? value) =>
      _channel.invokeMethod<void>('write', value);
}
