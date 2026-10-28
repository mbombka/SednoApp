import AVFoundation
import Flutter

/// Tracks the utterance associated with the pending Dart Future. Old delegate
/// callbacks must never resolve a replacement utterance's result.
final class PlaybackResultState {
  private var identity: ObjectIdentifier?
  private var pending: FlutterResult?

  func begin(_ utterance: AnyObject, result: @escaping FlutterResult) {
    cancel()
    identity = ObjectIdentifier(utterance)
    pending = result
  }

  @discardableResult
  func complete(_ utterance: AnyObject) -> Bool {
    guard identity == ObjectIdentifier(utterance), pending != nil else { return false }
    cancel()
    return true
  }

  func cancel() {
    let callback = pending
    pending = nil
    identity = nil
    callback?(nil)
  }
}

final class LocalTextPlaybackController: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  private let completion = PlaybackResultState()

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  func speak(text: String, language: String, result: @escaping FlutterResult) {
    stop()
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      result(FlutterError(code: "invalid_request", message: "Empty text", details: nil)); return
    }
    // speechVoices lists installed voices; never substitute a different language.
    guard let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {
      $0.language.caseInsensitiveCompare(language) == .orderedSame
    }) else {
      result(FlutterError(code: "voice_missing", message: "Local voice unavailable", details: nil)); return
    }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try session.setActive(true)
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = voice
      utterance.rate = AVSpeechUtteranceDefaultSpeechRate
      completion.begin(utterance, result: result)
      synthesizer.speak(utterance)
      // Keep the Dart Future pending while audio plays so its Stop UI remains active.
    } catch {
      releaseAudioSession()
      result(FlutterError(code: "playback_failed", message: "Audio unavailable", details: nil))
    }
  }

  func stop() {
    // Clear identity before requesting cancellation; the delegate can run immediately.
    completion.cancel()
    synthesizer.stopSpeaking(at: .immediate)
    releaseAudioSession()
  }

  private func releaseAudioSession() {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.completion.complete(utterance) else { return }
      self.releaseAudioSession()
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.completion.complete(utterance) else { return }
      self.releaseAudioSession()
    }
  }
}
