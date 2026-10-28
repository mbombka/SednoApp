import CryptoKit
import Foundation
import Security

/// A device-bound key and a protected, backup-excluded encrypted document.
/// Retention is enforced by EncryptedHistoryRepository before returning entries.
final class EncryptedHistoryStore {
  enum Failure: Error { case corrupt, storage }
  private let directory: URL
  private let service: String
  private let account = "history.aes256.v1"

  init(directory: URL? = nil, service: String? = nil) throws {
    self.directory = try directory ?? FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true).appendingPathComponent("SednoHistory", isDirectory: true)
    self.service = service ?? "\(Bundle.main.bundleIdentifier ?? "Sedno").history"
  }

  private var file: URL { directory.appendingPathComponent("history.enc") }
  private var query: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service, kSecAttrAccount as String: account,
     kSecAttrSynchronizable as String: false]
  }

  private func key(create: Bool) throws -> SymmetricKey {
    var search = query
    search[kSecReturnData as String] = true
    search[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(search as CFDictionary, &item)
    if status == errSecSuccess, let data = item as? Data, data.count == 32 {
      return SymmetricKey(data: data)
    }
    guard status == errSecItemNotFound else { throw Failure.storage }
    guard create else { throw Failure.corrupt }
    let key = SymmetricKey(size: .bits256)
    var insert = query
    insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    insert[kSecValueData as String] = key.withUnsafeBytes { Data($0) }
    guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw Failure.storage }
    return key
  }

  func read() throws -> String? {
    guard FileManager.default.fileExists(atPath: file.path) else { return nil }
    let bytes = try Data(contentsOf: file)
    guard bytes.first == 1 else { throw Failure.corrupt }
    // A missing key must never be replaced during a read of existing ciphertext.
    let secret = try key(create: false)
    do {
      let box = try AES.GCM.SealedBox(combined: Data(bytes.dropFirst()))
      let plain = try AES.GCM.open(box, using: secret)
      guard let text = String(data: plain, encoding: .utf8) else { throw Failure.corrupt }
      return text
    } catch { throw Failure.corrupt }
  }

  func write(_ document: String) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.complete])
    var excludedDirectory = directory
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try excludedDirectory.setResourceValues(values)
    let box = try AES.GCM.seal(Data(document.utf8), using: key(create: true))
    guard let encrypted = box.combined else { throw Failure.storage }
    try (Data([1]) + encrypted).write(to: file, options: [.atomic, .completeFileProtection])
    var excludedFile = file
    try excludedFile.setResourceValues(values)
  }

  func clear() throws {
    if FileManager.default.fileExists(atPath: file.path) {
      try FileManager.default.removeItem(at: file)
    }
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { throw Failure.storage }
  }
}
