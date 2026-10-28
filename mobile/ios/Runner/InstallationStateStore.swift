import Foundation

/// Unlike Keychain, this app-container marker does not survive uninstall or backup restore.
/// Keep the check and commit separate: Dart clears its secure preferences between them.
final class InstallationStateStore {
  enum Failure: Error { case invalidMarker }
  private let directory: URL
  private let markerContents = Data("sedno-installation-v1".utf8)

  init(directory: URL? = nil) throws {
    self.directory = try directory ?? FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true).appendingPathComponent("SednoInstallation", isDirectory: true)
  }

  private var marker: URL { directory.appendingPathComponent("initialized.v1") }

  func isFreshInstallation() throws -> Bool {
    do {
      let contents = try Data(contentsOf: marker)
      guard contents == markerContents else { throw Failure.invalidMarker }
      return false
    } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
      return true
    }
  }

  func markInitialized() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.complete])
    var excludedDirectory = directory
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try excludedDirectory.setResourceValues(values)
    try markerContents.write(to: marker, options: [.atomic, .completeFileProtection])
    var excludedMarker = marker
    try excludedMarker.setResourceValues(values)
  }
}
