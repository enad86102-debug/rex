import Flutter
import UIKit
import XCTest

@testable import Runner

final class RunnerTests: XCTestCase {
  func testKeychainRoundTripAndRemoval() throws {
    let service = "dev.rex.internal.test." + UUID().uuidString
    let vault = RexSessionKeychain(service: service)
    defer { try? vault.write(nil) }

    XCTAssertNil(try vault.read())
    try vault.write("جلسة REX — 🔐")
    XCTAssertEqual(try vault.read(), "جلسة REX — 🔐")
    try vault.write(nil)
    XCTAssertNil(try vault.read())
  }

  func testOversizedRecordRejectedWithoutWriting() throws {
    let service = "dev.rex.internal.test." + UUID().uuidString
    let vault = RexSessionKeychain(service: service)
    defer { try? vault.write(nil) }

    XCTAssertThrowsError(try vault.write(String(repeating: "A", count: 16_385)))
    XCTAssertNil(try vault.read())
  }
}
