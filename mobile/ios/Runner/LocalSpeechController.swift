import AVFoundation
import Flutter
import Speech

/// Recognition is strictly on-device. No fallback to Apple's network service.
final class LocalSpeechController {
  private let engine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var pending: FlutterResult?
  private var timer: Timer?
  private var tapInstalled = false
  private var generation = UUID()
  private var transcript = ""
  private var started: TimeInterval = ProcessInfo.processInfo.systemUptime
  private var lastVoice: TimeInterval = ProcessInfo.processInfo.systemUptime

  func listen(language: String, result: @escaping FlutterResult) {
    cancel()
    pending = result
    let attempt = UUID()
    generation = attempt
    SFSpeechRecognizer.requestAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self = self, self.generation == attempt, self.pending != nil else { return }
        guard status == .authorized else { self.fail("permission"); return }
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
          DispatchQueue.main.async {
            guard let self = self, self.generation == attempt, self.pending != nil else { return }
            guard allowed else { self.fail("permission"); return }
            self.start(language: language, attempt: attempt)
          }
        }
      }
    }
  }

  private func start(language: String, attempt: UUID) {
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)),
      recognizer.isAvailable else { fail("language_unsupported"); return }
    guard recognizer.supportsOnDeviceRecognition else { fail("language"); return }
    self.recognizer = recognizer
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    request.taskHint = .dictation
    self.request = request
    transcript = ""
    started = ProcessInfo.processInfo.systemUptime
    lastVoice = started
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .measurement, options: [])
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      guard format.sampleRate > 0, format.channelCount > 0 else { fail("unavailable"); return }
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self, weak request] buffer, _ in
        request?.append(buffer)
        guard let samples = buffer.floatChannelData?.pointee, buffer.frameLength > 0 else { return }
        var sum: Float = 0
        for index in 0..<Int(buffer.frameLength) { sum += samples[index] * samples[index] }
        let rms = sqrt(sum / Float(buffer.frameLength))
        if rms > 0.012 {
          DispatchQueue.main.async {
            guard self?.generation == attempt else { return }
            self?.lastVoice = ProcessInfo.processInfo.systemUptime
          }
        }
      }
      tapInstalled = true
      task = recognizer.recognitionTask(with: request) { [weak self] recognition, error in
        DispatchQueue.main.async {
          guard let self = self, self.generation == attempt, self.pending != nil else { return }
          if let recognition = recognition {
            let newText = recognition.bestTranscription.formattedString
            if self.transcript != newText { self.lastVoice = ProcessInfo.processInfo.systemUptime }
            self.transcript = newText
            if recognition.isFinal { self.finishText(); return }
          }
          if error != nil { self.fail("recognition_failed") }
        }
      }
      engine.prepare()
      try engine.start()
      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        if (ProcessInfo.processInfo.systemUptime - self.started) >= 60 {
          if self.transcript.isEmpty { self.fail("timeout") } else { self.finishText() }
        } else if !self.transcript.isEmpty && (ProcessInfo.processInfo.systemUptime - self.lastVoice) >= 1.5 {
          self.finishText()
        }
      }
    } catch { fail("unavailable") }
  }

  private func finishText() {
    let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { fail("no_speech") } else { finish(text) }
  }

  private func fail(_ code: String) {
    finish(FlutterError(code: code, message: "On-device speech recognition unavailable", details: nil))
  }

  func cancel() { finish(nil) }

  private func finish(_ value: Any?) {
    let callback = pending
    pending = nil
    generation = UUID()
    timer?.invalidate()
    timer = nil
    if engine.isRunning { engine.stop() }
    if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
    request?.endAudio()
    task?.cancel()
    task = nil
    request = nil
    recognizer = nil
    transcript = ""
    if callback != nil {
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      callback?(value)
    }
  }
}
