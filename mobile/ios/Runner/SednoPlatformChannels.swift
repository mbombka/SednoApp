import AVFoundation
import Flutter
import UIKit

final class SednoPlatformChannels {
  private let speech = LocalSpeechController()
  private let playback = LocalTextPlaybackController()
  private let attest = AppAttestBridge()
  private let storageQueue = DispatchQueue(label: "xyz.sedno.history")
  private var installation: InstallationStateStore?
  private var history: EncryptedHistoryStore?
  private var channels: [FlutterMethodChannel] = []
  private var observers: [NSObjectProtocol] = []

  init(messenger: FlutterBinaryMessenger) {
    register("sedno/app_attest", messenger: messenger) { [weak self] call, result in
      self?.attest.handle(call, result: result)
    }
    register("sedno/speech", messenger: messenger) { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "listen":
        self.playback.stop()
        let args = call.arguments as? [String: Any]
        self.speech.listen(language: args?["language"] as? String ?? "pl-PL", result: result)
      case "cancel": self.speech.cancel(); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    register("sedno/text-playback", messenger: messenger) { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "speak":
        self.speech.cancel()
        let args = call.arguments as? [String: Any]
        self.playback.speak(text: args?["text"] as? String ?? "",
          language: args?["language"] as? String ?? "pl-PL", result: result)
      case "stop": self.playback.stop(); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    register("sedno/installation", messenger: messenger) { [weak self] call, result in
      guard let self = self else { return }
      self.storageQueue.async {
        var value: Any?
        do {
          if self.installation == nil { self.installation = try InstallationStateStore() }
          guard let installation = self.installation else { throw EncryptedHistoryStore.Failure.storage }
          switch call.method {
          case "isFreshInstallation":
            let fresh = try installation.isFreshInstallation()
            if fresh {
              if self.history == nil { self.history = try EncryptedHistoryStore() }
              // Only this store's own service/key is cleared; unrelated Keychain entries are untouched.
              try self.history?.clear()
            }
            value = fresh
          case "markInitialized": try installation.markInitialized()
          default: value = FlutterMethodNotImplemented
          }
        } catch {
          value = FlutterError(code: "STORAGE", message: "Installation state unavailable", details: nil)
        }
        DispatchQueue.main.async { result(value) }
      }
    }
    register("pl.sedno/history", messenger: messenger) { [weak self] call, result in
      guard let self = self else { return }
      self.storageQueue.async {
        var value: Any?
        do {
          if self.history == nil { self.history = try EncryptedHistoryStore() }
          guard let history = self.history else { throw EncryptedHistoryStore.Failure.storage }
          switch call.method {
          case "read": value = try history.read()
          case "write":
            guard let document = call.arguments as? String else { throw EncryptedHistoryStore.Failure.storage }
            try history.write(document)
          case "clear": try history.clear()
          default: value = FlutterMethodNotImplemented
          }
        } catch EncryptedHistoryStore.Failure.corrupt {
          value = FlutterError(code: "CORRUPT", message: "History cannot be decrypted", details: nil)
        } catch {
          value = FlutterError(code: "STORAGE", message: "History storage unavailable", details: nil)
        }
        DispatchQueue.main.async { result(value) }
      }
    }
    for name in [UIApplication.didEnterBackgroundNotification, UIScene.didEnterBackgroundNotification,
                 AVAudioSession.interruptionNotification,
                 AVAudioSession.routeChangeNotification] {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
        [weak self] notification in
        if notification.name == AVAudioSession.routeChangeNotification {
          let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
          guard reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        }
        if notification.name == AVAudioSession.interruptionNotification {
          let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
          guard type == AVAudioSession.InterruptionType.began.rawValue else { return }
        }
        self?.speech.cancel()
        self?.playback.stop()
      })
    }
  }

  private func register(_ name: String, messenger: FlutterBinaryMessenger,
                        handler: @escaping FlutterMethodCallHandler) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler(handler)
    channels.append(channel)
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
    channels.forEach { $0.setMethodCallHandler(nil) }
    speech.cancel()
    playback.stop()
  }
}
