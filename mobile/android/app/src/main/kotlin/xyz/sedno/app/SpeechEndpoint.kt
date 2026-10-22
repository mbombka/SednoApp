package xyz.sedno.app

import kotlin.math.max

/** Energy based endpoint detector, fed 20 ms PCM frames; never stores audio. */
internal class SpeechEndpoint(private val startedAtMs: Long) {
    companion object {
        const val MAX_RECORDING_MS = 60_000L
        const val SILENCE_MS = 1_500L
    }
    private var noise = 100.0
    private var voiceFrames = 0
    private var heardVoice = false
    private var lastVoice = 0L

    fun accept(rms: Double, nowMs: Long): Boolean {
        if (nowMs - startedAtMs >= MAX_RECORDING_MS) return true
        if (rms >= max(350.0, noise * 3)) {
            voiceFrames++
            if (voiceFrames >= 5) heardVoice = true
            lastVoice = nowMs
        } else {
            voiceFrames = 0
            noise = noise * 0.98 + rms * 0.02
        }
        return heardVoice && nowMs - lastVoice >= SILENCE_MS
    }
}
