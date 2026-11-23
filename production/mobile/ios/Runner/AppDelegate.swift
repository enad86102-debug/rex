import Flutter
import Security
import UIKit

/// Native secure-session channel. No plaintext or iCloud-synchronized fallback.
final class RexSessionKeychain {
  private let service: String
  private let account = "active_session"

  init(service: String = "dev.rex.internal.session.v1") {
    self.service = service
  }

  private var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrSynchronizable as String: false
    ]
  }

  func read() throws -> String? {
    var lookup = query
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(lookup as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess,
      let data = item as? Data,
      let value = String(data: data, encoding: .utf8)
    else { throw VaultError.unavailable }
    return value
  }

  func write(_ value: String?) throws {
    guard let value = value else {
      let status = SecItemDelete(query as CFDictionary)
      if status != errSecSuccess && status != errSecItemNotFound {
        throw VaultError.unavailable
      }
      return
    }

    let data = Data(value.utf8)
    guard data.count <= 16_384 else { throw VaultError.unavailable }
    let status = SecItemUpdate(query as CFDictionary, [
      kSecValueData as String: data
    ] as CFDictionary)
    if status == errSecSuccess { return }
    guard status == errSecItemNotFound else { throw VaultError.unavailable }

    var attributes = query
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    attributes[kSecValueData as String] = data
    guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else {
      throw VaultError.unavailable
    }
  }

  private enum VaultError: Error {
    case unavailable
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let sessionKeychain = RexSessionKeychain()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "rex/session_vault",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [sessionKeychain] call, result in
        do {
          switch call.method {
          case "read":
            result(try sessionKeychain.read())
          case "write":
            if call.arguments == nil || call.arguments is NSNull {
              try sessionKeychain.write(nil)
            } else if let value = call.arguments as? String {
              try sessionKeychain.write(value)
            } else {
              throw NSError(domain: "REXSessionVault", code: 1)
            }
            result(nil)
          default:
            result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(
            code: "vault_unavailable",
            message: "Secure session storage unavailable",
            details: nil
          ))
        }
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
