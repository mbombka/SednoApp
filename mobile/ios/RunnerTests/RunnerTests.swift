import CryptoKit
import Foundation
import Security
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private var directory: URL!
  private var store: EncryptedHistoryStore!

  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    store = try EncryptedHistoryStore(directory: directory, service: "Sedno.HistoryTests.\(UUID().uuidString)")
  }

  override func tearDownWithError() throws {
    try store.clear()
    if FileManager.default.fileExists(atPath: directory.path) {
      try FileManager.default.removeItem(at: directory)
    }
  }

  func testEncryptionRoundTripAndBackupExclusion() throws {
    let document = "[{\"text\":\"synthetic test fixture\"}]"
    try store.write(document)
    XCTAssertEqual(try store.read(), document)
    let file = directory.appendingPathComponent("history.enc")
    let bytes = try Data(contentsOf: file)
    XCTAssertFalse(bytes.range(of: Data(document.utf8)) != nil)
    XCTAssertEqual(try file.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
  }

  func testTamperedCiphertextIsRejected() throws {
    try store.write("synthetic fixture")
    let file = directory.appendingPathComponent("history.enc")
    var bytes = try Data(contentsOf: file)
    bytes[bytes.count - 1] ^= 1
    try bytes.write(to: file)
    XCTAssertThrowsError(try store.read()) { error in
      guard let failure = error as? EncryptedHistoryStore.Failure, case .corrupt = failure else {
        return XCTFail("Expected a corrupt document")
      }
    }
  }

  func testMissingKeyNeverCreatesReplacementForExistingFile() throws {
    try store.write("synthetic fixture")
    let missingKey = try EncryptedHistoryStore(directory: directory, service: UUID().uuidString)
    XCTAssertThrowsError(try missingKey.read())
    XCTAssertEqual(try store.read(), "synthetic fixture")
  }

  func testClearDeletesDocumentAndKeyThenAllowsFreshWrite() throws {
    try store.write("first")
    try store.clear()
    XCTAssertNil(try store.read())
    try store.write("second")
    XCTAssertEqual(try store.read(), "second")
  }

  func testInstallationMarkerCommitsOnlyAfterExplicitInitialization() throws {
    let installation = try InstallationStateStore(directory: directory)
    XCTAssertTrue(try installation.isFreshInstallation())
    // A crash before Dart clears Keychain and calls markInitialized must remain fresh.
    XCTAssertTrue(try installation.isFreshInstallation())
    try installation.markInitialized()
    XCTAssertFalse(try installation.isFreshInstallation())
    let reopened = try InstallationStateStore(directory: directory)
    XCTAssertFalse(try reopened.isFreshInstallation())
    let marker = directory.appendingPathComponent("initialized.v1")
    XCTAssertEqual(try marker.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
  }

  func testCorruptInstallationMarkerFailsClosed() throws {
    let installation = try InstallationStateStore(directory: directory)
    try installation.markInitialized()
    try Data("invalid fixture".utf8).write(to: directory.appendingPathComponent("initialized.v1"))
    XCTAssertThrowsError(try installation.isFreshInstallation())
  }


  func testPlaybackRemainsPendingUntilItsUtteranceFinishes() {
    let state = PlaybackResultState()
    let utterance = NSObject()
    var completions = 0
    state.begin(utterance) { _ in completions += 1 }
    XCTAssertEqual(completions, 0)
    XCTAssertTrue(state.complete(utterance))
    XCTAssertEqual(completions, 1)
    XCTAssertFalse(state.complete(utterance))
    state.cancel()
    XCTAssertEqual(completions, 1)
  }

  func testPlaybackReplacementIgnoresOldUtteranceCallbacks() {
    let state = PlaybackResultState()
    let first = NSObject()
    let replacement = NSObject()
    var firstCompletions = 0
    var replacementCompletions = 0
    state.begin(first) { _ in firstCompletions += 1 }
    state.begin(replacement) { _ in replacementCompletions += 1 }
    XCTAssertEqual(firstCompletions, 1)
    XCTAssertEqual(replacementCompletions, 0)
    XCTAssertFalse(state.complete(first))
    XCTAssertEqual(replacementCompletions, 0)
    XCTAssertTrue(state.complete(replacement))
    XCTAssertEqual(replacementCompletions, 1)
  }

  func testPlaybackStopCompletesExactlyOnceBeforeLateCancelCallback() {
    let state = PlaybackResultState()
    let utterance = NSObject()
    var completions = 0
    state.begin(utterance) { _ in completions += 1 }
    state.cancel()
    XCTAssertEqual(completions, 1)
    XCTAssertFalse(state.complete(utterance))
    state.cancel()
    XCTAssertEqual(completions, 1)
  }

}
