package xyz.sedno.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.sqrt

/** No audio files, network recognizer or cloud fallback. All callbacks run on main. */
class LocalSpeechController(private val activity: Activity) {
    companion object {
        const val PERMISSION_REQUEST = 4901
        private const val SAMPLE_RATE = 16_000
    }

    private val handler = Handler(Looper.getMainLooper())
    private var session: Session? = null
    private var permissionPending = false

    fun listen(result: MethodChannel.Result) {
        if (session != null || permissionPending) {
            result.error("busy", null, null)
            return
        }
        if (Build.VERSION.SDK_INT < 33 ||
            !SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)) {
            result.error("unavailable", null, null)
            return
        }
        val current = Session(result)
        session = current
        if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            permissionPending = true
            try {
                activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST)
            } catch (_: Exception) {
                permissionPending = false
                fail(current, "permission")
            }
        } else {
            prepare(current)
        }
    }

    fun onPermissionResult(granted: Boolean) {
        permissionPending = false
        val current = session ?: return
        if (granted) prepare(current) else fail(current, "permission")
    }

    fun cancel() {
        session?.let { finish(it, null) }
    }

    @android.annotation.TargetApi(33)
    private fun prepare(current: Session) {
        if (session !== current) return
        handler.postDelayed(current.setupTimeout, 30_000)
        try {
            val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
            current.recognizer = recognizer
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pl-PL")
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            }
            recognizer.checkRecognitionSupport(intent, activity.mainExecutor, object : RecognitionSupportCallback {
                override fun onSupportResult(support: RecognitionSupport) {
                    if (session !== current) return
                    val installed = support.installedOnDeviceLanguages.any {
                        it.replace('_', '-').equals("pl-PL", true) || it.equals("pl", true)
                    }
                    if (!installed) fail(current, "language") else start(current, intent)
                }
                override fun onError(error: Int) {
                    if (session === current) fail(current, "unavailable")
                }
            })
        } catch (_: Exception) {
            fail(current, "unavailable")
        }
    }

    @android.annotation.TargetApi(33)
    private fun start(current: Session, intent: Intent) {
        try {
            val pipe = ParcelFileDescriptor.createPipe()
            current.input = pipe[0]
            current.output = ParcelFileDescriptor.AutoCloseOutputStream(pipe[1])
            // The recognizer consumes PCM from this pipe. Closing it ends the
            // session, independent of vendor-specific silence intent hints.
            intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pipe[0])
            intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, SAMPLE_RATE)
            intent.putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
            val minimum = AudioRecord.getMinBufferSize(
                SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
            )
            check(minimum > 0)
            val recorder = AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
                .setAudioFormat(AudioFormat.Builder()
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT).build())
                .setBufferSizeInBytes(max(minimum, 6400)).build()
            current.recorder = recorder
            check(recorder.state == AudioRecord.STATE_INITIALIZED)
            current.recognizer!!.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
                override fun onError(error: Int) {
                    if (session !== current) return
                    fail(current, when (error) {
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission"
                        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
                        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "language"
                        SpeechRecognizer.ERROR_NO_MATCH,
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "no_speech"
                        else -> "recognition"
                    })
                }
                override fun onSegmentResults(segmentResults: Bundle) {
                    if (session === current) bestText(segmentResults)?.let { current.segments.add(it) }
                }
                override fun onEndOfSegmentedSession() {
                    if (session !== current) return
                    // Fail closed when an engine ignores the supplied audio stream.
                    if (current.recording.get()) fail(current, "unavailable")
                    else finishText(current, current.segments.joinToString(" "))
                }
                override fun onResults(results: Bundle) {
                    if (session !== current) return
                    if (current.recording.get()) {
                        fail(current, "unavailable")
                    } else {
                        finishText(current, current.segments.joinToString(" ").ifBlank { bestText(results).orEmpty() })
                    }
                }
            })
            current.recording.set(true)
            current.recognizer!!.startListening(intent)
            recorder.startRecording()
            current.recordingStartedAt = SystemClock.elapsedRealtime()
            check(recorder.recordingState == AudioRecord.RECORDSTATE_RECORDING)
            handler.removeCallbacks(current.setupTimeout)
            handler.postDelayed(current.recordingTimeout, SpeechEndpoint.MAX_RECORDING_MS)
            Thread({ capture(current, recorder) }, "sedno-local-speech").start()
        } catch (_: SecurityException) {
            fail(current, "permission")
        } catch (_: Exception) {
            fail(current, "recognition")
        }
    }

    private fun capture(current: Session, recorder: AudioRecord) {
        // 20 ms PCM frames. The energy gate requires 100 ms of sound before
        // arming silence detection, so a single microphone click does not end it.
        val samples = ShortArray(320)
        val bytes = ByteArray(640)
        val endpoint = SpeechEndpoint(current.recordingStartedAt)
        try {
            while (current.recording.get()) {
                val count = recorder.read(samples, 0, samples.size)
                if (!current.recording.get()) break
                check(count > 0)
                var energy = 0.0
                for (i in 0 until count) {
                    val value = samples[i].toInt()
                    energy += value.toDouble() * value
                    bytes[i * 2] = (value and 255).toByte()
                    bytes[i * 2 + 1] = (value shr 8).toByte()
                }
                val rms = sqrt(energy / count)
                val now = SystemClock.elapsedRealtime()
                val ended = endpoint.accept(rms, now)
                current.output?.write(bytes, 0, count * 2)
                if (ended) {
                    handler.post { stopAudio(current) }
                    break
                }
            }
        } catch (_: Exception) {
            if (current.recording.get()) handler.post {
                if (session === current && current.recording.get()) fail(current, "recognition")
            }
        }
    }

    private fun stopAudio(current: Session) {
        if (session !== current || !current.recording.getAndSet(false)) return
        handler.removeCallbacks(current.recordingTimeout)
        try { current.recorder?.stop() } catch (_: Exception) {}
        try { current.output?.close() } catch (_: Exception) {}
        current.output = null
        // Allow final decoding, but never keep the UI waiting indefinitely.
        handler.postDelayed(current.resultTimeout, 10_000)
    }

    private fun bestText(bundle: Bundle): String? =
        bundle.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.trim()?.takeIf { it.isNotEmpty() }

    private fun finishText(current: Session, text: String) {
        if (text.isBlank()) fail(current, "no_speech") else finish(current, text)
    }

    private fun fail(current: Session, code: String) {
        if (session !== current) return
        cleanup(current)
        current.result.error(code, null, null)
    }

    private fun finish(current: Session, text: String?) {
        if (session !== current) return
        cleanup(current)
        current.result.success(text)
    }

    private fun cleanup(current: Session) {
        session = null
        current.recording.set(false)
        handler.removeCallbacks(current.setupTimeout)
        handler.removeCallbacks(current.recordingTimeout)
        handler.removeCallbacks(current.resultTimeout)
        try { current.recorder?.stop() } catch (_: Exception) {}
        try { current.output?.close() } catch (_: Exception) {}
        try { current.input?.close() } catch (_: Exception) {}
        try { current.recorder?.release() } catch (_: Exception) {}
        try { current.recognizer?.cancel() } catch (_: Exception) {}
        try { current.recognizer?.destroy() } catch (_: Exception) {}
    }

    private inner class Session(val result: MethodChannel.Result) {
        val recording = AtomicBoolean(false)
        var recognizer: SpeechRecognizer? = null
        var recorder: AudioRecord? = null
        var recordingStartedAt = 0L
        var input: ParcelFileDescriptor? = null
        @Volatile var output: ParcelFileDescriptor.AutoCloseOutputStream? = null
        val segments = mutableListOf<String>()
        val setupTimeout = Runnable { fail(this, "timeout") }
        val recordingTimeout = Runnable { stopAudio(this) }
        val resultTimeout = Runnable { fail(this, "timeout") }
    }
}
